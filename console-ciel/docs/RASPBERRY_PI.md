# Installation et mise à jour sur Raspberry Pi

Cible prévue : **Raspberry Pi 5, 4 Go**, Raspberry Pi OS **64 bits**, session graphique **labwc** de l'utilisateur. L'écran et le contrôleur définitifs restent à valider. Le projet utilise Godot standard **4.6.3.stable.official.7d41c59c4**, GDScript, rendu **Compatibility** ; les modèles d'export doivent être **4.6.3 stable**.

Les modèles ne sont pas présents dans l'environnement actuel : aucun binaire ARM64 autonome n'y a été produit. Ces commandes décrivent l'installation à effectuer après un export réussi. Ne pas copier l'exécutable Godot de développement x86_64 sur le Pi.

## Produire les fichiers de livraison

Installer les modèles officiels correspondants, puis lancer depuis le projet :

```sh
tools/export.sh arm64
```

Le preset **Linux ARM64 Raspberry Pi** produit `builds/linux-arm64/console-ciel.arm64`. Le pack est intégré dans cet exécutable (`embed_pck=true`) ; aucun `.pck` séparé n'est requis par ce preset. Copier aussi `assets/LICENSES.md`, `assets/licenses/` et la documentation utile. Si le preset est changé pour séparer le pack, son `.pck` doit être livré à côté du binaire du même export. [Détail des modèles et presets](EXPORT.md).

## Installer une version sans remplacer la précédente

Dans la session utilisateur du Pi, vérifier l'architecture avec `uname -m` : elle doit être `aarch64`. Exemple de disposition retenue :

```text
~/Applications/console-ciel/
  releases/
    0.3.0/
      console-ciel.arm64
      assets/LICENSES.md
      assets/licenses/
      docs/
  current -> releases/0.3.0
```

Copier les fichiers de l'export dans un nouveau dossier de version. Si ce dossier existe déjà, choisir un autre nom de livraison au lieu d'écraser son contenu. Ces commandes sont des opérations manuelles à réaliser sur le Pi ; elles n'ont pas été exécutées par le projet sur la machine de développement :

```sh
set -e
mkdir -p "$HOME/Applications/console-ciel/releases"
mkdir "$HOME/Applications/console-ciel/releases/0.3.0"
# Après copie du binaire et des fichiers associés :
chmod +x "$HOME/Applications/console-ciel/releases/0.3.0/console-ciel.arm64"
```

Essayer d'abord cette version explicitement, depuis le bureau ouvert :

```sh
mkdir -p "$HOME/.local/state/console-ciel"
"$HOME/Applications/console-ciel/releases/0.3.0/console-ciel.arm64" \
  --fullscreen --log-file "$HOME/.local/state/console-ciel/run.log"
```

Le renderer Compatibility requiert un pilote OpenGL/OpenGL ES fonctionnel. Si le rendu échoue sous labwc, examiner le journal puis essayer, selon les pilotes disponibles, `--display-driver wayland --rendering-driver opengl3_es` ou `--display-driver x11` pour XWayland. Ne pas modifier automatiquement les réglages système pour masquer un échec. Ces variantes et le plein écran doivent être vérifiés sur le Pi.

Après vérification et fermeture de l'application, placer le lien vers la version validée :

```sh
ln -sfnT releases/0.3.0 "$HOME/Applications/console-ciel/current"
```

Le chemin stable à transmettre au lanceur est alors `~/Applications/console-ciel/current/console-ciel.arm64`. Le shell ou la configuration du lanceur doit développer `~`, ou employer un chemin absolu.

## Interface avec le lanceur automatique distinct

Aucun pack d'autostart n'a été trouvé dans ce dépôt : seuls les outils d'export, de paquet source et de démonstration y sont présents. Le lanceur annoncé dans le projet reste un livrable distinct. **Aucun deuxième mécanisme d'autostart n'est créé.**

L'interface attendue est une exécution dans la **session graphique de l'utilisateur**, après ouverture du bureau :

```sh
"$HOME/Applications/console-ciel/current/console-ciel.arm64" \
  --fullscreen --log-file "$HOME/.local/state/console-ciel/run.log"
```

Le lanceur peut ajouter ses propres journaux, sans modifier le dossier des sauvegardes. Ne pas lancer Godot en root, ne pas ajouter d'autorisation sudo générale et ne pas créer un service système concurrent. La vérification complète du lanceur nécessite ses fichiers réels, qui ne sont pas livrés ici.

## Sauvegardes, mise à jour et retour arrière

Les profils et réglages sont dans `~/.local/share/console-ciel/`, indépendamment de l'emplacement de l'exécutable. Le dossier contient `profiles/`, `settings.cfg`, `session.json` et les copies précédentes. Un `XDG_DATA_HOME` personnalisé change ce chemin ; le garder identique entre relances destinées aux mêmes joueurs. Le mode de démonstration utilise sa propre racine et ne doit pas devenir le dossier des vrais profils.

Avant une mise à jour, fermer normalement l'application et sauvegarder ce dossier utilisateur. Exemple de copie datée, réalisée manuellement sous le compte utilisateur :

```sh
set -e
mkdir -p "$HOME/Backups/console-ciel"
backup_dir="$HOME/Backups/console-ciel/avant-0.3.0"
test ! -e "$backup_dir" && test ! -L "$backup_dir"
cp -aT -- "$HOME/.local/share/console-ciel" "$backup_dir"
```

Choisir un nom de copie inexistant pour préserver la sauvegarde précédente. Installer le nouvel export dans un autre dossier de `releases/`, le lancer explicitement, vérifier sélection du profil, reprise, achat, équipement et fermeture, puis modifier seulement `current`. Ne pas supprimer ni copier des données utilisateur dans le dossier du binaire.

Pour revenir à une version précédente encore présente : fermer l'application, remettre `current` vers son dossier, puis relancer. Exemple :

```sh
ln -sfnT releases/0.2.0 "$HOME/Applications/console-ciel/current"
```

Ce lien suppose que la version précédente est réellement installée. La version 0.3.0 conserve le schéma de profils 1 et la version d'enquête 1 de la 0.2.0. Pour une future migration incompatible, ne pas laisser un ancien programme écrire les nouveaux documents : utiliser une copie de données dédiée ou restaurer la sauvegarde préalable **après avoir archivé les données plus récentes**, afin de ne pas perdre les changements des joueurs.

## Journaux et diagnostic

Avec `--log-file`, le journal de lancement est `~/.local/state/console-ciel/run.log`. Sans cette option, le journal Godot habituel est dans `user://logs/`, sous le dossier des données de l'application. Lire les erreurs du moteur en plus du code de sortie.

Le diagnostic **F3** est disponible pendant le développement debug : version logiciel et Godot, résolution, renderer, FPS réellement observés, identifiant du profil actif, contrôleur et dernière erreur de stockage. Les FPS headless ne constituent pas une mesure de performance du Pi. Le test des commandes affiche les boutons et axes bruts ; enregistrer les valeurs réellement observées pour le futur USB HID avant d'adapter le mapping configurable.

## Arrêt et recette matérielle

**Retour au menu** conserve l'application ouverte. **Quitter** sauvegarde puis ferme l'application. **Arrêt système non configuré** reste indisponible : PlatformService ne lance aucune commande d'arrêt. La coupure électrique du montage n'est pas pilotée par cette application.

Avant la soutenance sur Pi : jouer les trois missions, reprendre après chacune, acheter puis équiper un cosmétique, fermer et relancer, changer de profil, retirer/rebrancher la manette, vérifier son au volume zéro et normal, tester 1280 × 720, 1024 × 600 et 800 × 480 en texte normal/grand, vérifier le plein écran labwc et mesurer menu/enquête. Aucun résultat matériel ou objectif de 60 FPS n'est annoncé comme acquis. [Recette et problèmes connus](KNOWN_ISSUES.md).
