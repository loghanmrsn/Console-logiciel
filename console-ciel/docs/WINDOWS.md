# Version portable Windows x86_64

Livraison actuelle **0.4.1 — navigation translucide** : [ZIP Windows](../builds/Console_CIEL_Windows_x86_64_navigation_0.4.1.zip). Décompresser tout le ZIP, puis double-cliquer sur `Console_CIEL.exe`. Barre **Accueil → Boutique → Paramètres → Profil**, avec avatar, pseudo et points. [Captures et vérifications](NAVIGATION_TRANSLUCIDE.md).

Livraison précédente **0.4.0 — refonte graphique**, conservée : `builds/Console_CIEL_Windows_x86_64_refonte_0.4.0.zip`, binaire local dans `builds/windows-x86_64-refonte-0.4.0/`. [Captures et vérifications historiques](REFONTE_GRAPHIQUE.md). Les anciens exécutables 0.3.0 et 0.3.1 n'étaient pas inclus dans les sources reçues ; le reste de cette page décrit les vérifications historiques 0.3.0.

Pour exporter 0.4.0 sans remplacer ces versions, utiliser :

```powershell
.\tools\export_windows.ps1 -GodotPath 'C:\Outils\Godot_v4.6.3-stable_win64_console.exe' -ArchiveName Console_CIEL_Windows_x86_64_refonte_0.4.0.zip -OutputDirectory windows-x86_64-refonte-0.4.0
```

Logiciel **0.3.0**, moteur officiel **4.6.3.stable.official.7d41c59c4**, GDScript standard, rendu **Compatibility**. Aucune migration de version. Le préréglage `Linux ARM64 Raspberry Pi` et son architecture sont conservés.

## Lancer sur votre PC

1. Copier [builds/Console_CIEL_Windows_x86_64.zip](../builds/Console_CIEL_Windows_x86_64.zip) sur un PC Windows x86_64.
2. Décompresser **tout** le ZIP dans un dossier de votre choix.
3. Double-cliquer sur **Console_CIEL.exe** depuis ce dossier. Godot, Bash, Python, labwc et les outils Raspberry Pi ne sont pas nécessaires sur le PC destinataire. L'application ne demande pas de droits administrateur.

L'exécutable se trouve aussi dans `builds/windows-x86_64/Console_CIEL.exe`. Les ressources sont intégrées (`embed_pck=true`) : cet export ne nécessite aucun `.pck` externe. Garder néanmoins l'ensemble des fichiers d'une livraison ensemble si un export futur produit un `.pck`, des DLL ou un exécutable console. `LIRE_MOI.txt`, `assets/LICENSES.md` et `assets/licenses/` accompagnent le programme.

Windows 10/11 x86_64 et un pilote graphique compatible OpenGL 3.3 sont conseillés. Le projet n'a pas signé l'exécutable ; aucun certificat n'est fourni. Ne pas désactiver l'antivirus : respecter les règles du PC et vérifier le journal si le lancement échoue.

## Fenêtre, commandes et fermeture

Au premier lancement, fenêtre **1280 × 720** redimensionnable, minimum **800 × 480**. Les réglages sauvegardés prennent ensuite effet. **Paramètres → Affichage → Plein écran → Appliquer** conserve le choix ; **Annuler** restaure l'aperçu. Grand texte et réduction des animations/transparences se trouvent dans Accessibilité. `--fullscreen` reste accepté, notamment pour le lanceur Pi.

| Action | Clavier | Manette compatible Godot |
|---|---|---|
| Naviguer | Flèches ; Tab / Maj+Tab pour le focus | Croix / joystick gauche |
| Valider | Entrée / Entrée numérique | Bouton de face bas |
| Retour | Échap | Bouton de face droit |
| Déplacer le personnage | Flèches ou ZQSD | Croix / joystick gauche |
| Interagir | Espace | Bouton de face bas |
| Pause | P | Start / Menu |
| Catégorie précédente/suivante | Q / E, hors saisie de texte | Épaules gauche / droite |

La souris est facultative. Les actions sont celles de l'Input Map existante, centralisée dans `scripts/input_setup.gd` ; les lettres saisies dans un pseudo ne déclenchent pas les raccourcis de jeu ou d'onglets. **Paramètres → Commandes → Test des commandes** montre les périphériques, boutons, axes et zone morte effectivement reçus. Le contrôleur fabriqué reste à mesurer ; aucun mapping matériel futur n'est annoncé comme connu.

**Quitter** et la croix de la fenêtre utilisent la confirmation et la sauvegarde existantes. Un échec laisse la session ouverte avec une possibilité de réessai. Un brouillon de paramètres propose appliquer, annuler les aperçus ou revenir aux réglages. `PlatformService` distingue fermeture et arrêt système ; aucune commande d'arrêt/redémarrage de Windows n'est exécutée. Les fonctions matérielles Pi ne sont pas présentées comme disponibles sur Windows.

## Trouver les sauvegardes et journaux

`project.godot` configure `application/config/use_custom_user_dir=true` et `custom_user_dir_name="console-ciel"`. Godot **4.6.3** utilise sur Windows le dossier de données fourni par `APPDATA`, puis ce nom personnalisé : normalement **`%APPDATA%\console-ciel`**. Win+R puis ce chemin permet de l'ouvrir. **Paramètres → À propos** affiche le chemin effectif via `OS.get_user_data_dir()`, y compris lorsque le dossier Windows est redirigé.

Cette correspondance a été vérifiée dans le [code Windows du moteur 4.6.3](https://github.com/godotengine/godot/blob/4.6.3-stable/platform/windows/os_windows.cpp), `get_data_path()` / `get_user_data_dir()`, et [la sélection du dossier personnalisé](https://github.com/godotengine/godot/blob/4.6.3-stable/core/os/os.cpp). Le chemin n'a pas été mesuré dans une session Windows ici.

| Chemin dans ce dossier | Contenu |
|---|---|
| `profiles/<identifiant>.json` | Progression, indices, points, récompenses, inventaire et équipement du profil |
| `settings.cfg` | Réglages communs |
| `session.json` | Dernier profil choisi |
| `logs/godot.log` | Journal Godot, avec rotation éventuelle |

Aucune sauvegarde n'est écrite dans l'installation. Le ZIP n'inclut ni profil personnel ni données préremplies. Fermer normalement le programme avant de copier les sauvegardes. Une mise à jour consiste à décompresser la nouvelle version dans un autre dossier : elle conserve le même `user://`. Garder le dossier de la version précédente pour revenir à ce binaire. Ne pas supprimer le dossier utilisateur pour mettre à jour.

## Refaire l'export sur Windows

Installer l'éditeur **standard** Godot officiel **4.6.3 stable**, puis ses modèles exacts depuis **Éditeur → Gérer les modèles d'export**, ou installer l'archive officielle `Godot_v4.6.3-stable_export_templates.tpz` de [cette publication](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable). Les modèles Windows x86_64 debug/release doivent correspondre à l'éditeur ; aucun Godot .NET n'est requis.

Depuis PowerShell, à la racine du dépôt :

```powershell
.\tools\export_windows.ps1 -GodotPath 'C:\Outils\Godot_v4.6.3-stable_win64_console.exe'
# Projet dans un autre dossier, y compris avec espaces :
.\tools\export_windows.ps1 -GodotPath 'C:\Outils\Godot_v4.6.3-stable_win64_console.exe' -ProjectPath 'C:\Projets\Console CIEL'
```

Adapter le chemin au moteur effectivement installé. Le script vise PowerShell **5.1 ou supérieur**. Il a été analysé et exécuté ici avec **PowerShell 7.4.13 sous Linux** ; Windows PowerShell 5.1 reste à vérifier sur le PC. Aucune politique de sécurité ou configuration système n'est modifiée par le script.

Le script vérifie le projet et la version, importe les ressources, utilise le preset **`Windows Desktop x86_64`**, exporte dans un dossier provisoire, contrôle le PE x86_64 puis conserve tous les fichiers associés. Il ajoute l'aide et les licences avant de vérifier/publier le ZIP. Un moteur absent, une erreur Godot (même avec code 0), un mauvais binaire ou un export manquant interrompt la publication. La livraison précédente est conservée en cas d'échec. Les dossiers provisoires sont nettoyés. Le ZIP est produit uniquement après un export réussi.

Les sorties sont :

```text
builds/windows-x86_64/Console_CIEL.exe
builds/windows-x86_64/LIRE_MOI.txt
builds/windows-x86_64/assets/...
builds/Console_CIEL_Windows_x86_64.zip
```

Depuis l'éditeur : importer `project.godot`, **Projet → Exporter → Windows Desktop x86_64**, vérifier `x86_64`, Compatibility et le pack intégré, puis exporter vers `builds/windows-x86_64/Console_CIEL.exe` sans débogage. Pour assembler ensuite un ZIP complet et vérifié, utiliser le script PowerShell, qui refait également l'export. `tools/export.sh windows` reste disponible pour exporter le binaire depuis Linux ; il n'assemble pas l'archive portable.

## Vérifications de cette livraison

Le détail des résultats et journaux se trouve dans `tests/windows_results/`. Les tests utilisent des données temporaires isolées.

| Vérification | Portée réelle |
|---|---|
| Import natif et export Windows release | Exécutés avec Godot 4.6.3 officiel et ses modèles Windows officiels sous Linux ; aucune erreur bloquante |
| Script PowerShell | Analyse syntaxique, export réel et tests isolés des erreurs/chemins avec espaces ; pas un essai Windows PowerShell 5.1 |
| EXE et ZIP | PE x86_64, ressources intégrées, CRC du ZIP, **95 fichiers du PCK vérifiés** par leurs empreintes, aide/licences présentes, aucun profil personnel ou chemin de développement requis |
| Pack intégré au `.exe` | Lancé 60 frames puis testé avec le moteur Godot **Linux headless**, depuis un dossier indépendant du dépôt |
| Profils, missions, boutique et reprise du pack exporté | **47 assertions, zéro échec** avec les scripts compilés et données embarqués ; les trois missions donnent 150 points, achat/équipement persistent et le rejeu ne récompense pas à nouveau |
| Projet source | **3 694 assertions, zéro échec** : services, entrées synthétiques, profils, sauvegardes, géométrie des trois tailles et trois processus de persistance indépendants |
| Fermetures réelles sous Linux | **105 assertions, zéro échec** : appliquer/annuler les aperçus, échec d'écriture, réessai et annulation |
| Contrats Windows / script PowerShell | **16 / 22 assertions, zéro échec** ; le test a révélé et permis de corriger le remplacement d'un ZIP existant (`File.Replace` recevait un chemin vide) |
| Compilation et références | **148 assertions natives, zéro échec**, 45 UID et 91 chemins `res://` contrôlés ; Python/JSON/Bash vérifiés, PowerShell analysé séparément avec son parseur |
| Double-clic, fenêtre Windows, son, USB | **Non exécutés** : aucun environnement Windows, affichage ou manette physique disponible |

Charger le pack exporté dans Godot Linux vérifie ses ressources et sa logique ; cela ne lance pas le binaire Windows. La géométrie des contrôles en headless ne remplace pas une inspection du rendu.

L'archive produite contient **8 fichiers**, mesure **36 455 773 octets** (environ 34,8 Mio) et son SHA-256 est `4a09d53550b152d9bf7fdc618c5130a170ccb4fc63d1f99443b5c2b9b2b47739`. [Inventaire et empreintes](../tests/windows_results/package.json), [modèles officiels utilisés](../tests/windows_results/templates.json), [journal de l'export PowerShell](../tests/windows_results/powershell-export.log), [recette source](../tests/windows_results/acceptance/summary.json), [pack intégré](../tests/windows_results/embedded-pack-tests.log). Ces empreintes décrivent cette livraison ; refaire l'export peut produire d'autres octets.

Les tests sont reproductibles sous Linux avec les outils du projet et PowerShell installé pour vérifier l'exporteur :

```sh
python3 tools/run_acceptance.py --log-dir tests/windows_results/acceptance
python3 tools/check_close.py --log-dir tests/windows_results/close
python3 tools/audit_project.py --log-dir tests/windows_results/static
python3 tools/check_windows_export.py --powershell /chemin/vers/pwsh
godot --headless --path . --script res://tests/windows_contracts.gd
```

`tests/windows_pack.gd` s'exécute comme script **externe** avec `--main-pack builds/windows-x86_64/Console_CIEL.exe`, depuis un dossier de travail indépendant et avec `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` dirigés vers une racine temporaire. Il n'est pas distribué dans le pack. Les stubs de l'exporteur vivent uniquement dans des dossiers temporaires : leurs en-têtes PE factices servent aux tests de garde et ne sont jamais livrés comme exécutables.

## Recette à faire sur votre PC

1. Décompresser, double-cliquer, créer deux profils et naviguer sans souris.
2. Modifier puis annuler un réglage ; l'appliquer, passer en plein écran puis revenir en fenêtre.
3. Jouer les trois missions, tenter une mauvaise réponse, revenir au menu et reprendre.
4. Vérifier les points, acheter et équiper un cosmétique ; l'autre profil doit rester indépendant.
5. Fermer par Quitter puis par la croix, relancer et retrouver paramètres, progression et équipement.
6. Vérifier les trois résolutions **1280 × 720**, **1024 × 600**, **800 × 480**, texte normal et grand texte.
7. Avec une manette USB, vérifier repos des axes, navigation, déconnexion/reconnexion et reprise explicite.

Les performances Raspberry Pi, le mapping du contrôleur fabriqué et l'arrêt système restent dans [les limites connues](KNOWN_ISSUES.md). Ils ne sont pas requis pour lancer cette version Windows.
