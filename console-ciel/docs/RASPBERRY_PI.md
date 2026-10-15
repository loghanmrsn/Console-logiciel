# Console CIEL 0.7.1 sur Raspberry Pi 4

La cible confirmée est un **Raspberry Pi 4 avec Raspberry Pi OS 64 bits et bureau**. Le paquet utilise un exécutable Linux **ARM64 / aarch64**, Godot standard **4.6.3.stable.official.7d41c59c4** et le rendu **Compatibility**, OpenGL ES 3. Le jeu, son clavier à l’écran pour les trois exercices de code, ses trois chapitres, les photos locales et les sauvegardes fonctionnent hors ligne ; Godot n’a pas besoin d’être installé pour jouer.

[Télécharger le logiciel Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Raspberry_Pi_ARM64_0.7.1.zip) · [Télécharger le projet complet avec les sources](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.7.1.zip).

Utiliser de préférence une installation à jour de **Raspberry Pi OS Bookworm ou Trixie 64 bits avec bureau**. `uname -m` doit indiquer **aarch64**. Le modèle officiel ARM64 requiert des symboles jusqu’à **GLIBC 2.28** ; Bookworm et Trixie satisfont cette version. Il attend aussi une session graphique et les pilotes du système. La configuration définitive de l’écran et de la manette reste à mesurer sur le Pi.

## Télécharger et lancer

1. Depuis le bureau du Pi, télécharger le ZIP Raspberry Pi et **extraire tout son contenu** dans un dossier utilisateur, par exemple `~/Applications/Console_CIEL_0.7.1/`.
2. Ouvrir un terminal dans le dossier extrait qui contient `console-ciel.arm64` et `Lancer_Console_CIEL.sh`.
3. Lancer :

```sh
bash ./Lancer_Console_CIEL.sh
# Ou démarrer en plein écran :
bash ./Lancer_Console_CIEL.sh --fullscreen
```

Le script et l’exécutable doivent rester dans le même dossier. Garder également `LIRE_MOI.txt`, `images_profil/`, `assets/LICENSES.md` et `assets/licenses/`. Les ressources du jeu sont intégrées dans **console-ciel.arm64**, sans `.pck` séparé. Le lanceur sélectionne le rendu **gl_compatibility / opengl3_es** et laisse Godot choisir le pilote de fenêtre X11 ou Wayland selon la session.

Dans le **projet complet Raspberry Pi**, le dossier à ouvrir est `console-ciel/builds/linux-arm64-raspberry-pi-0.7.1/`. Dans **Code → Download ZIP** sur GitHub, extraire également le ZIP Raspberry Pi placé dans `console-ciel/builds/`.

Pour ajouter un raccourci au menu des applications, depuis le même dossier :

```sh
bash ./Installer_raccourci.sh
```

Cet ajout facultatif crée uniquement `console-ciel.desktop` dans le dossier des applications de l’utilisateur, généralement `~/.local/share/applications/`. Le raccourci pointe vers le dossier extrait ; garder ce dossier ou réinstaller le raccourci après l’avoir déplacé.

Le lancement direct reste possible après avoir rendu le fichier exécutable :

```sh
chmod u+x ./console-ciel.arm64
./console-ciel.arm64 --rendering-method gl_compatibility --rendering-driver opengl3_es
```

Le réglage **Paramètres → Affichage → Plein écran** est conservé à la relance. Lancer sous le compte utilisateur du bureau. Aucun lancement en root, service système, autostart ou arrêt du système n’est ajouté.

## Même jeu que la livraison Windows 0.7.1

- Profil, avatar et points en haut à gauche ; quatre onglets centrés dans la barre inférieure.
- Trois chapitres et neuf missions ; ascenseur accessible en bas du bureau après les trois premières réussites. Après les trois missions réseau, le chapitre 3 présente Python (`print`), HTML (`h1`) et Markdown (`# `), sans exécution de code utilisateur.
- Tableau de missions à droite, repliable avec **T** ou le **bouton de face haut** de la manette.
- Repères et bouton d’interaction masqués après réussite sauvegardée ; meubles réparés et ascenseur conservés. **Pause → Bilan du chapitre** permet de revoir le bilan.
- **Test 1 à Test 4 coûtent 200 points chacun** et restent des emplacements de jeux en préparation. Une mission rapporte 50 points une seule fois, soit 450 points au maximum par profil ; un achat conserve débit et inventaire ensemble.
- Profils, clavier AZERTY minuscule / **⇧** / **123**, thèmes et couleurs, réglages et crédits conservés.

[Parcours de l’enquête](ENQUETE.md), [profil et clavier](PROFILS_ET_CLAVIER.md), [bibliothèque et tarifs](BIBLIOTHEQUE_ET_THEMES.md). La [livraison Windows 0.7.1](../builds/Console_CIEL_Windows_x86_64_clavier_0.7.1.zip) reste disponible séparément.

## Commandes et manette

| Action | Clavier | Manette Godot standard |
|---|---|---|
| Parcourir les menus | Flèches | Croix / joystick gauche |
| Valider | Entrée | Bouton de face bas |
| Retour | Échap | Bouton de face droit |
| Marcher | Flèches ou ZQSD | Croix / joystick gauche |
| Interagir | Espace | Bouton de face bas |
| Déplier / replier les missions | T | Bouton de face haut : Triangle / Y / X selon le modèle |
| Pause | P | Start / Menu |

Dans **Paramètres → Commandes → Test des commandes**, vérifier les boutons et axes réellement reçus avant d’adapter `data/controller_mapping.json` pour un contrôleur fabriqué. Les valeurs de test virtuelles ne prouvent pas le mapping USB physique. Le retrait de la manette suspend l’enquête ; la reconnexion nécessite une reprise explicite.

## Photos locales

Ajouter les fichiers PNG, JPEG ou WebP dans **images_profil/**, à côté de **console-ciel.arm64**, puis ouvrir **Profil → Personnaliser → Mes images → Actualiser les images**. En édition Godot, le dossier est `console-ciel/images_profil/`. Les photos personnelles ne sont pas incluses dans les paquets distribués.

## Données, mise à jour et retour arrière

Les profils et réglages sont séparés du binaire : **`~/.local/share/console-ciel/`** par défaut. Un `XDG_DATA_HOME` personnalisé change ce chemin ; le garder identique pour retrouver les mêmes joueurs. **Paramètres → À propos** affiche le chemin effectif. Le dossier contient `profiles/`, `settings.cfg`, `session.json` et les copies précédentes utilisées pour la récupération.

Les données Windows sont dans `%APPDATA%\console-ciel\` et ne se synchronisent pas automatiquement avec le Pi. L’installation Linux ne copie pas de profils ni de points de démonstration dans le compte utilisateur.

Pour mettre à jour, fermer normalement l’application, conserver une copie du dossier de données et extraire la nouvelle livraison dans **un nouveau dossier**, en gardant la précédente. Copier également vos images personnelles si vous souhaitez les retrouver dans ce nouveau dossier. L’emplacement du binaire peut changer sans changer les sauvegardes utilisateur. Réinstaller le raccourci facultatif depuis la nouvelle livraison.

Pour revenir à une version installée auparavant, fermer l’application puis lancer son dossier conservé. Une future version peut changer le format des données : garder les données récentes avant de restaurer une sauvegarde antérieure. La livraison 0.7.1 conserve le schéma de profils 1, les anciens achats et les réussites des chapitres précédents, puis ajoute les objectifs manquants.

## Journaux et affichage

Le journal habituel est sous **`user://logs/godot.log`**, donc généralement `~/.local/share/console-ciel/logs/godot.log`. Le chemin effectif est indiqué dans **Paramètres → À propos**. Pour choisir un journal de lancement :

```sh
mkdir -p "$HOME/.local/state/console-ciel"
bash ./Lancer_Console_CIEL.sh --log-file "$HOME/.local/state/console-ciel/run.log"
```

Le lanceur transmet les arguments supplémentaires au binaire. Le rendu Compatibility utilise **OpenGL ES 3**, pas Vulkan. Selon la session bureau et les pilotes, on peut choisir explicitement la fenêtre pour diagnostiquer un échec graphique :

```sh
bash ./Lancer_Console_CIEL.sh --display-driver wayland
bash ./Lancer_Console_CIEL.sh --display-driver x11
```

Lire les erreurs du moteur en plus du code de sortie. Le diagnostic **F3** appartient à l’exécution debug de développement ; ses FPS ne sont pas une mesure acquise pour le paquet release ou pour le Pi.

## Refaire l’export

Installer les modèles officiels **4.6.3 stable**, puis lancer depuis `console-ciel/` :

```sh
tools/export.sh arm64
```

Le preset **Linux ARM64 Raspberry Pi** produit `builds/linux-arm64/console-ciel.arm64`, avec pack intégré. Pour une livraison complète, l’exécutable doit être accompagné du lanceur, de la notice, du dossier d’images et des licences, comme dans le paquet publié. Le script d’export seul ne crée pas ce ZIP portable. [Guide des exports](EXPORT.md).

## Portée des vérifications

Le [rapport ARM64](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.7.1.verification.json) détaille le binaire, les ressources, l’archive et leurs empreintes ; le [rapport du projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.7.1.verification.json) inventorie les sources et les fichiers livrés. [Notice du paquet Linux](../builds/README_LINUX.md) et [bilan de livraison](DELIVERY.md).

La [livraison courante](DELIVERY.md) rassemble les résultats source, persistance, rendu réel et packs exportés. Les anciens résultats restent associés à leur version.

L’export ARM64 et l’exécution de ses ressources avec un moteur Linux x86_64 vérifient des aspects différents. Un chargement du pack sous x86_64 ne constitue pas un lancement natif du binaire ARM64. Aucun Raspberry Pi physique n’est disponible dans l’environnement cloud ; le rendu matériel, le son, le plein écran, la manette réelle et les performances restent à essayer sur votre Pi 4.

Avant la présentation, jouer les trois chapitres, reprendre après fermeture, tester le tableau de missions, le refus d’achat sous 200 points et la conservation des achats. Avec un profil neuf sans autre dépense, neuf réussites donnent 450 points ; deux achats à 200 laissent 50 points et un troisième est refusé. Vérifier l’écran final, le son et la déconnexion / reconnexion de votre manette. Les tests Linux de la version Windows restent historiques et n’attestent pas à eux seuls du fonctionnement sur le Pi.

**Quitter** sauvegarde puis ferme le logiciel. **Arrêt système non configuré** reste indisponible : fermer l’application, arrêter Raspberry Pi OS normalement, puis couper l’alimentation du montage. [Recette et problèmes connus](KNOWN_ISSUES.md).
