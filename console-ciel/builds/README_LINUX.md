# Console CIEL 0.19.2 — Raspberry Pi 4, Linux ARM64

[Télécharger le logiciel Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Raspberry_Pi_ARM64_0.19.2.zip). Cible : **Raspberry Pi 4, Raspberry Pi OS 64 bits avec bureau**, architecture **aarch64**. Bookworm ou Trixie à jour sont recommandés ; le binaire requiert des symboles jusqu’à **GLIBC 2.28**.

Extraire tout le ZIP sur le Pi, ouvrir un terminal dans le dossier extrait, puis :

```sh
bash ./Lancer_Console_CIEL.sh
# Facultatif, ajouter l’application au menu du bureau :
bash ./Installer_raccourci.sh
```

Le véritable exécutable est **console-ciel.arm64**. Ses ressources sont intégrées ; Godot n’est pas nécessaire pour jouer. Garder le lanceur, **LIRE_MOI.txt**, les licences et **images_profil/** dans le même dossier. Le [guide Raspberry Pi](../docs/RASPBERRY_PI.md) décrit le lancement direct, les données, les images et les journaux.

Le [projet complet Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.19.2.zip) réunit les sources et ce binaire sous `console-ciel/builds/linux-arm64-raspberry-pi-0.19.2/`. Les sources s’ouvrent dans Godot standard **4.6.3.stable.official.7d41c59c4**, rendu **Compatibility**. Le [paquet Windows 0.19.2](Console_CIEL_Windows_x86_64_replay_0.19.2.zip) et son projet complet restent conservés séparément.

## Jeu et données

Le jeu est celui de la version Windows **0.19.2** : profil en haut à gauche, treize missions dans cinq chapitres, ascenseur, panneau de missions, prix de **200 points par Test**, repères masqués après réussite, thèmes et clavier de profil. Les Test restent des jeux en préparation. Le clavier à l’écran apparaît dans chaque exercice de code. Le chapitre 3 propose Python (`print`), HTML (`h1`) et Markdown (`# `), accessibles après les trois missions réseau. Les treize premières réussites rapportent 650 points et les deux objectifs du matin ajoutent 100 points : 1 000 au maximum par profil, en ajoutant les 250 points des cinq postes du CTF ; quatre achats à 200 points laissent 200 points après le CTF, sans autre dépense ni pénalité. Aucun code utilisateur n’est exécuté ; aucun crédit de test ni profil personnel n’est distribué.

Les sauvegardes sont généralement dans **`~/.local/share/console-ciel/`** ; Godot respecte `XDG_DATA_HOME`. **Paramètres → À propos** affiche le chemin effectif. Les photos vont dans **images_profil/** à côté de l’exécutable, puis **Profil → Personnaliser → Mes images → Actualiser les images**. Copier vos photos lors d’une installation dans un autre dossier ; conserver les sauvegardes utilisateur avant mise à jour.

## Vérifications et essai sur le Pi

Le [rapport ARM64](Console_CIEL_Raspberry_Pi_ARM64_0.19.2.verification.json) décrit le format ELF / AArch64, le pack embarqué, les fichiers livrés et les empreintes. Le [rapport du projet complet Raspberry Pi](Console_CIEL_Projet_Complet_Raspberry_Pi_0.19.2.verification.json) détaille son inventaire et son empreinte finale. Les contrôles de l’export sont distincts de l’exécution du pack avec Godot Linux x86_64.

Les résultats courants de la recette Windows et ARM64 sont consignés dans le [bilan de livraison](../docs/DELIVERY.md). Les résultats des anciennes versions restent distincts.

Le lanceur utilise **gl_compatibility / opengl3_es**, avec les bibliothèques et pilotes du bureau Raspberry Pi OS. Le lancement natif ARM64, le rendu, le son et la manette physique restent à essayer sur le Pi 4 ; aucun FPS matériel n’est annoncé comme mesuré dans le cloud. Le lanceur n’ajoute pas de service, autostart ni arrêt système. [Bilan de livraison](../docs/DELIVERY.md).

Les trois livres animés du coin ressources (chapitre 3) et le chapitre 4 restent disponibles : pare-feu, conflit IPv4 et masque /26. L’ascenseur propose Descendre d’étage, Monter d’étage et Retour au menu ; Échap reste dans la pièce. Les anciennes sauvegardes sont conservées.

Le **chapitre 5** reste disponible : portable → **Y aller** → labyrinthe avec inscriptions murales et terminal simulé. Une seule mission est affichée **???** ; le clavier virtuel apparaît pour les identifiants, les mots de passe et les commandes. Les quatre premiers chapitres conservent trois missions chacun. La connexion et la reprise sont sauvegardées. Aucune commande n’est exécutée sur le système hôte.

Le parcours de l’hôtel prolonge l’exploration après le chapitre 5 : descente jusqu’au premier niveau, porte de sortie en bas à gauche, cour et immeuble d’en face. Le second bâtiment devient un hôtel doté d’un grand hall de **6 400 × 4 200** et de salles dédiées au parcours de la chambre 206. La carte en haut à gauche affiche la position et la sortie ; **→** l’affiche ou la masque, **D / ZQSD ou le joystick** restent disponibles pour marcher. Les treize missions de l’enquête conservent leurs 650 points ; les deux objectifs du matin portent le total à 750 points avant le CTF ; ses cinq postes ajoutent 250 points, soit 1 000 au total. Les portes enregistrent les zones avant chaque déplacement.

Le second bâtiment est un hôtel : grand hall et réception, réservation de la chambre **206**, panne du système de réservation à réparer dans la salle informatique voisine, escaliers arrondis, premier étage limité au palier et deuxième étage avec accès à la chambre. Après avoir posé les bagages, **Dormir** fait passer la nuit ; **Se poser sur le lit** propose ensuite **Dormir / Continuer à attendre** toutes les dix secondes. [Parcours de l’hôtel](../docs/HOTEL.md).

La version **0.19.2** poursuit le récit après le sommeil. Au réveil, le panneau vous invite à **descendre au rez-de-chaussée** : cette première descente rapporte **50 points**. Entrez dans la salle du petit déjeuner et asseyez-vous à table. Le café oublié vous conduit à la machine en panne. Son panneau présente six fils : **A, B, C** en haut et **1, 2, 3** en bas. Reliez les couleurs identiques : **A–3 rouge, B–2 vert et C–1 marron**. Le fil sélectionné brille ; un nouvel appui le désélectionne. Une fois les trois paires reliées, prenez votre café, remontez dans la **chambre 206** et récupérez le sac à dos contenant l’ordinateur, pour **50 points supplémentaires**. Redescendez, sortez de l’hôtel et rejoignez l’arrêt de bus. Le trajet mène au bâtiment du CTF **sudo hack**, où les cinq épreuves de Sudo Hack sont jouables avec leurs indices et le clavier virtuel. Après le flag final, un bus vous ramène en ville près de l’hôtel. [Guide détaillé](../docs/HOTEL.md).

Les deux récompenses du matin sont accordées une seule fois par profil, même après Nouvelle partie. La réparation du café et le trajet en bus ne rapportent pas de points. Les cinq défis du CTF ne sont pas encore disponibles.

Les modèles et collisions revus dans la version 0.13.0 sont conservés. Le personnage passe devant ou derrière les objets selon sa position. Dans la cour, un passage piéton, des feux et des voitures lentes encadrent la traversée : départ au vert sans frais ; traversée achevée au rouge sans choc, **200 points** ; collision, retour au trottoir de départ en gardant la progression. Les points disponibles paient la pénalité, puis une dette conserve le reste et se rembourse sur les prochains gains. [Règles et vérifications](../docs/TRAFFIC.md).

La version **0.14.0** a enrichi les deux épreuves existantes de l’hôtel : local informatique, cartes du diagnostic, buffet, machine à café et panneau de câblage. Les trois nouveaux meubles ont leur collision. La direction artistique, la progression, les points et les pénalités restent ceux du projet. [Détails du rendu et des contrôles](../docs/HOTEL_VISUAL.md).

La version **0.15.0** a ajouté six personnages solides et des discussions à plusieurs pages : première salle, dernier étage, buffet, entrée de l’hôtel, passage piéton et palier fermé du premier étage de l’hôtel. Les explications suivent la progression sans modifier les missions ni les points. **Espace / face bas** ouvre la discussion ; **Échap / face droite** la ferme. [Rencontres et commandes](../docs/PNJ.md).

La version **0.16.0** a affiné les six PNJ : coiffures et tenues distinctes, regards, geste d’accueil, portraits rapprochés et bulles portant leur nom. La discussion fonctionne depuis les côtés libres, avec de courts fondus, un portrait et des boutons fixes, un texte défilant et un bouton de fermeture directe. Espace avance aussi les pages ; les obstacles et les sauvegardes sont conservés. [Visuel et commandes](../docs/PNJ.md).

La version **0.19.2** propose le bouton **Dev · Super administrateur** : profil séparé, treize défis, épreuves de l’hôtel et cinq postes du CTF validés, étages accessibles et 1 000 points initiaux. La réutilisation conserve sa sauvegarde et les autres profils restent indépendants. [Utiliser Dev](../docs/DEV.md).

Les cinq épreuves **Sudo Hack** se jouent dans le hall du CTF. Chaque poste donne 50 points une seule fois. Après le flag final, le bus devant le CTF ramène en ville ; les lieux restent visitables. [Toutes les solutions illustrées](../../solution/README.md).
