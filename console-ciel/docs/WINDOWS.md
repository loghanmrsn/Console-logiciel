# Version portable Windows x86_64 — 0.14.0

**[Télécharger Windows 0.14.0 — épreuves de l’hôtel enrichies](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_hotel_visuel_0.14.0.zip)**. Décompresser **tout** le ZIP, puis lancer **Console_CIEL.exe** dans le dossier extrait. Godot ne doit pas être installé sur le PC destinataire.

La version **0.14.0** propose le clavier à l’écran dans les exercices du chapitre 3 : **Python (`print`)**, **HTML (`h1`)** et **Markdown (`# `)**. Après les trois missions réseau du chapitre 2, l’ascenseur conduit à l’atelier du code ; les étages ouverts restent accessibles. Les réponses se saisissent au clavier à l’écran ou physique, avec erreurs expliquées, sans exécution de code utilisateur. Le tableau de missions à droite se déplie ou se replie avec **T** ou le **bouton de face haut**. [Parcours des cinq chapitres](ENQUETE.md). Le profil en haut à gauche, les achats, les styles et les repères masqués après réussite sont conservés. [Guide de la bibliothèque](BIBLIOTHEQUE_ET_THEMES.md). [Rapport Windows](../builds/Console_CIEL_Windows_x86_64_hotel_visuel_0.14.0.verification.json).

Le [projet complet 0.14.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Windows_0.14.0.zip) contient aussi les sources. Dans ce ZIP, le logiciel se trouve dans **console-ciel/builds/windows-x86_64-hotel-visuel-0.14.0/Console_CIEL.exe**. [Contenu du projet complet](ARCHIVE_COMPLETE.md).

## Lancer sur votre PC

1. Télécharger le ZIP Windows ci-dessus. Avec **Code → Download ZIP**, ouvrir d’abord le ZIP Windows dans `console-ciel/builds/`.
2. Choisir **Extraire tout**. Ne pas lancer le programme depuis l’aperçu du ZIP.
3. Double-cliquer sur **Console_CIEL.exe** dans le dossier extrait.

Garder l’aide, les licences et **images_profil/** à côté de l’EXE. Les ressources du jeu sont intégrées (`embed_pck=true`) ; le ZIP reste la livraison à copier dans son ensemble. L’EXE dépasse la limite de taille d’un fichier GitHub ordinaire et est donc distribué dans l’archive portable.

Le moteur est fixé à **4.6.3.stable.official.7d41c59c4**, édition standard, rendu **Compatibility**, x86_64. Windows 10/11 avec un pilote OpenGL 3.3 est conseillé. Le programme ne demande pas de droits administrateur. Le préréglage Linux ARM64 Raspberry Pi reste distinct.

## Profils, bibliothèque et achats

Au premier lancement, créer un profil avec le clavier virtuel ou physique. L’éditeur conserve les minuscules, **⇧**, **123**, **#+=** et **ABC**. Pour les photos, déposer des PNG, JPEG ou WebP dans **images_profil/** voisin de l’EXE, puis **Profil → Modifier → Mes images → Actualiser les images**. Le [guide des profils](PROFILS_ET_CLAVIER.md) précise les limites et le remplacement d’une image absente par l’avatar classique.

L’enquête pédagogique est gratuite : **50 points par première réussite**, treize missions réparties en cinq chapitres, **650 points**. La descente au rez-de-chaussée après la nuit et la récupération du sac ajoutent **50 points chacune**, soit **750 points au maximum par profil**. **Test 1 / 2 / 3 / 4** coûtent **200 points chacun**, soit **800 au total**. Sans autre dépense ni pénalité, quatre premières réussites financent un jeu ; terminer les treize missions et les deux objectifs du matin puis acheter trois Test laisse 150 points. Les autres achats attendent de futurs défis ou un solde déjà présent dans un ancien profil ; rejouer ne redonne aucun point. Les jeux déjà acquis restent achetés sans supplément. Les vrais jeux n’étant pas prêts, ces achats ouvrent seulement une page **jeu en préparation** ; leur ouverture ne rapporte aucun point. Un achat payant est refusé à solde nul ou insuffisant. Un article possédé n’est pas acheté deux fois. Solde et inventaire sont sauvegardés ensemble, séparément pour chaque profil.

**Boutique → Jeux** présente ces emplacements ; **Mes achats** retrouve les acquisitions du joueur. Les cosmétiques existants restent disponibles. Les cartes de profil affichent les points, objectifs et jeux acquis. Le profil actif reste visible dans l’en-tête en haut à gauche, y compris pendant l’enquête ; la barre du bas affiche uniquement les quatre onglets centrés.

## Affichage, apparence et crédits

La fenêtre est redimensionnable, **1280 × 720** par défaut, minimum **800 × 480**. **Paramètres → Affichage** règle le plein écran et la disposition de l’accueil : enquête à gauche avec quatre jeux à droite, ou cinq couvertures de même taille avec défilement horizontal. Sur petit écran, la disposition s’adapte et défile. **Précédent / Suivant** et le focus clavier/manette parcourent les couvertures.

**Paramètres → Apparence** propose gratuitement **Thème du profil, Brume, Sable, Sauge, Nuit, Aurore**. Choisir séparément la couleur du fond et des boutons, ou **Personnaliser** pour une couleur RGB. L’aperçu est immédiat ; **Appliquer** enregistre, **Annuler** restaure. Les anciens fichiers de réglages sont compatibles. Grand texte, animations et transparence réduites restent dans Accessibilité.

**Crédits** est la dernière catégorie des paramètres ; un bloc de crédits figure aussi au bas de chaque catégorie. **À propos** conserve l’aide, la version et les chemins des données.

Après une réussite sauvegardée, le repère et le bouton d’interaction de la mission terminée disparaissent. Le meuble réparé reste visible dans le décor ; l’ascenseur reste interactif pour changer de chapitre. **Pause → Bilan du chapitre** permet de revoir un chapitre terminé. Reprendre une sauvegarde conserve les repères masqués ; une nouvelle partie les rétablit pour les missions à refaire, sans nouvelle récompense.

## Commandes et fermeture

| Action | Clavier | Manette compatible Godot |
|---|---|---|
| Naviguer | Flèches ; Tab / Maj+Tab | Croix / joystick gauche |
| Valider | Entrée / Entrée numérique | Bouton de face bas |
| Retour | Échap | Bouton de face droit |
| Déplacer le personnage | Flèches ou ZQSD | Croix / joystick gauche |
| Interagir | Espace | Bouton de face bas |
| Afficher / masquer le tableau de missions | T | Bouton de face haut (Triangle / Y / X selon la manette) |
| Pause | P | Start / Menu |
| Catégorie précédente / suivante | Q / E, hors saisie de texte | Épaules gauche / droite |

La souris est facultative. **Paramètres → Commandes → Test des commandes** montre les entrées effectivement reçues et la zone morte. Une déconnexion suspend l’enquête ; reconnecter ne la reprend pas automatiquement. Le mapping du contrôleur fabriqué doit être mesuré sur le matériel réel.

**Paramètres → Quitter l’application** et la croix de la fenêtre demandent confirmation et sauvegardent. Un échec laisse l’application ouverte avec possibilité de réessai. Un brouillon de paramètres propose appliquer, annuler ou revenir aux réglages. Quitter n’arrête ni ne redémarre Windows.

## Sauvegardes et mises à jour

Les données sont dans le dossier utilisateur **console-ciel**, généralement **`%APPDATA%\console-ciel`** sous Windows. **Win+R** puis ce chemin permet de l’ouvrir ; **Paramètres → À propos** affiche le chemin effectif calculé par Godot, y compris si Windows redirige ce dossier.

| Fichier | Contenu |
|---|---|
| `profiles/<identifiant>.json` | Profil, progression, points, inventaire, jeux acquis et équipement |
| `settings.cfg` | Réglages de la console, disposition, style et couleurs |
| `session.json` | Dernier profil choisi |
| `logs/godot.log` | Journal Godot |

Le ZIP ne contient aucun profil prérempli ni sauvegarde personnelle. Une mise à jour dans un nouveau dossier conserve ces données ; ne pas effacer le dossier utilisateur. Copier également **images_profil/** pour conserver les photos locales et garder leurs noms stables. Fermer normalement le logiciel avant de copier les sauvegardes. Les achats et points changent en mémoire seulement après une sauvegarde réussie. Les anciens profils reçoivent les missions manquantes sans perdre leurs anciennes réussites, leurs observations, points, récompenses ou achats ; le schéma reste en version 1. Continuer restaure aussi la salle et le chapitre atteints.

## Refaire l’export

Installer Godot standard **4.6.3 stable** et les [modèles d’export officiels correspondants](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable). Depuis `console-ciel/`, dans PowerShell :

```powershell
.\tools\export_windows.ps1 -GodotPath 'C:\Outils\Godot_v4.6.3-stable_win64_console.exe' -ArchiveName Console_CIEL_Windows_x86_64_hotel_visuel_0.14.0.zip -OutputDirectory windows-x86_64-hotel-visuel-0.14.0
```

Adapter le chemin du moteur. Le script cible PowerShell **5.1 ou supérieur**, vérifie la version exacte, importe les ressources et exporte avec **Windows Desktop x86_64** dans un dossier provisoire. Il vérifie le PE x86_64, ajoute aide, licences et images_profil, puis assemble l’archive. Un échec conserve la livraison précédente. Le preset Pi n’est pas modifié.

Le script PowerShell a été analysé et testé historiquement avec PowerShell 7.4.13 sous Linux ; cela ne constitue pas un essai de Windows PowerShell 5.1. Les [résultats historiques](../tests/windows_results/) sont conservés. Depuis l’éditeur, le preset **Windows Desktop x86_64**, sans débogage et avec pack intégré, permet également d’exporter le binaire ; le script assemble le ZIP portable complet.

## Vérifications et recette Windows

Le [rapport Windows 0.14.0](../builds/Console_CIEL_Windows_x86_64_hotel_visuel_0.14.0.verification.json) décrit les fichiers et empreintes du paquet ; le [rapport du projet complet](../builds/Console_CIEL_Projet_Complet_Windows_0.14.0.verification.json) décrit l’archive des sources et du binaire. Les rapports de recette distinguent logique source, captures sous Linux, configuration Windows et pack compilé. Les résultats historiques des versions précédentes sont conservés séparément.

La [livraison courante](DELIVERY.md) rassemble les résultats source, persistance, rendu réel et packs exportés. Les chiffres historiques ci-dessous décrivent uniquement leurs versions.

La recette historique **0.6.0** a passé **9 568 assertions source** (14 suites), **65 assertions de persistance** sur trois processus, **694 contrôles de rendu X11** avec 12 captures, **4 351 assertions du pack compilé**, **18 contrats Windows** et **27 contrôles de packaging**, tous avec zéro échec. Le pack contient **203 ressources contrôlées**, dont **43 SVG**. [Résumé de recette](../tests/chapitre_2_0.6.0_results/summary.json), [captures](screenshots/chapitre_2_0.6.0/) et [taille/empreinte du téléchargement](../builds/README_WINDOWS.md).

Tester un pack embarqué avec le moteur Linux vérifie ses ressources et sa logique ; cela ne lance pas l’EXE Windows. Le double-clic, le rendu, le son et les périphériques USB sous Windows restent à essayer sur votre PC :

1. Extraire, lancer, créer deux profils, ajouter une photo et saisir minuscules, majuscules et chiffres. Vérifier l’avatar, le pseudo et les points en haut à gauche sur chaque écran avec profil actif ; vérifier les quatre onglets centrés sans pseudo ni solde dans la barre.
2. Vérifier que les quatre prix sont de **200 points** dans la boutique et les deux dispositions de l’accueil. Avec zéro ou 199 points, un achat doit être refusé ; avec 200, un achat laisse zéro point. Afficher et masquer le tableau de missions par son bouton, T et le bouton de face haut ; en pause ou pendant un défi, vérifier que les actions ne traversent pas les dialogues.
3. Après chaque mission sauvegardée, vérifier que son repère et son bouton d’interaction disparaissent, tandis que son meuble reste visible et réparé. Terminer les trois missions du chapitre 1 : l’ascenseur en bas du bureau reste bloqué avant et devient accessible après. Lire le bilan de 150 points, monter, puis terminer RJ45, IPv4 et Wi-Fi. Le second bilan doit afficher 300 nouveaux points cumulés pour un profil neuf sans achat. Vérifier que le chapitre 3 est bloqué avant les trois réussites réseau, puis y accéder. Terminer Python, HTML et Markdown : le troisième bilan doit afficher 450 nouveaux points cumulés sans achat. Vérifier **Pause → Bilan du chapitre** après chaque chapitre terminé et les trajets d’ascenseur entre les cinq chapitres ; avant la fin d’un chapitre, ce bouton de bilan n’est pas disponible.
4. Fermer et reprendre entre les missions et à l’étage. Les repères des missions terminées doivent rester masqués. Vérifier le chapitre restauré et un ancien profil déjà terminé au chapitre 1. Commencer une nouvelle partie : les repères des missions à refaire redeviennent disponibles ; rejouer les treize missions sans gain supplémentaire.
5. Avec les 750 points du parcours complet pour un profil neuf, acheter trois emplacements Test, vérifier le solde de 150 et le refus d’un quatrième achat à 200. Retrouver sa carte à l’accueil et ouvrir la page de préparation sans gain. Un Test déjà acquis à l’ancien prix reste possédé sans débit supplémentaire. Changer de profil pour contrôler la séparation des achats.
6. Choisir les deux dispositions d’accueil, parcourir le carrousel au clavier ou à la manette.
7. Tester les styles, une couleur du fond et une couleur des boutons ; Annuler, puis Appliquer. Retrouver les réglages après relance et consulter Crédits.
8. Vérifier fenêtre et plein écran, texte normal et grand texte à **1920 × 1080, 1280 × 720, 1024 × 600 et 800 × 480**.
9. Fermer, relancer, reprendre l’enquête et vérifier points et achats ; essayer déconnexion et reconnexion de la manette USB.
10. Après la nuit, suivre l’objectif jusqu’au rez-de-chaussée, puis réparer la machine à café. Vérifier sélection, désélection, refus d’une paire de couleurs différentes et validation des trois bonnes paires. Prendre le café, récupérer le sac en chambre 206 et suivre le bus jusqu’au hall sudo hack. Vérifier les deux gains de 50 points et leur absence lors d’un rejeu ; reprendre une sauvegarde à plusieurs étapes de ce trajet.

## Livraisons conservées

- [Windows 0.6.1 — confort visuel](../builds/Console_CIEL_Windows_x86_64_confort_0.6.1.zip), [résultats historiques](../tests/confort_0.6.1_results/summary.json).
- [Windows 0.6.0 — chapitre 2](../builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.zip), [résultats historiques](../tests/chapitre_2_0.6.0_results/summary.json).
- [Windows 0.5.0 — bibliothèque et thèmes](../builds/Console_CIEL_Windows_x86_64_bibliotheque_0.5.0.zip), [guide](BIBLIOTHEQUE_ET_THEMES.md).
- [Windows 0.4.2 — profils et clavier](../builds/Console_CIEL_Windows_x86_64_profils_0.4.2.zip), [guide](PROFILS_ET_CLAVIER.md).
- [Windows 0.4.1 — navigation translucide](../builds/Console_CIEL_Windows_x86_64_navigation_0.4.1.zip), [captures et recette](NAVIGATION_TRANSLUCIDE.md).
- [Windows 0.4.0 — refonte graphique](../builds/Console_CIEL_Windows_x86_64_refonte_0.4.0.zip), [captures et recette](REFONTE_GRAPHIQUE.md).

Les anciens exécutables 0.3.0/0.3.1 n’étaient pas inclus dans les sources reçues. Les rapports historiques sont conservés sans les présenter comme des essais du binaire courant. Les performances Pi et le contrôleur fabriqué restent dans les [limites connues](KNOWN_ISSUES.md).

Les trois livres animés du coin ressources (chapitre 3) et le chapitre 4 restent disponibles : pare-feu, conflit IPv4 et masque /26. L’ascenseur propose Descendre d’étage, Monter d’étage et Retour au menu ; Échap reste dans la pièce. Les anciennes sauvegardes sont conservées.

Le **chapitre 5** reste disponible : portable → **Y aller** → labyrinthe avec inscriptions murales et terminal simulé. Une seule mission est affichée **???** ; le clavier virtuel apparaît pour les identifiants, les mots de passe et les commandes. Les quatre premiers chapitres conservent trois missions chacun. La connexion et la reprise sont sauvegardées. Aucune commande n’est exécutée sur le système hôte.

Le parcours de l’hôtel prolonge l’exploration après le chapitre 5 : descente jusqu’au premier niveau, porte de sortie en bas à gauche, cour et immeuble d’en face. Le second bâtiment devient un hôtel doté d’un grand hall de **6 400 × 4 200** et de salles dédiées au parcours de la chambre 206. La carte en haut à gauche affiche la position et la sortie ; **→** l’affiche ou la masque, **D / ZQSD ou le joystick** restent disponibles pour marcher. Les treize missions de l’enquête conservent leurs 650 points ; les deux objectifs du matin portent le total possible à 750 points par profil. Les portes enregistrent les zones avant chaque déplacement.

Le parcours de l’hôtel comprend : réservation, panne informatique, escaliers et chambre **206**. [Guide de l’hôtel](HOTEL.md).

La version **0.14.0** poursuit le récit après le sommeil. Au réveil, le panneau vous invite à **descendre au rez-de-chaussée** : cette première descente rapporte **50 points**. Entrez dans la salle du petit déjeuner et asseyez-vous à table. Le café oublié vous conduit à la machine en panne. Son panneau présente six fils : **A, B, C** en haut et **1, 2, 3** en bas. Reliez les couleurs identiques : **A–3 rouge, B–2 vert et C–1 marron**. Le fil sélectionné brille ; un nouvel appui le désélectionne. Une fois les trois paires reliées, prenez votre café, remontez dans la **chambre 206** et récupérez le sac à dos contenant l’ordinateur, pour **50 points supplémentaires**. Redescendez, sortez de l’hôtel et rejoignez l’arrêt de bus. Le trajet mène au bâtiment du CTF **sudo hack**, dont le hall attend cinq futurs défis. [Guide détaillé](HOTEL.md).

Les deux récompenses du matin sont accordées une seule fois par profil, même après Nouvelle partie. La réparation du café et le trajet en bus ne rapportent pas de points. Les cinq défis du CTF ne sont pas encore disponibles.

Les modèles et collisions revus dans la version 0.13.0 sont conservés. Le personnage passe devant ou derrière les objets selon sa position. Dans la cour, un passage piéton, des feux et des voitures lentes encadrent la traversée : départ au vert sans frais ; traversée achevée au rouge sans choc, **200 points** ; collision, retour au trottoir de départ en gardant la progression. Les points disponibles paient la pénalité, puis une dette conserve le reste et se rembourse sur les prochains gains. [Règles et vérifications](TRAFFIC.md).

La version **0.14.0** enrichit les deux épreuves existantes de l’hôtel : local informatique, cartes du diagnostic, buffet, machine à café et panneau de câblage. Les trois nouveaux meubles ont leur collision. La direction artistique, la progression, les points et les pénalités restent ceux du projet. [Détails du rendu et des contrôles](HOTEL_VISUAL.md).
