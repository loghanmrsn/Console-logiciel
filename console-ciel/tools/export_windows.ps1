#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$GodotPath = 'godot',
    [string]$ProjectPath = (Join-Path $PSScriptRoot '..'),
    [ValidateSet('release', 'debug')][string]$Mode = 'release',
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_.-]*\.zip$')][string]$ArchiveName = 'Console_CIEL_Windows_x86_64.zip',
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_.-]*$')][string]$OutputDirectory = 'windows-x86_64'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$stagingRoot = $null
$previousDirectory = $null

function ConvertTo-NativeArgument([string]$Value) {
    # Windows CommandLineToArgvW escaping, also understood by Process on Unix.
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-GodotChecked([string[]]$Arguments) {
    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = $script:godotExecutable
    $start.Arguments = (($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ')
    $start.WorkingDirectory = $script:projectRoot
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $start
    try {
        if (-not $process.Start()) { throw 'Godot ne démarre pas.' }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(600000)) {
            $process.Kill()
            throw 'Godot dépasse le délai de dix minutes.'
        }
        $text = $stdout.Result + $stderr.Result
        if ($process.ExitCode -ne 0 -or $text -match '(?m)^(?:ERROR:|SCRIPT ERROR:)|Parse Error:') {
            throw ('Godot a échoué (code {0}).{1}{2}' -f $process.ExitCode, [Environment]::NewLine, $text)
        }
        return $text
    } finally { $process.Dispose() }
}

function Assert-WindowsExecutable([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Aucun nouvel exécutable produit.' }
    $stream = [System.IO.File]::OpenRead($Path)
    $reader = New-Object System.IO.BinaryReader($stream)
    try {
        if ($stream.Length -lt 512 -or $reader.ReadUInt16() -ne 0x5A4D) { throw 'Exécutable Windows invalide.' }
        $stream.Position = 0x3C
        $peOffset = $reader.ReadUInt32()
        $stream.Position = $peOffset
        if ($reader.ReadUInt32() -ne 0x4550 -or $reader.ReadUInt16() -ne 0x8664) {
            throw 'Le fichier produit ne correspond pas à Windows x86_64.'
        }
    } finally { $reader.Dispose() }
}

try {
    $script:projectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path
    foreach ($required in @('project.godot', 'export_presets.cfg', 'docs/windows/LIRE_MOI.txt', 'assets/LICENSES.md', 'assets/licenses')) {
        if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $required))) { throw "Fichier du projet absent : $required" }
    }
    if (Test-Path -LiteralPath $GodotPath -PathType Leaf) {
        $script:godotExecutable = (Resolve-Path -LiteralPath $GodotPath).Path
    } else {
        $script:godotExecutable = (Get-Command -Name $GodotPath -CommandType Application -ErrorAction Stop).Source
    }
    $version = (Invoke-GodotChecked -Arguments @('--version')).Trim()
    if ($version -ne '4.6.3.stable.official.7d41c59c4') {
        throw "Godot 4.6.3 officiel requis ; version reçue : $version"
    }
    $presetText = Get-Content -LiteralPath (Join-Path $projectRoot 'export_presets.cfg') -Raw
    if ($presetText -notmatch 'name="Windows Desktop x86_64"') { throw 'Préréglage Windows Desktop x86_64 absent.' }
    $buildRoot = Join-Path $projectRoot 'builds'
    [System.IO.Directory]::CreateDirectory($buildRoot) | Out-Null
    $stagingRoot = Join-Path $buildRoot ('.windows-export-' + [guid]::NewGuid().ToString('N'))
    $packageDirectory = Join-Path $stagingRoot 'windows-x86_64'
    [System.IO.Directory]::CreateDirectory($packageDirectory) | Out-Null
    $exe = Join-Path $packageDirectory 'Console_CIEL.exe'
    Write-Host 'Import du projet...'
    Write-Host (Invoke-GodotChecked -Arguments @('--headless', '--path', $projectRoot, '--import'))
    Write-Host 'Export Windows x86_64...'
    Write-Host (Invoke-GodotChecked -Arguments @('--headless', '--path', $projectRoot, "--export-$Mode", 'Windows Desktop x86_64', $exe))
    Assert-WindowsExecutable $exe
    # Preserve every associated file Godot emits, including .pck/.dll/console exe.
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/windows/LIRE_MOI.txt') -Destination (Join-Path $packageDirectory 'LIRE_MOI.txt')
    $assetDirectory = Join-Path $packageDirectory 'assets'
    [System.IO.Directory]::CreateDirectory($assetDirectory) | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/LICENSES.md') -Destination $assetDirectory
    Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/licenses') -Destination $assetDirectory -Recurse
    # Keep local profile pictures outside the PCK so users can add pictures later.
    $profileImages = Join-Path $projectRoot 'images_profil'
    if (Test-Path -LiteralPath $profileImages -PathType Container) {
        Copy-Item -LiteralPath $profileImages -Destination (Join-Path $packageDirectory 'images_profil') -Recurse
    } else {
        [System.IO.Directory]::CreateDirectory((Join-Path $packageDirectory 'images_profil')) | Out-Null
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = Join-Path $stagingRoot $ArchiveName
    [System.IO.Compression.ZipFile]::CreateFromDirectory($packageDirectory, $zip, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
    try {
        $names = @($archive.Entries | ForEach-Object { $_.FullName.Replace([char]92, [char]47) })
        foreach ($entry in @('Console_CIEL.exe', 'LIRE_MOI.txt', 'assets/LICENSES.md', 'assets/licenses/GODOT_MIT.txt')) {
            if ($names -notcontains $entry) { throw "Archive incomplète : $entry" }
        }
        if ($names -match '(?:^|/)profiles/|\.runtime-|settings\.cfg$|session\.json$') { throw 'Données utilisateur interdites dans le ZIP.' }
    } finally { $archive.Dispose() }
    $target = Join-Path $buildRoot $OutputDirectory
    # Keep the previous directory until the new archive and executable are verified.
    if (Test-Path -LiteralPath $target) {
        $previousDirectory = Join-Path $buildRoot ('.windows-previous-' + [guid]::NewGuid().ToString('N'))
        Move-Item -LiteralPath $target -Destination $previousDirectory
    }
    try {
        Move-Item -LiteralPath $packageDirectory -Destination $target
        $zipTarget = Join-Path $buildRoot $ArchiveName
        if (Test-Path -LiteralPath $zipTarget -PathType Leaf) {
            # PowerShell can convert $null to an empty path for this .NET API.
            # Use a real staging backup, removed only by the final cleanup.
            [System.IO.File]::Replace($zip, $zipTarget, (Join-Path $stagingRoot 'previous.zip'))
        } else { [System.IO.File]::Move($zip, $zipTarget) }
    } catch {
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        if ($previousDirectory) { Move-Item -LiteralPath $previousDirectory -Destination $target; $previousDirectory = $null }
        throw
    }
    if ($previousDirectory) { Remove-Item -LiteralPath $previousDirectory -Recurse -Force; $previousDirectory = $null }
    Write-Host ('Archive prête : ' + (Join-Path $buildRoot $ArchiveName))
} catch {
    [Console]::Error.WriteLine('Export Windows interrompu : ' + $_.Exception.Message)
    exit 1
} finally {
    if ($stagingRoot -and (Test-Path -LiteralPath $stagingRoot)) { Remove-Item -LiteralPath $stagingRoot -Recurse -Force }
}
