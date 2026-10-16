# Console CIEL 0.9.0 — Raspberry Pi 4, Linux ARM64

[Télécharger le logiciel Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Raspberry_Pi_ARM64_0.9.0.zip). Cible : **Raspberry Pi 4, Raspberry Pi OS 64 bits avec bureau**, architecture **aarch64**. Bookworm ou Trixie à jour sont recommandés ; le binaire requiert des symboles jusqu’à **GLIBC 2.28**.

Extraire tout le ZIP sur le Pi, ouvrir un terminal dans le dossier extrait, puis :

```sh
bash ./Lancer_Console_CIEL.sh
# Facultatif, ajouter l’application au menu du bureau :
bash ./Installer_raccourci.sh
```

Le véritable exécutable est **console-ciel.arm64**. Ses ressources sont intégrées ; Godot n’est pas nécessaire pour jouer. Garder le lanceur, **LIRE_MOI.txt**, les licences et **images_profil/** dans le même dossier. Le [guide Raspberry Pi](../docs/RASPBERRY_PI.md) décrit le lancement direct, les données, les images et les journaux.

Le [projet complet Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.9.0.zip) réunit les sources et ce binaire sous `console-ciel/builds/linux-arm64-raspberry-pi-0.9.0/`. Les sources s’ouvrent dans Godot standard **4.6.3.stable.official.7d41c59c4**, rendu **Compatibility**. Le [paquet Windows 0.9.0](Console_CIEL_Windows_x86_64_labyrinthe_0.9.0.zip) et son projet complet restent conservés séparément.

## Jeu et données

Le jeu est celui de la version Windows **0.9.0** : profil en haut à gauche, treize missions dans cinq chapitres, ascenseur, panneau de missions, prix de **200 points par Test**, repères masqués après réussite, thèmes et clavier de profil. Les Test restent des jeux en préparation. Le clavier à l’écran apparaît dans chaque exercice de code. Le chapitre 3 propose Python (`print`), HTML (`h1`) et Markdown (`# `), accessibles après les trois missions réseau. Chaque première réussite rapporte 50 points, soit 650 au maximum par profil ; trois achats à 200 points laissent 50 points sans autre dépense. Aucun code utilisateur n’est exécuté ; aucun crédit de test ni profil personnel n’est distribué.

Les sauvegardes sont généralement dans **`~/.local/share/console-ciel/`** ; Godot respecte `XDG_DATA_HOME`. **Paramètres → À propos** affiche le chemin effectif. Les photos vont dans **images_profil/** à côté de l’exécutable, puis **Profil → Personnaliser → Mes images → Actualiser les images**. Copier vos photos lors d’une installation dans un autre dossier ; conserver les sauvegardes utilisateur avant mise à jour.

## Vérifications et essai sur le Pi

Le [rapport ARM64](Console_CIEL_Raspberry_Pi_ARM64_0.9.0.verification.json) décrit le format ELF / AArch64, le pack embarqué, les fichiers livrés et les empreintes. Le [rapport du projet complet Raspberry Pi](Console_CIEL_Projet_Complet_Raspberry_Pi_0.9.0.verification.json) détaille son inventaire et son empreinte finale. Les contrôles de l’export sont distincts de l’exécution du pack avec Godot Linux x86_64.

Les résultats courants de la recette Windows et ARM64 sont consignés dans le [bilan de livraison](../docs/DELIVERY.md). Les résultats des anciennes versions restent distincts.

Le lanceur utilise **gl_compatibility / opengl3_es**, avec les bibliothèques et pilotes du bureau Raspberry Pi OS. Le lancement natif ARM64, le rendu, le son et la manette physique restent à essayer sur le Pi 4 ; aucun FPS matériel n’est annoncé comme mesuré dans le cloud. Le lanceur n’ajoute pas de service, autostart ni arrêt système. [Bilan de livraison](../docs/DELIVERY.md).

La version 0.9.0 ajoute les trois livres animés du coin ressources (chapitre 3) et le chapitre 4 : pare-feu, conflit IPv4 et masque /26. L’ascenseur propose Descendre d’étage, Monter d’étage et Retour au menu ; Échap reste dans la pièce. Les anciennes sauvegardes sont conservées.

La version 0.9.0 ajoute le **chapitre 5** : portable → **Y aller** → labyrinthe avec inscriptions murales et terminal simulé. Une seule mission est affichée **???** ; le clavier virtuel apparaît pour les identifiants, les mots de passe et les commandes. Les quatre premiers chapitres conservent trois missions chacun. La connexion et la reprise sont sauvegardées. Aucune commande n’est exécutée sur le système hôte.
