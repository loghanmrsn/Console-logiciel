# Console CIEL 0.7.0 — Windows x86_64

[Télécharger Windows 0.7.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_code_0.7.0.zip). Choisir **Extraire tout**, puis ouvrir **Console_CIEL.exe** à la racine du dossier extrait. Garder l’aide, les licences et **images_profil/** à côté de l’exécutable. Godot n’est pas nécessaire pour jouer.

Avec **Code → Download ZIP**, extraire aussi le ZIP Windows dans `console-ciel/builds/`. Le paquet contient le véritable EXE avec ses ressources intégrées, sans pointeur Git LFS.

Le [projet complet Windows 0.7.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Windows_0.7.0.zip) réunit sources et logiciel. Après extraction : `console-ciel/builds/windows-x86_64-code-0.7.0/Console_CIEL.exe`.

## Chapitre 3 — atelier du code

Après RJ45, IPv4 et Wi-Fi, l’ascenseur donne accès à trois exercices simples : **Python (`print`)**, **HTML (`h1`)**, puis **Markdown (`# `)**. Les réponses sont des choix guidés avec explications ; aucun code utilisateur n’est exécuté. Les étages déjà ouverts restent accessibles. [Parcours de l’enquête](../docs/ENQUETE.md).

Les neuf missions rapportent **50 points à leur première réussite**, soit **450 au maximum par profil**. Deux achats Test à 200 points laissent 50 points, sans autre dépense. Ces Test restent des jeux en préparation. Les anciens profils et achats sont conservés ; rejouer ne redonne aucun point. Le profil en haut à gauche, les repères masqués après réussite, les thèmes et le clavier restent disponibles. [Bibliothèque](../docs/BIBLIOTHEQUE_ET_THEMES.md).

## Rapports et essai sur votre PC

Le [rapport Windows 0.7.0](Console_CIEL_Windows_x86_64_code_0.7.0.verification.json) et le [rapport du projet complet Windows](Console_CIEL_Projet_Complet_Windows_0.7.0.verification.json) décrivent le contenu et les empreintes. [Bilan des vérifications](../docs/DELIVERY.md).

Les tests des ressources compilées utilisent Godot **Linux** et des données isolées ; ils ne constituent pas un lancement natif de l’EXE Windows. Le double-clic, le son et une manette USB physique restent à essayer sur votre PC. [Guide Windows](../docs/WINDOWS.md). Les anciennes livraisons sont conservées séparément sur GitHub.

# Historique — Windows x86_64 0.6.0

[Télécharger Windows 0.6.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.zip). Le ZIP contient le véritable **Console_CIEL.exe**, l’aide, les licences et **images_profil/**. Godot n’est pas nécessaire pour jouer.

1. Télécharger le ZIP Windows et choisir **Extraire tout**.
2. Ouvrir le dossier extrait.
3. Double-cliquer sur **Console_CIEL.exe**, à la racine de ce dossier.

Avec **Code → Download ZIP**, extraire aussi le ZIP Windows dans `console-ciel/builds/`. L’EXE complet mesure **105 240 440 octets** ; sa taille dépasse la limite de 100 Mio par fichier Git. Le paquet contient l’EXE complet, sans pointeur Git LFS.

Le [projet complet](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.6.0.zip) réunit sources et logiciel. Après extraction : `console-ciel/builds/windows-x86_64-chapitre-2-0.6.0/Console_CIEL.exe`.

## Nouveautés

Après les trois missions du local technique, l’ascenseur situé en bas du bureau se déverrouille et mène au chapitre 2 : **liaison RJ45, adressage IPv4, protection Wi-Fi**. Le tableau de missions à droite se déplie ou se replie par son bouton, **T** ou le **bouton de face haut** de la manette (Triangle / Y / X selon le modèle). [Parcours et recette des deux chapitres](../docs/ENQUETE.md).

Les six missions rapportent chacune **50 points une seule fois**, soit **300 points au maximum par profil**. Les anciens profils conservent leurs réussites, observations, points et achats, puis reçoivent les objectifs du chapitre 2. Les deux bilans distinguent les nouveaux gains cumulés de la partie du solde total. Les activités réseau sont fictives et ne changent aucun réglage du PC.

Les deux dispositions d’accueil, les styles/couleurs, les crédits, les profils et les achats **Test 1 à Test 4** sont conservés. Ces Test coûtent **20 / 30 / 40 / 50 points** et ouvrent seulement une page de préparation, sans nouveau gain. [Guide de la bibliothèque](../docs/BIBLIOTHEQUE_ET_THEMES.md).

Pour les photos locales, déposer vos PNG/JPEG/WebP dans **images_profil/**, puis **Profil → Personnaliser → Mes images → Actualiser les images**. Le clavier minuscule avec **⇧**, **123**, **#+=** et **ABC** est conservé.

## Vérification et essai sur votre PC

Vérifications exécutées le **14 octobre 2026** :

- Moteur officiel **4.6.3.stable.official.7d41c59c4**, modèles officiels contrôlés par SHA-512, export release PE32+ x86_64 avec pack intégré.
- CRC du ZIP et empreintes des **203 ressources intégrées**, dont **43 SVG**, contrôlés.
- Pack compilé : **4 351 assertions, zéro échec**, pour ressources, profils, clavier, photos, achats, apparence, bibliothèque, chapitres et tableau de missions.
- Configuration Windows : **18 contrôles, zéro échec**.
- Audit statique : **797 fichiers, 70 UID, 191 références**, zéro erreur ; chargement des ressources avec Godot Linux : **199 contrôles, zéro échec**.
- Sources : **9 568 assertions, zéro échec** dans 14 suites ; persistance : **65 assertions** dans trois processus réels, zéro échec.
- Rendu X11 sous Linux : **694 contrôles, zéro échec**, avec **12 captures réelles** ; outils de packaging : **27 contrôles, zéro échec**.

[Résultats de la recette](../tests/chapitre_2_0.6.0_results/summary.json) et [captures](../docs/screenshots/chapitre_2_0.6.0/). Le [rapport Windows](Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.verification.json) décrit le pack et ses empreintes. Le [rapport du projet complet](Console_CIEL_Projet_Complet_0.6.0.verification.json) donne l’inventaire et l’empreinte finale de l’archive complète.

ZIP Windows : **36 441 246 octets**. SHA-256 : `7a1e8250250bfd6c407c4d843bf2a12a6dae4403607c9589d7faff43b333b82a`.

Les essais du pack exécutent ses ressources avec Godot **Linux**, depuis des dossiers indépendants du dépôt et des données temporaires. Ils ne constituent pas un lancement natif sous Windows. Le double-clic, le son et une manette USB physique restent à essayer sur votre PC ; le logiciel n’est pas signé. [Parcours manuel Windows](../docs/WINDOWS.md).

Livraisons conservées : [0.5.0](Console_CIEL_Windows_x86_64_bibliotheque_0.5.0.zip), [0.4.2](Console_CIEL_Windows_x86_64_profils_0.4.2.zip), [0.4.1](Console_CIEL_Windows_x86_64_navigation_0.4.1.zip), [0.4.0](Console_CIEL_Windows_x86_64_refonte_0.4.0.zip).
