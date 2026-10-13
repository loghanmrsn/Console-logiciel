# Console CIEL 0.4.0 — refonte graphique réalisée

Le 13 octobre 2026, le projet existant a été modifié directement avec **Godot 4.6.3.stable.official.7d41c59c4**, rendu **Compatibility**. Les services, définitions de missions, catalogue, schéma des profils et règles de récompense sont inchangés. Leurs empreintes et celles des anciennes archives ont été comparées avant/après. Aucun envoi externe ni nouveau mécanisme de démarrage n'a été créé.

## Défauts confirmés et corrections

- L'accueil utilisait deux colonnes sans occuper la hauteur disponible ; son illustration mesurait seulement 108 pixels de haut. La nouvelle carte d'enquête remplit la zone principale, dans une composition centrée limitée à 1 400 pixels. La présentation se simplifie sur petit écran ; la progression et les deux actions restent visibles.
- La colonne secondaire est remplacée par **cinq onglets persistants** avec SVG original, libellé, soulignement actif et bordure de focus distincte. La barre réserve sa place sous le contenu, sans le recouvrir. Gauche/droite restent dans la barre ; haut/bas rejoignent le contenu. Les onglets ne recréent pas l'écran déjà affiché. Un brouillon de paramètres demande une annulation explicite avant de changer d'onglet.
- **Quitter l'application** est dans les paramètres ; Échap à l'accueil et la croix conservent la confirmation/sauvegarde existante. La barre est masquée en jeu et dans les paramètres/aide ouverts depuis la pause.
- Le décor dessiné comme un plan est remplacé par des **ressources séparées** : carrelage calme, parquet, murs épais, seuil, tableau, établi et outils, étagère, bureau, chaise, tour, moniteur, armoire, plante et porte. Les accessoires sont des objets distincts ; le niveau n'est pas une image aplatie.
- Le personnage utilise douze poses SVG, quatre orientations, marche/immobilité, ombre et collision aux pieds. Le tri vertical des objets règle le passage devant/derrière le mobilier. Les collisions d'origine sont conservées, avec une chaise et une plante correspondant à leurs nouvelles formes.
- Les grandes étiquettes sont remplacées par une signalétique décorative de 12 pixels et un **HUD natif** : nom de l'objet proche, marqueur discret, interaction compacte et objectif courant. La liste complète s'affiche par son bouton ou **Pause → Afficher les objectifs**, donc sans souris obligatoire.
- Les missions restaurent la lumière, révèlent la note, ouvrent la porte et désactivent sa collision, puis modifient le moniteur. Son bref retour visuel respecte la réduction des animations. Les réponses et points restent validés par InvestigationService. Le marqueur se dessine sur l’équipement plutôt que sur la tête du personnage ; sa portée d’interaction reste inchangée.
- Les cartes de boutique montrent un aperçu réel du type de cosmétique. Paramètres et profils utilisent des descriptions courtes. Les pauses, dialogues et défis sont centrés, avec défilement suivant le focus.

L'inspection a également permis de corriger des ombres SVG interprétées en noir (notation alpha remplacée par `fill-opacity`), une texture d'aperçu libérée trop tôt, la hauteur calculée avant l'apparition de la barre, et une contrainte de 275 pixels qui débordait en jeu à 800 × 480 lorsqu'une notification réduisait la zone disponible.

## Ressources et fichiers

Les **36 SVG sont originaux et CC0 1.0** : `assets/art/world/`, `assets/art/character/`, `assets/art/icons/`. Ils se régénèrent avec `python3 tools/generate_art.py`, sans réseau. Sources/licences dans [assets/LICENSES.md](../assets/LICENSES.md). Police intégrée à Godot ; aucun téléchargement de police ou ressource propriétaire.

Principaux fichiers modifiés : `scripts/ui/main.gd`, `theme_factory.gd`, `enquiry_art.gd`, `product_card.gd`, `scripts/game/investigation_world.gd`, `player.gd`, `interactable.gd`, `demo_game.gd`, `challenge_panel.gd`. Composants ajoutés : `scripts/ui/navigation_bar.gd`, `cosmetic_preview.gd`, `scripts/game/room_art.gd`. Version logiciel et métadonnées Windows passent à **0.4.0** ; la version du moteur et le preset Linux ARM64 restent identiques.

L'interface garde `window/stretch/mode="disabled"` : elle se recompose à la taille réelle de fenêtre au lieu d'étirer une page 720p. Les cartes et la barre ont des largeurs maîtrisées. Le SubViewport suit la surface disponible ; Camera2D cadre la salle et suit le personnage lorsque le petit écran impose de rogner un axe. Les SVG sont importés en textures, filtrés en mode linéaire ; aucun flou, shader obligatoire, effet animé permanent ou rendu 3D.

## Vérifications exécutées

Les données sont isolées dans des sous-dossiers de test et des racines XDG temporaires. Aucun vrai profil n'est inclus dans les livraisons.

| Vérification | Résultat et portée |
|---|---|
| Import natif | Godot 4.6.3, scripts et ressources sans erreur bloquante |
| Services | 190 assertions, zéro échec ; profils, portefeuille, achats, écritures/récupération |
| Enquête | 189 assertions, zéro échec ; prérequis, erreurs, trois réponses, récompenses uniques et reprise |
| Recette UI | 1 974 assertions, zéro échec ; clavier et manette **synthétique**, collisions, trois missions, pause, paramètres, achats, profils, validations rapides et géométrie |
| Navigation refondue | 796 assertions, zéro échec ; quatre résolutions × normal/grand/opaque, cinq destinations, focus distinct, absence de recouvrement, pseudo de 16 caractères, contexte de pause et profils inchangés |
| Parcours avec affichage | 310 assertions via événements natifs injectés sous X11 ; aucune manette physique revendiquée |
| Rendu réel | Matrice de 101 captures et complément de 22 captures (certaines remplacent les vues de menu/paramètres) ; zéro échec de capture ; inspection des quatre tailles, texte normal et grand/opaque |
| Contrat Windows | 16 assertions, zéro échec ; preset, architecture, fenêtre et `user://` |
| Pack Windows exporté | 47 assertions métier et 50 assertions ressources/UI, zéro échec, avec le moteur **Linux headless** chargeant le pack intégré au EXE |

Le test de corruption des réglages produit volontairement une erreur native ConfigFile « Unexpected EOF » sur son fichier isolé ; la récupération contrôlée est vérifiée ensuite.

Journaux et inventaires : `tests/refonte_results/`. Le rendu a réellement été exécuté avec un serveur X11 virtuel et **Mesa llvmpipe**. Le pilote signale qu'il ne permet pas de modifier V-Sync. L'audio utilise Dummy : ces essais ne prouvent pas le son perçu. Certaines sessions graphiques signalent aussi des ressources audio WAV/playback encore référencées à leur fermeture, malgré l'arrêt explicite des lecteurs ; les tests fonctionnels passent, mais cet avertissement de fin de fixture reste à contrôler avec un vrai pilote audio. Aucune erreur de script n'est ignorée.

Une passe graphique exécutée pendant d’autres rendus a manqué trois assertions de synchronisation (285 contrôles), sans erreur de script. Le même parcours relancé seul passe 310 contrôles. Les deux journaux sont conservés (`graphical-input-attempt.log`, `graphical-input.log`) ; exécuter les recettes graphiques l’une après l’autre. Cela ne dispense pas de la recette Windows réelle.

Les tests de la barre incluent **1920 × 1080, 1280 × 720, 1024 × 600 et 800 × 480**, normal/grand texte et opacité renforcée. Le jeu ne bouge pas derrière les dialogues ; les commandes reviennent après fermeture. Les sauvegardes/reprises, récompenses de 50 points une fois, achat de 20 points et équipement conservé restent contrôlés. Le changement de collision aux pieds adapte les assertions aux limites des surfaces, sans supprimer ces tests.

## Captures réelles avant/après

Toutes viennent du viewport Godot exécuté, avec profil isolé Loghan. Les ressources SVG sont des illustrations créées ; ces PNG sont des captures de l'application.

- Avant : `screenshots/refonte/avant/accueil_1280x720.png` et `piece_1280x720.png` ; mêmes vues également à 1920 × 1080.
- Après : `screenshots/refonte/apres/menu_1280x720_normal.png`, `navigation_focus_1280x720.png`, `enquete_1280x720_normal.png`.
- Même cadrage avant/après lumière : `atelier_avant_eclairage_1280x720.png`, `atelier_apres_eclairage_1280x720.png`.
- Porte et ordinateur : `atelier_porte_ouverte_1280x720.png`, `ordinateur_repare_1280x720.png`.
- Boutique : `boutique_focus_1280x720.png`, `inventaire_apres_achat_1280x720.png` (130 points après les trois missions et l'achat).
- Compact : `menu_800x480_normal.png`, `menu_800x480_grand_opaque.png`, `enquete_800x480_grand_opaque.png` ; profils, pause, paramètres, défis et conclusion aux mêmes tailles également disponibles.

Les captures peuvent être affichées directement dans la conversation. Un chemin local n'est pas une garantie de téléchargement sur iPhone.

## Lancer et exporter

Importer `project.godot` dans l'éditeur Godot **4.6.3 standard**, puis F5, ou `godot --path .`. Sélectionner/créer un profil, choisir Commencer ; Continuer reprend sa sauvegarde. Toutes les commandes restent celles du [README](../README.md).

Nouvelle livraison portable : **`builds/Console_CIEL_Windows_x86_64_refonte_0.4.0.zip`**. Décompresser entièrement, puis lancer `Console_CIEL.exe`. Ressources intégrées, LIRE_MOI et licences fournis. Taille contrôlée et empreinte dans `tests/refonte_results/windows-package.json`. Binaire et fichiers associés dans `builds/windows-x86_64-refonte-0.4.0/`. Le fichier n'est pas signé.

Pour reproduire cette sortie sans remplacer 0.3.0/0.3.1 :

```powershell
.\tools\export_windows.ps1 -GodotPath 'C:\Outils\Godot_v4.6.3-stable_win64_console.exe' -ArchiveName Console_CIEL_Windows_x86_64_refonte_0.4.0.zip -OutputDirectory windows-x86_64-refonte-0.4.0
```

Modèles officiels Windows **4.6.3 stable** requis. L'export et le ZIP ont été produits avec PowerShell 7.4.13 sous Linux. L'intégrité CRC, le PE x86_64, les 173 entrées du pack (empreintes vérifiées) et la conservation des anciens ZIP sont vérifiés dans `tests/refonte_results/windows-package.json`.

Tests reproductibles :

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/refonte_navigation.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/investigation_tests.gd
# Affichage nécessaire ; fournir des XDG_DATA_HOME/CONFIG_HOME/CACHE_HOME isolés :
godot --audio-driver Dummy --path . --script res://tests/refonte_visual.gd
godot --audio-driver Dummy --path . --script res://tests/refonte_states.gd
```

## Limites restantes

Aucun Windows natif ni Raspberry Pi n'est disponible ici. **Double-clic, DPI Windows 100/125/150/200 %, plein écran natif, son, USB réel, écran final et performances Pi restent à vérifier.** Le rendu logiciel ne permet pas d'annoncer 60 FPS sur Pi. Le preset ARM64 est conservé mais ses modèles d'export sont absents de cet environnement. Arrêt système non configuré ; Quitter ferme uniquement l'application. Mapping du contrôleur fabriqué encore à mesurer. Aucun nouvel autostart, faux indicateur de batterie ou modification système.
