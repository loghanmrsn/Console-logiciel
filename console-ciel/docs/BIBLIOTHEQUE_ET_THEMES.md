# Bibliothèque, boutique et apparence — 0.5.0

La version courante **0.6.0** ajoute trois missions à l’étage de l’enquête, accessibles par l’ascenseur après le chapitre 1, et porte les récompenses uniques à **300 points par profil**. [Parcours des deux chapitres et tableau de missions](ENQUETE.md). Les prix et les fonctions de bibliothèque ci-dessous restent valables ; les 150 points cités plus bas décrivent les trois missions disponibles en 0.5.0.

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
| Test 1 | 20 points |
| Test 2 | 30 points |
| Test 3 | 40 points |
| Test 4 | 50 points |
| Les quatre | 140 points |

Chaque mission pédagogique réussie pour la première fois rapporte **50 points**, soit **150 points au maximum par profil**. Rejouer une mission, recommencer l’enquête ou ouvrir un emplacement Test ne redonne pas ces récompenses.

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

Les cartes de profils présentent le portrait, les points, la progression de l’enquête et les jeux achetés. **Modifier** conserve l’éditeur de portrait et le clavier AZERTY : lettres minuscules, **⇧** pour une majuscule, double appui pour verrouiller, **123**, **#+=** et **ABC**.

Ajoutez des PNG, JPEG ou WebP dans **images_profil/** à côté de `Console_CIEL.exe`, puis ouvrez **Profil → Modifier → Mes images → Actualiser les images**. En édition Godot, utilisez `console-ciel/images_profil/`. Les images restent locales ; une photo absente fait apparaître l’avatar classique sans effacer les données. [Détails des profils, limites des images et clavier](PROFILS_ET_CLAVIER.md).

## Télécharger et vérifier

- [Windows 0.5.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_bibliotheque_0.5.0.zip) : **Extraire tout**, puis lancer `Console_CIEL.exe`.
- [Projet complet 0.5.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.5.0.zip) : l’EXE est dans `console-ciel/builds/windows-x86_64-bibliotheque-0.5.0/`.
- [Guide Windows et recette sur votre PC](WINDOWS.md), [contenu du projet complet](ARCHIVE_COMPLETE.md).

Les suites ciblées exécutées sur le projet source comptent **127 assertions pour les achats** et **1 881 pour l’apparence**, sans échec. Ces tests couvrent la logique et les sauvegardes sous Godot Linux ; ils ne constituent pas un essai du binaire Windows. Les rapports de la livraison distinguent les tests source, le rendu Linux et les contrôles du paquet exporté. Le lancement, le son et la manette USB sous Windows restent à vérifier sur un PC Windows.

La recette source complète compte **8 438 assertions**, sans échec. Le rendu X11 a passé **501 contrôles** et produit **17 captures réelles** des deux dispositions, de la boutique, des profils et des paramètres. Le pack Windows compilé a passé **3 242 assertions**, sa configuration **18 contrôles**. [Résultats](../tests/bibliotheque_0.5.0_results/summary.json) et [captures](screenshots/bibliotheque_0.5.0/).
