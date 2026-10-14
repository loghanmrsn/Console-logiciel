# Console CIEL 0.6.1 — Windows x86_64

[Télécharger Windows 0.6.1](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_confort_0.6.1.zip). Choisir **Extraire tout**, puis ouvrir **Console_CIEL.exe** à la racine du dossier extrait. Garder l’aide, les licences et **images_profil/** à côté de l’exécutable. Godot n’est pas nécessaire pour jouer.

Avec **Code → Download ZIP**, extraire aussi le ZIP Windows dans `console-ciel/builds/`. Le paquet contient le véritable EXE avec ses ressources intégrées, sans pointeur Git LFS ; son fichier dépasse la limite de 100 Mio pour un fichier Git ordinaire.

Le [projet complet 0.6.1](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.6.1.zip) réunit sources et logiciel. Après extraction : `console-ciel/builds/windows-x86_64-confort-0.6.1/Console_CIEL.exe`.

## Ajustements 0.6.1

- Profil, avatar et points en haut à gauche, y compris pendant l’enquête ; quatre onglets centrés dans la barre du bas.
- **Test 1 à Test 4 : 200 points chacun**, soit 800 au total. Les anciens achats restent acquis sans supplément ; ces jeux ouvrent seulement une page de préparation.
- Repère et bouton d’interaction masqués après réussite sauvegardée d’une mission. Les meubles réparés restent visibles et l’ascenseur reste interactif dans les deux sens.
- **Pause → Bilan du chapitre** permet de revoir un chapitre terminé.

Les six missions rapportent toujours 50 points une seule fois chacune, **300 au maximum par profil**. Quatre réussites sans dépense préalable financent un jeu ; les six réussites suivies de cet achat laissent 100 points. Les autres jeux attendent de futurs défis ou un solde déjà présent dans un ancien profil ; rejouer ne redonne aucun point. [Guide de la bibliothèque](../docs/BIBLIOTHEQUE_ET_THEMES.md) et [parcours de l’enquête](../docs/ENQUETE.md).

## Rapports et essai sur votre PC

[Rapport Windows 0.6.1](Console_CIEL_Windows_x86_64_confort_0.6.1.verification.json) et [rapport du projet complet 0.6.1](Console_CIEL_Projet_Complet_0.6.1.verification.json) : contenu et empreintes des archives courantes. Les résultats historiques 0.6.0 ci-dessous sont conservés séparément.

Vérifications **0.6.1 du 14 octobre 2026** : **11 844 assertions source** dans 16 suites, **65 de persistance** entre trois processus, **58 contrôles avec rendu X11** et 8 captures, **6 547 assertions du pack compilé**, **18 contrats Windows** et **27 contrôles de packaging**, zéro échec. Les **203 ressources intégrées**, dont **43 SVG**, et les CRC du ZIP ont été contrôlés. Audit statique : **818 fichiers, 72 UID, 194 références**, zéro erreur ; chargement natif des ressources sous Godot Linux : **203 contrôles, zéro échec**. [Résumé courant](../tests/confort_0.6.1_results/summary.json) et [liens des huit captures réelles](../docs/DELIVERY.md).

ZIP Windows : **36 442 313 octets** ; EXE : **105 241 656 octets**. SHA-256 du ZIP : `bcceba1c337c69db48cfe5e236856246ecd9b97759f1111b079efd8f9de0ba37`.

Les tests de logique et de pack embarqué s’exécutent avec Godot **Linux** et des données isolées ; ils ne constituent pas un lancement natif de l’EXE Windows. Le double-clic, le son et une manette USB physique restent à essayer sur votre PC. Le [guide Windows](../docs/WINDOWS.md) inclut le profil en haut à gauche, les quatre prix, la disparition des repères, le bilan en pause, la reprise et les deux trajets d’ascenseur. Les anciens ZIP **0.6.0 et antérieurs** sont conservés.

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
