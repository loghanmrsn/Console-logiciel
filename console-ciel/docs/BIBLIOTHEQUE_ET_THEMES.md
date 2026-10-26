# Bibliothèque, boutique et apparence — mise à jour 0.7.0

La version courante **0.7.0** place le profil, son avatar et ses points en haut à gauche ; les quatre onglets sont centrés dans la barre inférieure. **Test 1 à Test 4 coûtent 200 points chacun**, soit **800 pour les quatre**. Les acquisitions précédentes restent possédées sans supplément. Les neuf missions de l’enquête rapportent **450 points au maximum par profil** ; le chapitre 3 aborde Python, HTML et Markdown. [Parcours des trois chapitres et tableau de missions](ENQUETE.md).

La version **0.5.0** organise l’accueil autour de votre bibliothèque, refait les cartes de la boutique et du profil et ajoute les styles de la console dans les paramètres. Tout fonctionne localement, avec les profils et les points existants.

## Choisir une disposition de l’accueil

Dans **Paramètres → Affichage → Disposition de l’accueil**, choisissez :

- **Enquête à gauche · quatre jeux à droite** : l’enquête pédagogique occupe la moitié gauche, avec une couverture réduite ; quatre emplacements sont disposés à droite. Sur un petit écran, les deux parties se placent l’une sous l’autre et le contenu défile.
- **Couvertures égales · défilement horizontal** : les cinq jeux ont des cartes de même taille. Utilisez **Précédent / Suivant**, les flèches ou la manette pour parcourir les couvertures ; le défilement suit le focus.

**Appliquer** conserve la disposition. **Annuler** restaure les réglages précédents. L’enquête reste gratuite et ses commandes **Commencer**, **Continuer** et **Nouvelle partie** restent disponibles selon la progression du profil.

## Acheter les emplacements de test

Les vrais jeux ne sont pas encore prêts. À la demande de l’utilisateur, la boutique propose seulement **Test 1**, **Test 2**, **Test 3** et **Test 4** : ce sont des emplacements pour vérifier les achats et la bibliothèque. Les ouvrir affiche **un jeu en préparation**, sans attribuer de points.

| Emplacement | Prix |
|---|---:|
| Test 1 | 200 points |
| Test 2 | 200 points |
| Test 3 | 200 points |
| Test 4 | 200 points |
| Les quatre | 800 points |

Les treize missions éducatives donnent **650 points**, les deux objectifs du matin à l’hôtel **100 points** et les cinq postes Sudo Hack **250 points**, soit **1 000 points possibles par profil**, avant achats et pénalités. Sans autre dépense ni dette, les quatre Test à 200 points laissent 200 points. Un solde inférieur au prix empêche l’achat. Rejouer une mission, recommencer l’enquête ou ouvrir un emplacement Test ne redonne pas ces récompenses.

À leur introduction en **0.5.0**, les emplacements coûtaient **20, 30, 40 et 50 points**, soit 140 au total ; cette tarification décrit les anciennes livraisons. Un jeu acquis à ces prix reste acquis sans nouveau débit.

Dans **Boutique**, le solde apparaît au-dessus des cartes. Le filtre **Jeux** présente les emplacements ; **Mes achats** affiche les articles du profil actif. Acheter un jeu le débloque dans l’accueil et permet d’ouvrir sa page de préparation. Les avatars, thèmes de profil et cadres restent proposés dans leurs catégories.

Un achat payant est refusé lorsque le solde est nul ou insuffisant. Un article déjà possédé n’est pas facturé une deuxième fois. Le débit et l’ajout à l’inventaire sont enregistrés ensemble ; une erreur de sauvegarde laisse le solde et l’inventaire inchangés. Les achats et les points appartiennent à chaque profil : changer de joueur change sa bibliothèque. Les cosmétiques gratuits du catalogue restent gratuits.

## Personnaliser les paramètres

**Paramètres → Apparence** propose six styles gratuits : **Thème du profil**, **Brume**, **Sable**, **Sauge**, **Nuit** et **Aurore**. Le style Thème du profil utilise le thème équipé par le joueur. Les autres styles ne consomment aucun point et ne remplacent pas les achats du profil.

La **Couleur du fond** et la **Couleur des boutons** se règlent séparément. Choisissez une couleur proposée ou **Personnaliser** pour sélectionner une couleur RGB. **Couleur du style** retrouve la couleur définie par le style sélectionné. Les couleurs personnalisées ont priorité sur le style ; sélectionner **Couleur du style** rétablit sa palette. Les modifications apparaissent immédiatement en aperçu, puis :

- **Appliquer** les enregistre pour les prochains lancements.
- **Annuler** abandonne le brouillon et restaure l’apparence enregistrée.

Les fichiers de paramètres antérieurs restent acceptés : les nouveaux champs utilisent leurs valeurs par défaut lorsqu’ils sont absents. Les réglages audio, plein écran, accessibilité et manette sont conservés. Les styles et couleurs sont des réglages de la console ; le thème cosmétique équipé appartient au profil.

**Crédits** est la dernière catégorie des paramètres. Un bloc de crédits figure aussi en bas de chaque catégorie, avec l’accès aux licences. **À propos** conserve les informations de version, les chemins des sauvegardes et l’aide.

## Profils et photos locales

Les cartes de profils présentent le portrait, les points, la progression de l’enquête et les jeux achetés. Le profil actif est aussi visible dans l’en-tête en haut à gauche, y compris pendant l’enquête ; la barre inférieure conserve quatre onglets centrés sans répéter le pseudo ni le solde. **Modifier** conserve l’éditeur de portrait et le clavier AZERTY : lettres minuscules, **⇧** pour une majuscule, double appui pour verrouiller, **123**, **#+=** et **ABC**.

Ajoutez des PNG, JPEG ou WebP dans **images_profil/** à côté de `Console_CIEL.exe` sous Windows ou de `console-ciel.arm64` sur Raspberry Pi, puis ouvrez **Profil → Modifier → Mes images → Actualiser les images**. En édition Godot, utilisez `console-ciel/images_profil/`. Les images restent locales ; une photo absente fait apparaître l’avatar classique sans effacer les données. [Détails des profils, limites des images et clavier](PROFILS_ET_CLAVIER.md).

## Télécharger la version courante et vérifier

- [Windows 0.7.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_code_0.7.0.zip) : **Extraire tout**, puis lancer `Console_CIEL.exe`.
- [Raspberry Pi 0.7.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Raspberry_Pi_ARM64_0.7.0.zip) : extraire tout, puis lancer `bash ./Lancer_Console_CIEL.sh` dans le dossier extrait, depuis le bureau.
- Projets complets avec sources : [Windows](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Windows_0.7.0.zip) · [Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.7.0.zip).

Les résultats et la portée des contrôles de la livraison courante sont consignés dans [DELIVERY.md](DELIVERY.md). Les recettes et captures ci-dessous sont conservées pour leur version.

## Recette historique 0.6.1

La recette **0.6.1 du 14 octobre 2026** a passé **11 844 assertions source**, dont **235 pour les achats**, **1 912 pour l’en-tête du profil** et **477 pour la bibliothèque**, sans échec. Le rendu réel X11 a passé **58 contrôles** et produit 8 captures ; le pack compilé a passé **6 547 assertions** avec Godot Linux. [Résumé historique 0.6.1](../tests/confort_0.6.1_results/summary.json).

Captures : [profil à gauche et tarifs à l’accueil](screenshots/confort_0.6.1/home_profile_left_prices_200_1280x720.png), [boutique à 200 points](screenshots/confort_0.6.1/shop_prices_200_1280x720.png), [grand texte en 800 × 480](screenshots/confort_0.6.1/home_profile_left_800x480_large.png), [style Nuit en 800 × 480](screenshots/confort_0.6.1/home_profile_left_800x480_nuit.png) et [les huit captures de la livraison](DELIVERY.md).

## Historique 0.5.0

- [Windows 0.5.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_bibliotheque_0.5.0.zip) : **Extraire tout**, puis lancer `Console_CIEL.exe`.
- [Projet complet 0.5.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.5.0.zip) : l’EXE est dans `console-ciel/builds/windows-x86_64-bibliotheque-0.5.0/`.
- [Guide Windows et recette sur votre PC](WINDOWS.md), [contenu du projet complet](ARCHIVE_COMPLETE.md).

Les suites ciblées de la livraison **0.5.0** exécutées sur le projet source comptent **127 assertions pour les achats** et **1 881 pour l’apparence**, sans échec. Ces tests couvrent la logique et les sauvegardes sous Godot Linux ; ils ne constituent pas un essai du binaire Windows. Les rapports de la livraison distinguent les tests source, le rendu Linux et les contrôles du paquet exporté. Le lancement, le son et la manette USB sous Windows restent à vérifier sur un PC Windows.

La recette source complète compte **8 438 assertions**, sans échec. Le rendu X11 a passé **501 contrôles** et produit **17 captures réelles** des deux dispositions, de la boutique, des profils et des paramètres. Le pack Windows compilé a passé **3 242 assertions**, sa configuration **18 contrôles**. [Résultats](../tests/bibliotheque_0.5.0_results/summary.json) et [captures](screenshots/bibliotheque_0.5.0/).

## Vérifier la bibliothèque courante

1. Vérifier avatar, pseudo et points en haut à gauche sur les écrans avec profil actif, en petit écran et en grand texte ; vérifier les quatre onglets centrés en bas.
2. Vérifier les quatre prix de **200 points** dans Boutique et dans les deux dispositions d’accueil. Un solde de 0 ou 199 doit refuser l’achat ; un solde de 200 permet un seul achat et devient nul.
3. Reprendre un profil ayant déjà acheté un Test dans une ancienne version : le jeu reste acquis, aucun complément n’est débité.
4. Terminer les neuf missions avec un profil neuf, sans achat : le solde est de 450. Acheter deux Test laisse 50 points ; un troisième achat à 200 est refusé. Rejouer n’ajoute aucun point.

Le [guide Windows](WINDOWS.md) complète ce parcours avec les repères de mission, l’ascenseur, la reprise et le bilan en pause. Les résultats 0.5.0 et 0.6.1 ci-dessus restent historiques et ne remplacent pas la recette courante.

Les cinq épreuves **Sudo Hack** se jouent dans le hall du CTF. Chaque poste donne 50 points une seule fois. Après le flag final, le bus devant le CTF ramène en ville ; les lieux restent visitables. [Toutes les solutions illustrées](../../solution/README.md).
