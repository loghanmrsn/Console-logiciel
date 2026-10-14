# Export PC et Raspberry Pi — Godot 4.6.3 stable

## Préparer les modèles correspondants

L'éditeur et les modèles doivent être **4.6.3 stable**. Télécharger l'archive officielle `Godot_v4.6.3-stable_export_templates.tpz` depuis [la publication Godot officielle](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable), puis Godot → Éditeur → Gérer les modèles d'export → Installer depuis un fichier. Une installation avec les modèles d'une autre version ne convient pas.

Sur Linux, le dossier habituel est `~/.local/share/godot/export_templates/4.6.3.stable/`. Pour une installation isolée dans le dépôt sans écrire dans le HOME :

```sh
set -e
models_tmp_dir="$(mktemp -d -t ciel-templates.XXXXXX)"
trap 'rm -rf -- "$models_tmp_dir"' EXIT
mkdir -p .runtime-data/godot/export_templates/4.6.3.stable .runtime-cache .runtime-config
unzip /chemin/Godot_v4.6.3-stable_export_templates.tpz -d "$models_tmp_dir"
cp -- "$models_tmp_dir"/templates/* .runtime-data/godot/export_templates/4.6.3.stable/
XDG_DATA_HOME="$PWD/.runtime-data" XDG_CONFIG_HOME="$PWD/.runtime-config" \
XDG_CACHE_HOME="$PWD/.runtime-cache" tools/export.sh linux
```

Vérifier notamment `linux_release.x86_64`, `linux_debug.x86_64`, `linux_release.arm64`, `linux_debug.arm64` et les modèles Windows si l'on exporte cette cible. Ne pas commettre les modèles, caches ou données personnelles. Le dossier temporaire ne contient que les modèles de cet essai.

**Livraison 0.6.1 :** les modèles officiels **4.6.3 stable** sont utilisés pour les paquets Windows x86_64 et Raspberry Pi **ARM64**, conservés séparément. L’export Pi utilise `linux_release.arm64` ; `linux_debug.arm64` est nécessaire uniquement pour un export debug. Le programme ARM64 livré est un exécutable ELF autonome avec pack intégré. Le [bilan de livraison](DELIVERY.md), les [rapports Linux](../builds/README_LINUX.md) et le [guide Windows](WINDOWS.md) distinguent export, intégrité, exécution du pack avec Godot Linux x86_64 et lancement natif sur la cible.

Pour la **0.3.0**, une tentative réelle d'export ARM64 autonome a échoué avec la sortie 1 et ces deux modèles manquants : [`tests/arm64-export-results.log`](../tests/arm64-export-results.log). Un pack ZIP de ressources a été exporté avec la sortie 0, contrôlé puis chargé pendant 30 frames par Godot headless : [`tests/pack-launch-results.log`](../tests/pack-launch-results.log). Le pack n'est pas un binaire Pi. Des refus de socket TCP de l'éditeur dans le sandbox apparaissent au stade de l'export de pack ; ils sont distincts de l'absence des modèles et du lancement propre du pack.

## Presets livrés

| Preset | Plateforme et architecture | Sortie |
|---|---|---|
| `Linux PC x86_64` | Linux, `x86_64` | `builds/linux-x86_64/console-ciel.x86_64` |
| `Linux ARM64 Raspberry Pi` | Linux, `arm64` | `builds/linux-arm64/console-ciel.arm64` |
| `Windows Desktop x86_64` | Windows Desktop, `x86_64` | `builds/windows-x86_64/Console_CIEL.exe` |

Le pack est intégré à l'exécutable (`embed_pck=true`). Les JSON et licences sont inclus explicitement car ils ne sont pas tous des ressources importées automatiquement. Les tests, outils, docs de développement et caches sont exclus. Les crédits/licences doivent aussi accompagner toute redistribution.

```sh
tools/export.sh linux
tools/export.sh arm64
tools/export.sh windows
# Pour diagnostiquer avant une livraison :
tools/export.sh arm64 debug
```

Le script vérifie la version, importe les ressources et lance l'export. Il refuse aussi les erreurs de script même si Godot retourne 0 et vérifie qu’un nouveau binaire non vide a été produit. Un export échoué conserve le binaire précédent. Les erreurs de socket de l’éditeur dans un environnement restreint font également échouer cet outil ; le journal indique leur cause. `GODOT_BIN=/chemin/vers/godot` permet de choisir l'éditeur.

Depuis l'éditeur : Projet → Exporter, sélectionner le preset, vérifier l'architecture, exporter en désactivant « Exporter avec débogage » pour une livraison. Ne pas confondre ARM64 avec x86_64 ou ARM32.

## PC Linux et Windows

Sur Linux :

```sh
chmod +x builds/linux-x86_64/console-ciel.x86_64
./builds/linux-x86_64/console-ciel.x86_64
./builds/linux-x86_64/console-ciel.x86_64 --fullscreen
```

Sur Windows, décompresser tout `builds/Console_CIEL_Windows_x86_64_confort_0.6.1.zip` puis lancer **Console_CIEL.exe**, ou depuis PowerShell `./Console_CIEL.exe --fullscreen`. L’archive inclut les ressources dans l’exécutable, les crédits et les licences. L’export a réussi sous Linux ; il reste à essayer sur un PC Windows réel. Le script de réexport peut employer son nom historique `Console_CIEL_Windows_x86_64.zip`, distinct de la livraison versionnée.

Pour refaire l'export et l'archive depuis la racine du projet avec Godot officiel et les modèles exacts installés :

```powershell
.\tools\export_windows.ps1 -GodotPath 'C:\Outils\Godot_v4.6.3-stable_win64_console.exe'
```

Le script PowerShell vérifie le moteur et le projet, importe, exporte dans un dossier provisoire puis contrôle le PE x86_64, copie tous les fichiers associés et les licences, crée et vérifie le ZIP. Il ne publie rien si l'export échoue et conserve la livraison précédente. Voir [la procédure complète Windows](WINDOWS.md), y compris l'export par l'éditeur. `tools/export.sh windows` produit le binaire sous Linux ; c'est le script PowerShell qui assemble le ZIP portable.

## Raspberry Pi 4, Raspberry Pi OS 64 bits avec bureau

Le guide [RASPBERRY_PI.md](RASPBERRY_PI.md) décrit l’installation du paquet prêt à jouer, les photos, les sauvegardes, les journaux et les mises à jour. Le lanceur manuel **Lancer_Console_CIEL.sh** et le script facultatif **Installer_raccourci.sh** sont livrés dans le ZIP. Aucun autostart ni service système n’est ajouté. Les étapes suivantes résument la fabrication et la vérification d’une livraison.

1. Confirmer un système 64 bits : `uname -m` doit donner `aarch64`.
2. Exporter `Linux ARM64 Raspberry Pi` avec l'éditeur et les modèles 4.6.3.
3. Préparer un dossier de livraison avec **console-ciel.arm64**, les scripts de `docs/linux/`, sa notice, **images_profil/** et les licences. Les modèles officiels réclament des symboles jusqu’à **GLIBC 2.28** ; Raspberry Pi OS Bookworm ou Trixie 64 bits avec bureau sont recommandés.
4. Sur le Pi, depuis la **session graphique ouverte**, lancer `bash ./Lancer_Console_CIEL.sh`, éventuellement avec `--fullscreen`. Le lanceur sélectionne **gl_compatibility / opengl3_es**. Pour diagnostiquer la fenêtre, ajouter `--display-driver wayland` ou `--display-driver x11`, selon les pilotes réellement disponibles.
5. Facultativement, lancer `bash ./Installer_raccourci.sh` pour créer une entrée du menu utilisateur. La future intégration à un lanceur automatique distinct doit respecter les mêmes données utilisateur et la session bureau ; elle n’est pas créée par ce paquet.
6. Vérifier profils, photos, son, manette, relance, focus, plein écran et trois résolutions sur le matériel. Jouer les six défis, reprendre après chacun, essayer la porte avant et après réparation, l’ascenseur et le panneau de missions, puis les achats. Mesurer menu et enquête avec `--print-fps` et/ou le profileur Godot ; aucun résultat de FPS Raspberry Pi n’est déclaré comme acquis.

Après création du ZIP portable, vérifier son binaire et son contenu depuis la racine du projet :

```sh
python3 tools/verify_linux_package.py \
  --exe builds/linux-arm64-raspberry-pi-0.6.1/console-ciel.arm64 \
  --zip builds/Console_CIEL_Raspberry_Pi_ARM64_0.6.1.zip \
  --report builds/Console_CIEL_Raspberry_Pi_ARM64_0.6.1.verification.json
```

Cet outil vérifie la livraison existante ; il ne crée pas l’export ni les essais matériels. [Assemblage du projet complet Raspberry Pi](ARCHIVE_COMPLETE.md).

Les réglages du bureau/écran, le son et les permissions des périphériques relèvent de la session Raspberry Pi OS. Ne pas lancer l'application en root. Quitter ferme l'application ; « Arrêt système non configuré » reste indisponible jusqu'à une intégration spécifique, limitée et testée avec les droits de session. Aucun faux réglage de luminosité matérielle, Wi-Fi ou Bluetooth.

Références officielles correspondant à la branche 4.6 : [export des projets](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_projects.html), [export Linux](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_linux.html), [export Windows](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_windows.html), [options de ligne de commande](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html). Les références embarquées et `godot --help` peuvent être utilisées hors ligne.
