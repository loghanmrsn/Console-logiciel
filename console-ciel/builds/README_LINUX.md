# Console CIEL 0.6.1 — Raspberry Pi 4, Linux ARM64

[Télécharger le logiciel Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Raspberry_Pi_ARM64_0.6.1.zip). Cible : **Raspberry Pi 4, Raspberry Pi OS 64 bits avec bureau**, architecture **aarch64**. Bookworm ou Trixie à jour sont recommandés ; le binaire requiert des symboles jusqu’à **GLIBC 2.28**.

Extraire tout le ZIP sur le Pi, ouvrir un terminal dans le dossier extrait, puis :

```sh
bash ./Lancer_Console_CIEL.sh
# Facultatif, ajouter l’application au menu du bureau :
bash ./Installer_raccourci.sh
```

Le véritable exécutable est **console-ciel.arm64**. Ses ressources sont intégrées ; Godot n’est pas nécessaire pour jouer. Garder le lanceur, **LIRE_MOI.txt**, les licences et **images_profil/** dans le même dossier. Le [guide Raspberry Pi](../docs/RASPBERRY_PI.md) décrit le lancement direct, les données, les images et les journaux.

Le [projet complet Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.6.1.zip) réunit les sources et ce binaire sous `console-ciel/builds/linux-arm64-raspberry-pi-0.6.1/`. Les sources s’ouvrent dans Godot standard **4.6.3.stable.official.7d41c59c4**, rendu **Compatibility**. Le [paquet Windows 0.6.1](Console_CIEL_Windows_x86_64_confort_0.6.1.zip) et son projet complet restent conservés séparément.

## Jeu et données

Le jeu est celui de la version Windows **0.6.1** : profil en haut à gauche, six missions dans deux chapitres, ascenseur, panneau de missions, prix de **200 points par Test**, repères masqués après réussite, thèmes et clavier de profil. Les Test restent des jeux en préparation. Aucun changement de règle, crédit de points de test ou profil personnel n’est distribué.

Les sauvegardes sont généralement dans **`~/.local/share/console-ciel/`** ; Godot respecte `XDG_DATA_HOME`. **Paramètres → À propos** affiche le chemin effectif. Les photos vont dans **images_profil/** à côté de l’exécutable, puis **Profil → Personnaliser → Mes images → Actualiser les images**. Copier vos photos lors d’une installation dans un autre dossier ; conserver les sauvegardes utilisateur avant mise à jour.

## Vérifications et essai sur le Pi

Le [rapport ARM64](Console_CIEL_Raspberry_Pi_ARM64_0.6.1.verification.json) décrit le format ELF / AArch64, le pack embarqué, les fichiers livrés et les empreintes. Le [rapport du projet complet Raspberry Pi](Console_CIEL_Projet_Complet_Raspberry_Pi_0.6.1.verification.json) détaille son inventaire et son empreinte finale. Les contrôles de l’export sont distincts de l’exécution du pack avec Godot Linux x86_64.

| Vérification du 14 octobre 2026 | Résultat |
|---|---|
| Pack ARM64 exécuté avec Godot Linux x86_64 | **6 218 assertions, zéro échec**, 11 suites dont 8 contrats de plateforme |
| Rendu réel X11 / OpenGL ES 3.2, Mesa llvmpipe | **58 contrôles, zéro échec**, 8 captures temporaires |
| Lanceur et raccourci | **17 tests, zéro échec** |
| Outils Linux et contrats des presets | **47 assertions + 13 contrôles, zéro échec** |
| Régression des outils Windows | **27 contrôles, zéro échec** |
| Pack intégré et ZIP | **203 ressources MD5 vérifiées**, dont 43 SVG ; CRC vérifiés |

[Résumé de la livraison Raspberry Pi](../tests/raspberry_pi_0.6.1_results/summary.json). ZIP : **27 026 535 octets** ; ELF : **65 476 296 octets**. SHA-256 du ZIP : `96ea7e0c50e5015c7eb13188ccb38f24a14865587813f045f833192a7e7eddde`.

Le lanceur utilise **gl_compatibility / opengl3_es**, avec les bibliothèques et pilotes du bureau Raspberry Pi OS. Le lancement natif ARM64, le rendu, le son et la manette physique restent à essayer sur le Pi 4 ; aucun FPS matériel n’est annoncé comme mesuré dans le cloud. Le lanceur n’ajoute pas de service, autostart ni arrêt système. [Bilan de livraison](../docs/DELIVERY.md).
