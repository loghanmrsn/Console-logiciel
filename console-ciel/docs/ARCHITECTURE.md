# Architecture native — version 0.3.0

Godot 4.6.3 stable, GDScript, rendu Compatibility. `scenes/main.tscn` lance l'interface existante ; `scripts/ui/main.gd` conserve ses écrans et compose le jeu dans leur navigation. `scenes/demo_game.tscn` et `scripts/game/demo_game.gd` restent les points d'entrée, malgré leur nom historique : ils ouvrent désormais l'enquête jouable. Les transactions nécessitent un profil actif ; lancer le projet entier avec F5 permet de le sélectionner.

## Services réutilisés

| Service | Responsabilité |
|---|---|
| SaveService | Validation et adaptation des documents, temporaires vérifiés, copies précédentes, récupération explicite |
| AppState | Document du profil actif ; signaux profil, portefeuille, équipement et objectifs |
| ProfileService | Création, sélection, édition, suppression, nouvelle partie et réinitialisation |
| InvestigationService | Prérequis, observations, indices, diagnostic réel des trois défis et transitions de mission |
| RewardService | Règles configurables et transaction cohérente d'une récompense attribuée une seule fois |
| PenaltyService | Débit de 200 points par traversée au rouge, dette persistante et remboursement dans les transactions de récompense |
| ShopService | Catalogue, achats et équipement ; règles métier avant écriture |
| SettingsService | Réglages communs, aperçu réversible, audio, accessibilité et affichage |
| SceneRouter | Navigation, mémorisation du focus et attente du relâchement des entrées |
| ControllerService | Sélection d'une manette active, filtrage des événements et état de connexion |
| PlatformService | Détection de plateforme ; arrêt système explicitement non configuré |

Depuis la version 0.13.0, le champ optionnel `penalties` du profil contient `version`, `count`, `debt`, `paid` et `last_event`. SaveService vérifie notamment `count × 200 = paid + debt`. Le dernier identifiant de traversée évite un double enregistrement immédiat. PenaltyService prépare le débit sur une copie, enregistre puis publie le profil ; son calcul de remboursement ne modifie que la transaction détachée de RewardService ou HotelService. Nouvelle partie conserve ces données économiques.

L'enquête complète l'architecture existante avec sa validation métier. Elle ne crée ni second gestionnaire de profils, ni second portefeuille, ni second répertoire de sauvegarde. L'interface transmet les choix ; le service vérifie les réponses et prérequis, puis la réussite utilise la transaction de récompense existante. Un clic d'interface ne peut pas attribuer arbitrairement une mission ou des points.

Une transaction prépare une copie du profil en mémoire. Les changements de mission, portefeuille et identifiant de récompense sont enregistrés dans le même fichier ; AppState ne publie le nouveau document qu'après réussite. Les signaux actualisent l'enquête, l'en-tête et la boutique. Une erreur d'écriture garde le dernier état cohérent et permet une nouvelle tentative.

## Progression et données

`data/game_rules.json` définit les missions, leurs descriptions, prérequis, états initiaux et récompenses ainsi que les choix pédagogiques. Les identifiants `lighting`, `lock` et `computer` sont conservés pour préserver les récompenses des profils existants.

La progression du profil contient missions terminées, observations, indices, checkpoint et gains nouveaux de cette partie. L'état visuel de la salle est dérivé des missions terminées : éclairage rétabli, porte ouverte et ordinateur réparé. Les états d'objectif sont dérivés des prérequis et de l'avancement, sans copie contradictoire de la réussite.

Le schéma du profil reste `schema_version: 1`. Les champs ajoutés à `progress` sont :

| Champ | Rôle |
|---|---|
| `investigation_version: 1` | Distingue les défis jouables des anciennes interactions simulées |
| `active_mission` | Mission commencée, sans attribution de réussite |
| `clues` | Identifiants `badge_note`, `video_note`, `incident_message` collectés |
| `observations` | Listes par mission : `lighting`, `lock`, `computer` |
| `checks` | Vérifications réalisées, notamment celles de l'ordinateur |
| `run_reward_points` | Points nouvellement attribués dans cette partie |
| `legacy_migration_notice` | Information de migration à acquitter par le joueur |

`started`, `room_id`, `checkpoint_id` et `completed_missions` restent les champs de progression existants. Les checkpoints sont `entrance`, `lighting`, `lock`, `computer` et `exit` ; les identifiants et types sont validés avant utilisation. Le chargement détecte les profils antérieurs puis adapte leur progression ; la sélection persiste cette adaptation avec copie précédente, au lieu d'écraser silencieusement un fichier lors d'une simple lecture.

La nouvelle partie remet l'enquête à son point initial, mais conserve le portefeuille, les achats, l'équipement et `rewarded_missions`. Le compteur des gains de la partie repart à zéro et n'augmente que si une récompense est nouvellement accordée. Une migration explicite adapte les anciens succès simulés tout en préservant les données économiques.

## Exploration et interface

La salle, le joueur et les objets interactifs sont séparés de l'écran de défi. Le personnage utilise le moteur de collisions Godot ; murs, mobilier et porte fermée sont des obstacles. Le choix de l'objet proche prend en compte la distance et l'orientation avec une stabilité de cible. Sur petit écran, le zoom minimal de 0,70 conserve un personnage d'environ 18 pixels : la caméra suit les portions hors cadre et reste limitée aux murs, au lieu de réduire toute la salle jusqu'à rendre le personnage trop petit.

Les modèles des meubles sont enfants de leur corps physique, ancrés au sol dans le groupe trié par profondeur avec le joueur. HotelLayout distingue l'emprise du pot des feuilles et définit les chaises séparément ; fontaine et colonnes utilisent CircleShape2D. RoadLayout centralise route, passage, arrêts des voitures, garde-corps et emprises des objets de rue. RoadTraffic gère le cycle du feu, les Area2D des voitures, le contrôle continu des contacts et l'état d'une traversée. TrafficHud présente les règles ; InvestigationWorld transmet les notifications à l'interface. Le contrôleur de circulation s'arrête avec les contrôles du monde ou SceneRouter et ne modifie les points qu'en appelant PenaltyService. [Règles et tests du passage](TRAFFIC.md).

Les dialogues, défis, pause et conclusion suspendent les contrôles d'exploration. Les actions de jeu restent distinctes des actions UI. SceneRouter attend le relâchement des touches et boutons après une transition, afin que l'appui d'ouverture n'effectue pas une deuxième action dans l'écran suivant. La fermeture restaure les contrôles et le focus appropriés.

Les défis emploient des contrôles natifs sélectionnables : connexions du circuit, observations, diagnostics et réparations. Le schéma dessiné représente les choix sélectionnés ; la vérification appartient au service. Aucune mécanique ne requiert un tracé à la souris.

Les composants partagés restent dans `scripts/ui/` : boutons, cartes, confirmations, notifications, lignes de réglages et clavier virtuel. `themes/console_theme.tres` et ThemeFactory fournissent StyleBoxFlat, états de focus et accessibilité. Les panneaux utilisent des aplats alpha, sans flou obligatoire. Décor, personnage et diagrammes sont originaux et procéduraux.

Les grilles dépendent de leur largeur disponible. Le défilement suit le focus après stabilisation des conteneurs. Les modales capturent les interactions et restaurent le focus à leur fermeture. Les réglages sont globaux sauf les cosmétiques, enregistrés par profil.

## Démarrage, transitions et erreurs

`scenes/startup.tscn` et `scripts/ui/startup_panel.gd` affichent **Console CIEL** et l'étape en cours : commandes, réglages, catalogue/règles puis profils. Le démarrage cède la main au moteur entre les étapes ; il n'impose pas de délai d'animation et ne présente pas un pourcentage fictif. Le thème et les options d'accessibilité sont appliqués avant la sélection du profil. Sans profil valide, la création est proposée.

Un échec essentiel ouvre un écran dédié. Le réessai invalide les caches de définitions et relit les fichiers livrés ; il ne réutilise pas un catalogue ancien après un chargement refusé. Les récupérations de profil, de réglages et de session demandent une action explicite et conservent les originaux dans une copie de corruption. Une copie `.bak` seule est également détectée : une écriture ne recrée pas silencieusement le document principal manquant.

Les confirmations ne peuvent pas se superposer. SceneRouter conserve le contexte et le focus, et attend le relâchement après une transition. L'enquête est conservée pendant les paramètres ouverts depuis la pause, puis revient à cette pause. Le retour au menu et la fermeture passent par la sauvegarde ; une erreur maintient la session ouverte avec réessai. L'interface n'annonce pas une réussite avant la transaction persistante.

`SaveService.last_error` et `last_error_at` conservent la dernière erreur réelle de lecture ou d'écriture, même après un essai réussi. Les erreurs de pseudo et les mauvaises réponses pédagogiques ne remplacent pas ce diagnostic. Les erreurs importantes attendent une décision explicite, tandis que les informations ordinaires utilisent une notification lisible.

## Manette active et contrôleur fabriqué

`scripts/services/controller_service.gd` complète la navigation existante. Au démarrage, la manette possédant le plus petit identifiant Godot est active. Elle reste sélectionnée tant qu'elle est connectée ; les autres manettes ne contrôlent pas l'application. Si elle est retirée, le service choisit le plus petit identifiant encore connecté, ou conserve le clavier comme seul moyen d'entrée. Rebrancher une ancienne manette ne remplace pas automatiquement celle qui est désormais active.

La perte de la manette active suspend les contrôles et met l'enquête en pause avec un message. La reconnexion ne reprend pas la partie : **Reprendre** est une action explicite. Les entrées clavier restent utilisables. Les appuis et axes précédents sont relâchés lors d'un changement pour éviter un déplacement maintenu.

`data/controller_mapping.json` contient `schema_version: 1` et un dictionnaire `actions`, avec des associations de bouton ou d'axe/direction. `scripts/input_setup.gd` traduit ces associations vers les actions de l'Input Map. Le fichier livré décrit le mapping standard Godot ; il ne prétend pas mesurer le futur contrôleur USB HID. Pour celui-ci, relever d'abord les indices bruts et sens d'axes avec le test des commandes, modifier les données puis relancer et refaire la recette.

Le test des commandes présente nom, GUID, identifiant et état actif des périphériques reçus, boutons actuellement pressés et valeurs brutes des axes. L'indication **au repos** est calculée à partir des axes de navigation et de la zone morte courante. L'absence de périphérique est affichée explicitement ; aucun faux contrôleur n'est présenté comme branché.

## Diagnostic de développement

**F3**, action `debug_diagnostics` centralisée, ouvre en exécution debug `scripts/ui/diagnostics_panel.gd`. Il présente version logiciel/Godot, résolution courante, backend d'affichage, méthode/pilote de rendu, FPS observés, identifiant interne du profil actif, état du contrôleur et dernière erreur de stockage. En headless, la méthode réellement rendue est indisponible : le panneau distingue cette absence du renderer configuré. L'outil est absent de l'interface de livraison release et ne modifie pas les données. Les métriques indisponibles de température, batterie ou mémoire ne sont pas inventées. Les FPS du moteur headless n'évaluent pas le Raspberry Pi. Les textes sont actualisés au plus quatre fois par seconde ; le test des commandes échantillonne à dix fois par seconde.

La préparation de soutenance passe par `tools/run_demo.sh` et une racine de données distincte, suivie par un manifeste. Aucune commande de crédit ou outil de triche n'apparaît dans les menus exportés. [Procédure de démonstration](DEMONSTRATION.md).

Le modèle reste local et scolaire, sans cryptographie anti-triche ni garantie contre toutes les coupures électriques. Le raccordement matériel final relève du mapping USB HID, de l'export ARM64 et des essais dans la session graphique du Raspberry Pi.

## Présentation des épreuves de l’hôtel — 0.14.0

`HotelDiagnosticPanel` compose le bandeau illustré, les cartes d’observations et les choix du diagnostic, puis émet ses signaux. HotelStoryUI conserve seulement les choix provisoires et l’indice consulté, appelle HotelService puis reconstruit la présentation depuis l’état sauvegardé. CoffeeWiringPanel conserve la sélection provisoire et dessine les fils ; la validation des paires reste dans le service. HotelLayout fournit les trois emprises supplémentaires ; InvestigationWorld leur applique le même corps physique et le même tri de profondeur qu’aux meubles existants. [Rendu et contrôles](HOTEL_VISUAL.md).

## Rencontres — 0.15.0

`NpcCatalog` regroupe les six emplacements, leurs approches libres et leurs dialogues contextuels. Il lit une copie de la progression, sans appeler les services de sauvegarde ou de récompenses. `InvestigationWorld` construit les pieds solides et le modèle `NpcVisual` sous le même parent trié que le joueur. Le modèle est dessiné une fois avec des primitives dans la palette existante, et partagé avec le portrait de la discussion.

`DemoGame` route les identifiants `npc_` avant les épreuves et refuse ceux d’un autre lieu. Le composant natif `NpcDialoguePanel` présente le nom, le rôle et les pages ; ses signaux reprennent le focus, le défilement et la fermeture des autres fenêtres. Le verrou de dialogue suspend le joueur et la circulation. La carte utilise le même catalogue pour ses repères. Aucun champ de sauvegarde, nouvelle mission ou ressource externe n’est ajouté. [Emplacements et recette](PNJ.md).

## PNJ et fluidité — 0.16.0

`NpcVisual` dessine des couches de vêtements, six coiffures et des visages plus détaillés. Le modèle est partagé avec les portraits rapprochés ; seul un bref geste d’attention utilise un tween, sans boucle d’animation permanente. Le regard est quantifié pour éviter de redessiner à chaque petit déplacement. `NpcSpeechMarker` hérite du repère spatial commun et fait apparaître le nom depuis une bulle discrète.

La portée et le score d’un PNJ sont calculés depuis ses pieds. Le rayon de visibilité exclut uniquement son propre corps, ce qui permet de parler depuis plusieurs côtés tout en gardant les murs et le mobilier opaques. Les emprises physiques, les points de reprise et les missions ne changent pas.

`NpcDialoguePanel` garde un en-tête et une rangée d’actions fixes. Seul le texte possède une zone de défilement native ; sa hauteur est mesurée depuis la plus longue page, puis limitée à la place disponible. Les pages changent sans reconstruire la fenêtre. Espace avance le texte, les boutons gardent leur navigation et une fermeture directe est disponible. Les fondus sont courts, sans bloquer la pagination, et respectent la réduction des animations. Une fermeture possède un numéro de transition : une déconnexion de manette l’annule et conserve le panneau, la page et les commandes à la reprise. [Commandes et recette](PNJ.md).

## Profil Dev — 0.17.0

`DevProfile` construit un document complet depuis les missions livrées, sans sélectionner ni écrire de profil. Les observations, indices, vérifications, récompenses et étapes de l’hôtel passent le validateur habituel. `ProfileService.use_dev_profile()` crée le compte dédié à la demande, puis emploie la sélection normale. Un compte existant, une sauvegarde précédente ou un fichier endommagé ne sont pas écrasés. Le rôle facultatif `super_admin` est limité à l’identifiant dédié et au nom Dev ; le pseudo d’un joueur ne confère pas de rôle. Les remises en place conservent les points, les achats, les images et les pénalités. [Utilisation](DEV.md).
