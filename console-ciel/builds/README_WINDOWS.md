# Console CIEL 0.5.0 — Windows x86_64

[Télécharger Windows 0.5.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_bibliotheque_0.5.0.zip). Le ZIP contient le véritable **Console_CIEL.exe**, l’aide, les licences et **images_profil/**. Godot n’est pas nécessaire pour jouer.

1. Télécharger le ZIP Windows et choisir **Extraire tout**.
2. Ouvrir le dossier extrait.
3. Double-cliquer sur **Console_CIEL.exe**, à la racine de ce dossier.

Avec **Code → Download ZIP**, extraire aussi le ZIP Windows dans `console-ciel/builds/`. L’EXE complet mesure **105193000 octets** et dépasse la limite de 100 Mio par fichier Git ; le ZIP contient le binaire complet, sans pointeur Git LFS.

Le [projet complet](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.5.0.zip) réunit sources et logiciel. Après extraction : `console-ciel/builds/windows-x86_64-bibliotheque-0.5.0/Console_CIEL.exe`.

## Nouveautés

Boutique et profils refaits, deux dispositions d’accueil, styles/couleurs et crédits dans les paramètres. **Test 1 à Test 4** sont des emplacements de jeux encore en préparation : leur achat en points ouvre une page de test, sans jeu final ni nouveau gain. Prix **20 / 30 / 40 / 50 points** ; achats enregistrés séparément pour chaque profil. [Guide des nouveautés](../docs/BIBLIOTHEQUE_ET_THEMES.md).

Les photos locales et le clavier sont conservés : déposer vos PNG/JPEG/WebP dans **images_profil/**, puis **Profil → Personnaliser → Mes images → Actualiser les images**. Clavier minuscule avec **⇧**, **123**, **#+=** et **ABC**.

## Vérification exécutée

- Moteur officiel **4.6.3.stable.official.7d41c59c4**, modèles officiels vérifiés par SHA-512.
- Export release réussi, PE32+ x86_64 et pack intégré.
- CRC ZIP et empreintes des **187 ressources intégrées** vérifiés, dont **36 SVG**.
- Pack compilé : **3 242 assertions, zéro échec** — 47 métier, 76 ressources/interface, 644 profils/clavier/photos, 127 achats de jeux, 1 881 apparence, 467 bibliothèque.
- Configuration Windows : **18 contrôles, zéro échec**.
- Tests depuis des dossiers indépendants du dépôt, avec des données temporaires isolées.

Les tests exécutent le pack avec Godot **Linux**. Le lancement natif sous Windows, le son et une manette USB physique restent à essayer sur un PC Windows. Le logiciel n’est pas signé.

ZIP : **36405957 octets**. SHA-256 : `5d7ce9f0c557021d62477eb824c64742031b27989ed86e8ab9cf02ba2e1ac26e`.

[Rapport Windows](Console_CIEL_Windows_x86_64_bibliotheque_0.5.0.verification.json). Livraisons conservées : [0.4.2](Console_CIEL_Windows_x86_64_profils_0.4.2.zip), [0.4.1](Console_CIEL_Windows_x86_64_navigation_0.4.1.zip), [0.4.0](Console_CIEL_Windows_x86_64_refonte_0.4.0.zip).
