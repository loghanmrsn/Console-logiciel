# Console CIEL 0.4.2 — Windows x86_64

[Télécharger le paquet Windows](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_profils_0.4.2.zip). Il contient le véritable **Console_CIEL.exe**  l’aide française  les licences et le dossier **images_profil/**. Godot n’est pas nécessaire pour jouer.

1. Télécharger le ZIP  puis **Extraire tout** dans l’Explorateur Windows.
2. Ouvrir le dossier extrait.
3. Double-cliquer sur **Console_CIEL.exe**  directement à la racine de ce dossier.

Déposer vos PNG  JPEG ou WebP dans **images_profil/** à côté de l’EXE  puis **Profil → Modifier → Mes images → Actualiser les images**. Le pseudo utilise un clavier AZERTY minuscule avec **⇧**  **123**  **#+=** et **ABC**. [Guide des profils](../docs/PROFILS_ET_CLAVIER.md).

Si vous téléchargez tout le dépôt  extraire aussi le ZIP Windows contenu dans `console-ciel/builds/`. L’EXE complet mesure **105 162 952 octets** et dépasse la limite GitHub de 100 Mio par fichier ; le ZIP contient ce binaire  sans pointeur Git LFS.

Le [projet complet 0.4.2](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.4.2.zip) contient directement le logiciel dans `console-ciel/builds/windows-x86_64-profils-0.4.2/Console_CIEL.exe`  ainsi que les sources  les ressources et les outils.

## Vérifications exécutées

- Godot officiel **4.6.3.stable.official.7d41c59c4**  modèles Windows officiels vérifiés par SHA-512.
- Export release réussi ; PE32+ x86_64  pack intégré.
- CRC ZIP et empreintes des **175 ressources intégrées** vérifiés  dont **36 SVG**.
- Configuration Windows : **18 contrôles** ; missions  achats et sauvegardes du pack compilé : **47** ; ressources et interface : **60** ; profil  clavier et images locales du pack : **644**. Aucun échec.
- Paquet testé depuis un dossier indépendant du dépôt avec des données temporaires isolées.

Les essais exécutent le pack compilé avec Godot **Linux**. Le double-clic Windows  le son et une manette USB physique restent à essayer sur un PC Windows. Le programme n’est pas signé.

ZIP : **36 377 860 octets**. SHA-256 : `93aa056cf352ac5db0519431900d92b099ba5409f9844399de028750122ac99b`.

[Rapport détaillé](Console_CIEL_Windows_x86_64_profils_0.4.2.verification.json). Les anciennes livraisons [0.4.1](Console_CIEL_Windows_x86_64_navigation_0.4.1.zip) et [0.4.0](Console_CIEL_Windows_x86_64_refonte_0.4.0.zip) sont conservées.
