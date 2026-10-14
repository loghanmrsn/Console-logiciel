# Livraison courante 0.6.1 — confort visuel et tarifs

[Projet complet](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.6.1.zip) et [Windows prêt à lancer](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_confort_0.6.1.zip). Décompresser tout le ZIP Windows et ouvrir **Console_CIEL.exe**. Dans le projet complet, il se trouve sous `console-ciel/builds/windows-x86_64-confort-0.6.1/`. [Guide de l’archive](ARCHIVE_COMPLETE.md).

Le profil actif, son avatar et ses points sont en haut à gauche, y compris pendant l’enquête. La barre inférieure conserve quatre onglets centrés et ne répète plus le pseudo ni le solde. Les quatre emplacements **Test 1 à Test 4** coûtent **200 points chacun** ; les jeux déjà acquis restent possédés sans supplément.

Après une mission réussie et sauvegardée, son repère et son bouton d’interaction disparaissent. Le décor reste visible dans son état réparé ; l’ascenseur reste utilisable dans les deux chapitres. Une reprise conserve cet état et une nouvelle partie rétablit les repères des missions à refaire. **Pause → Bilan du chapitre** permet de revoir un chapitre terminé. [Parcours manuel](ENQUETE.md).

Les six missions rapportent toujours **50 points à leur première réussite**, au maximum **300 par profil**, sans nouveau gain lors d’un rejeu. Sans autre dépense, quatre premières réussites financent un jeu ; après les six missions et cet achat, il reste 100 points. Les quatre jeux coûtent 800 points au total : les autres achats attendent de futurs défis ou un solde déjà présent dans un ancien profil. Les Test restent des emplacements de préparation, sans gameplay ni récompense supplémentaires. [Bibliothèque et tarifs](BIBLIOTHEQUE_ET_THEMES.md).

## Rapports de la livraison courante

Le [rapport Windows 0.6.1](../builds/Console_CIEL_Windows_x86_64_confort_0.6.1.verification.json) et le [rapport du projet complet 0.6.1](../builds/Console_CIEL_Projet_Complet_0.6.1.verification.json) détaillent contenu et empreintes. Les recettes distinguent logique source, rendu réel sous Linux, contrats Windows et ressources embarquées exécutées avec Godot Linux. Les résultats historiques ci-dessous restent ceux de leurs versions respectives.

Recette exécutée le **14 octobre 2026**, avec données temporaires isolées :

| Périmètre | Résultat |
|---|---|
| Sources, 16 suites | **11 844 assertions, zéro échec** |
| Persistance entre trois processus Godot réels | **65 assertions, zéro échec** |
| Rendu X11 Linux, Mesa llvmpipe / Compatibility | **58 contrôles, zéro échec**, 8 captures |
| Pack réellement embarqué dans l’EXE Windows, exécuté avec Godot Linux | **6 547 assertions, zéro échec** |
| Contrats de configuration Windows | **18 contrôles, zéro échec** |
| Outils de packaging | **27 contrôles, zéro échec** |
| Ressources du pack | **203 empreintes contrôlées**, dont 43 SVG ; CRC du ZIP vérifiés |
| Audit statique du projet | **818 fichiers, 72 UID, 194 références**, zéro erreur |
| Chargement des ressources avec Godot Linux | **203 contrôles, zéro échec** |

[Résumé détaillé et empreintes des journaux](../tests/confort_0.6.1_results/summary.json). Les contrôles couvrent le profil en haut à gauche, les prix à 200 points, l’achat refusé à 199 et accepté à 200 après quatre missions réussies, les achats antérieurs, les repères des six missions, la reprise, le rejeu, l’ascenseur et le bilan en pause.

Les huit captures réelles montrent :

- [Accueil, profil à gauche et prix à 200 en 1280 × 720](screenshots/confort_0.6.1/home_profile_left_prices_200_1280x720.png).
- [Accueil en 800 × 480 avec grand texte](screenshots/confort_0.6.1/home_profile_left_800x480_large.png).
- [Accueil en 800 × 480 avec style Nuit](screenshots/confort_0.6.1/home_profile_left_800x480_nuit.png).
- [Boutique, quatre jeux à 200 points](screenshots/confort_0.6.1/shop_prices_200_1280x720.png).
- [Commande de porte avant réussite, avec repère](screenshots/confort_0.6.1/door_before_success_marker.png).
- [Commande de porte après réussite, sans repère ni bouton d’interaction](screenshots/confort_0.6.1/door_after_success_no_marker.png).
- [Chapitre terminé, sans repères de missions](screenshots/confort_0.6.1/chapter_completed_no_mission_marker.png).
- [Ascenseur toujours disponible après les missions](screenshots/confort_0.6.1/elevator_available_after_missions.png).

Le rendu Linux utilise le pilote audio Dummy et ne valide pas le son perçu. Le pilote graphique ne prend pas en charge le changement de VSync. La fermeture verbose signale un unique StringName `process_frame` non libéré, sans fuite d’instance ObjectDB. Les contrôles de manette utilisent des périphériques virtuels ; la corruption ConfigFile est provoquée uniquement dans des données de test.

Le [guide Windows](WINDOWS.md) décrit les contrôles manuels : profil en haut à gauche, quatre prix à 200, refus sous 200 points, achats antérieurs conservés, repères masqués après réussite et relance, repères rétablis en nouvelle partie, absence de récompense répétée, bilan en pause et ascenseur dans les deux sens. Le lancement natif, le son et une manette USB physique sous Windows restent à essayer sur le PC destinataire. Le contrôleur de la console et les performances Pi restent à mesurer sur le matériel réel.

# Historique — livraison 0.6.0 : enquête, chapitre 2

[Projet complet](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.6.0.zip) et [Windows prêt à lancer](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.zip). Décompresser tout le ZIP Windows et ouvrir **Console_CIEL.exe**. Dans le projet complet, il se trouve sous `console-ciel/builds/windows-x86_64-chapitre-2-0.6.0/`. [Guide de l’archive](ARCHIVE_COMPLETE.md).

Le chapitre 1 est conservé. Après ses trois missions, l’ascenseur en bas du bureau conduit à la salle réseau : liaison RJ45, adressage IPv4 et protection Wi-Fi. Le tableau de missions compact à droite s’ouvre et se ferme par son bouton, **T** ou le **bouton de face haut**. Chaque chapitre possède son bilan ; les nouveaux gains de la partie restent cumulés entre les étages. [Explications et parcours manuel](ENQUETE.md).

Les six premières réussites rapportent **50 points chacune**, au maximum **300 par profil**. Rejouer conserve les identifiants de récompense et ne rapporte pas ces points une seconde fois. Les anciens profils reçoivent les missions du chapitre 2 sans perdre réussites, observations, portefeuille, achats ni équipement. La progression de salle et de chapitre est persistée. Toutes les manipulations restent fictives et hors ligne ; aucun réglage réseau réel n’est changé.

La bibliothèque, les emplacements **Test 1 à Test 4**, les styles/couleurs, les crédits, les images locales et le clavier de la version 0.5.0 restent disponibles. Les Test sont toujours des emplacements provisoires, et leur ouverture ne rapporte aucun point. Les anciennes livraisons sont conservées dans le dépôt.

## Vérifications de la livraison historique 0.6.0

Le [rapport Windows](../builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.verification.json) et le [rapport du projet complet](../builds/Console_CIEL_Projet_Complet_0.6.0.verification.json) décrivent les empreintes et le contenu des deux archives. La recette distingue tests de logique avec données isolées, affichage réel sous Linux, configuration Windows et exécution du pack compilé avec Godot Linux.

Recette exécutée le **14 octobre 2026**, avec données temporaires isolées :

| Périmètre | Résultat |
|---|---|
| Sources, 14 suites | **9 568 assertions, zéro échec** |
| Persistance entre trois processus Godot réels | **65 assertions, zéro échec** |
| Rendu X11 Linux, Mesa llvmpipe / Compatibility | **694 contrôles, zéro échec**, 12 captures |
| Pack réellement embarqué dans l’EXE Windows, exécuté avec Godot Linux | **4 351 assertions, zéro échec** |
| Contrats de configuration Windows | **18 contrôles, zéro échec** |
| Outils de packaging | **27 contrôles, zéro échec** |
| Ressources du pack | **203 empreintes contrôlées**, dont 43 SVG ; CRC du ZIP vérifiés |
| Audit statique du projet | **797 fichiers, 70 UID, 191 références**, zéro erreur |
| Chargement des ressources avec Godot Linux | **199 contrôles, zéro échec** |

[Résumé détaillé et empreintes des journaux](../tests/chapitre_2_0.6.0_results/summary.json). Les captures montrent l’[ascenseur déverrouillé](screenshots/chapitre_2_0.6.0/chapter_1_elevator_unlocked.png), l’[arrivée à l’étage](screenshots/chapitre_2_0.6.0/chapter_2_arrival_missions.png), les trois défis et le panneau ouvert ou replié à 1280 × 720, 1024 × 600 et 800 × 480, en texte normal ou grand. [Les 12 captures](screenshots/chapitre_2_0.6.0/).

L’affichage Linux utilise un rendu logiciel et un pilote audio Dummy ; ces essais ne valident pas le son perçu. Le pilote signale que le réglage VSync n’est pas pris en charge. Les tests de manette emploient des événements et périphériques virtuels. La suite générale provoque volontairement la corruption de son propre fichier de paramètres pour vérifier la récupération.

Ces contrôles ne remplacent pas le lancement natif, le son ou une manette USB physique sur Windows. Le contrôleur de la console reste à mesurer sur le matériel réel ; les tests virtuels ne prouvent pas son mapping. Les limites Raspberry Pi et d’alimentation sont conservées dans [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

# Historique — livraison 0.3.0 intégrée

Les noms d’archives et résultats ci-dessous décrivent la livraison historique reçue. Les anciens exécutables 0.3.0/0.3.1 n’étaient pas inclus dans les sources fournies. La phrase « Tests visuels exécutés : aucun » dans cet historique concerne cette recette ancienne ; elle ne décrit pas les captures des versions ultérieures.

Projet natif Godot **4.6.3.stable.official.7d41c59c4**, édition standard, GDScript, rendu **Compatibility**. Cette version stabilise le menu et l'enquête existants ; elle n'ajoute pas de nouvelle enquête et conserve les profils, le portefeuille, les cosmétiques et le format d'enquête 0.2.0.

## Corrections et compléments

- Démarrage par étapes réelles : réglages, catalogue et règles, profils, thème et accessibilité ; création proposée sans profil. Les erreurs essentielles offrent un réessai qui relit les données livrées.
- Récupération explicite des profils, réglages et session, y compris lorsqu'il ne reste qu'une copie précédente. Les documents défectueux sont conservés et ne sont pas écrasés silencieusement.
- Transitions, focus et confirmations protégés contre la validation traversant plusieurs écrans et les dialogues superposés. Les paramètres ouverts depuis la pause reviennent à cette pause.
- Manette active unique, mapping configurable, pause à sa déconnexion et reprise explicite. Le clavier reste disponible ; le test des commandes présente noms, GUID, boutons, axes, zone morte et état de repos réellement reçus.
- Fermeture avec brouillon de réglages et erreur de sauvegarde traitée explicitement. Les transactions conservent le dernier état cohérent et les erreurs importantes restent visibles jusqu'à une action.
- Diagnostic debug F3 : versions, résolution, renderer, FPS observés, profil interne, contrôleur et dernière erreur de stockage. Aucun état fictif de batterie, température ou réseau.
- Outil de démonstration réservé au développement : données isolées, profil identifié par manifeste, remise à zéro ciblée et préremplissage facultatif utilisant la validation métier.
- Guides de soutenance et d'installation Pi avec conservation des données, copie de versions et retour arrière. Aucun deuxième autostart ni arrêt système inventé.

Le parcours est conservé : sélection du profil → menu → enquête et trois défis → sauvegarde → menu → boutique/inventaire → équipement → fermeture → relance. Les missions sont de vraies activités jouables dans une simulation pédagogique fictive. Réussite, points et récompense sont enregistrés ensemble ; un rejeu ne donne pas une seconde récompense.

## Vérifications exécutées et preuves

Les résultats de recette intégrée sont dans [TESTS.md](TESTS.md), [UI_TESTS.md](UI_TESTS.md) et [tests/release_results/summary.json](../tests/release_results/summary.json). Exécution réelle le **11 octobre 2026 à 15:58 UTC** : **2 500 assertions, zéro échec**, huit jobs complets et sorties 0. Les fermetures réelles ajoutent **105 assertions, zéro échec**, et la préparation démo **36 vérifications, zéro échec**. Godot est lancé en mode **headless**, avec des données temporaires isolées. Les événements clavier/manette et la physique du moteur sont réellement utilisés ; les périphériques déclarés pour la connexion sont explicitement virtuels.

| Vérification | Résultat ou portée | Preuve |
|---|---|---|
| Services, profils, boutique, réglages et récupération | 190 assertions, zéro échec | [business.log](../tests/release_results/business.log) |
| Trois défis, progression, migration et transactions | 189 assertions, zéro échec | [investigation.log](../tests/release_results/investigation.log) |
| Persistance après deux fermetures/relances | 65 assertions, zéro échec, dans trois processus Godot indépendants | `tests/release_results/persistence_*.log` |
| Politique de manette active et action F3 | 22 assertions, zéro échec sur périphériques virtuels de test | [controllers.log](../tests/release_results/controllers.log) |
| Interface, collisions, focus et géométrie | 1 937 assertions, zéro échec | [native_ui.log](../tests/release_results/native_ui.log) |
| Démarrage, réessais et récupération | 97 assertions, zéro échec | [stability.log](../tests/release_results/stability.log) |
| Quatre fermetures avec brouillon et erreurs d'écriture | 105 assertions, zéro échec ; lecture des documents après sortie | [close_summary.json](../tests/stability_results/close_summary.json) |
| Préparation et remise à zéro de démonstration | 36 vérifications, zéro échec ; second profil conservé | [demo-preparation-results.log](../tests/demo-preparation-results.log) |
| Pack de ressources ARM64 0.3.0 | CRC contrôlés ; démarrage headless 30 frames sans erreur | `tests/pack-launch-results.log` |
| Export autonome ARM64 0.3.0 | Échec explicite, sortie 1 : modèles `linux_debug.arm64` et `linux_release.arm64` absents | `tests/arm64-export-results.log` |

Les résultats précédents **0.2.0** — 190 services, 189 enquête et 1743 interface — restent historiques. Ils ne servent pas seuls à prouver les nouveaux comportements de connexion et de fermeture. La corruption volontaire d'un ConfigFile temporaire peut produire son message de parse attendu ; elle est suivie du contrôle de récupération. Une sortie 0 sans lecture du journal ne suffit pas.

Une relance rapide de l'interface a également réussi **309 assertions, zéro échec** dans [stability-ui-quick-results.log](../tests/stability-ui-quick-results.log). Elle recoupe les scénarios complets et n'est pas ajoutée au total de référence.

**Tests visuels exécutés : aucun.** Aucun affichage graphique utilisable n'est disponible ici et aucune capture censée prouver un rendu n'est fabriquée. La géométrie des contrôles à 1280 × 720, 1024 × 600 et 800 × 480, en texte normal/grand et transparence réduite, est testable en headless ; elle ne remplace pas l'inspection du contraste et de la lisibilité à l'écran.

**Tests manuels restants sur PC :** parcours complet sans souris avec affichage, qualité visuelle, sons perçus, plein écran et déconnexion/reconnexion USB physique. **Tests matériels restants sur Pi :** binaire ARM64, labwc, écran final, contrôleur fabriqué, mapping, son, performances et comportement de l'alimentation. Aucune température ni performance Pi n'est annoncée comme mesurée par ce projet.

## Lancer et présenter

```sh
godot --headless --path . --import
godot --path .
# Profil de soutenance et données séparées, conservés à la relance :
./tools/run_demo.sh
```

Sélectionner un profil puis **Commencer / Nouvelle partie**, ou **Continuer**. Flèches/ZQSD pour marcher, Espace pour interagir, flèches/Entrée pour les défis, Échap pour revenir et P pour la pause. [README](../README.md), [parcours de soutenance](DEMONSTRATION.md) et [explications pédagogiques](ENQUETE.md).

L'archive source `console-ciel-source.zip` (ancien nom d’archive) se régénère avec `python3 tools/package_source.py`, sans caches ni profils personnels. L’archive a également été extraite dans un dossier temporaire neuf : import avec Godot puis lancement 30 frames réussis, sans erreur de script ; journaux `tests/source-import-results.log` et `tests/source-launch-results.log`. Le pack `console-ciel-arm64.zip` (ancien nom d’archive) **0.3.0** inclut contrôleur, mapping JSON, démarrage, diagnostic et ressources de l'enquête ; outils, tests et docs de développement en sont exclus. Il a été chargé par le moteur Godot installé, mais **ce n'est pas un exécutable autonome ARM64**.

L'export du pack retourne 0. Son journal d'éditeur comporte des refus de socket TCP liés au sandbox de cet environnement ; le lancement de ce pack est propre. L'export du binaire autonome retourne 1 pour absence des modèles 4.6.3. Ces résultats ne sont ni un lancement Raspberry Pi ni un contrôle du rendu graphique.

## Fichiers intégrés

| Fichiers | Changement de cette version |
|---|---|
| `project.godot`, `export_presets.cfg` | Version logiciel, service contrôleur et export ARM64 conservé |
| `scenes/startup.tscn`, `scripts/ui/startup_panel.gd` | Chargement par étapes réelles sans durée artificielle |
| `scripts/ui/main.gd`, `confirmation_dialog.gd` | Démarrage, transitions, erreurs, fermeture et diagnostic |
| `scripts/services/controller_service.gd`, `scripts/input_setup.gd`, `data/controller_mapping.json` | Manette active et associations d'actions configurables |
| `scripts/ui/joy_navigation.gd`, `input_monitor.gd` | Filtrage et diagnostic des entrées |
| `scripts/ui/diagnostics_panel.gd` | Diagnostic de développement avec valeurs disponibles réelles |
| `scripts/game/demo_game.gd` | Pause lors d'une perte de manette, préservation de la session et reprises |
| `scripts/services/save_service.gd`, `profile_service.gd`, `settings_service.gd`, `shop_service.gd`, `reward_service.gd` | Récupération, réessai et suivi de dernière erreur réelle |
| `tests/stability_tests.gd`, `controller_tests.gd`, `process_persistence.gd`, `ui_smoke.gd` | Recette de stabilité, navigation et relances indépendantes |
| `tests/close_persistence.gd`, `tools/check_close.py` | Quatre fermetures réelles et vérification externe des documents |
| `tools/run_acceptance.py`, `run_demo.sh`, `prepare_demo.gd`, `check_demo.py` | Recette groupée et préparation de démonstration isolée |
| `README.md`, `docs/` | Lancement, soutenance, installation Pi, limites et résultats |

Le thème, les données pédagogiques, les trois missions et les ressources locales originales sont réutilisés. Les crédits/licences restent sous `assets/` ; le nom du binôme est encore à compléter.

## Ce qui reste bloquant avant une démonstration sur Pi

Les modèles d'export **Linux ARM64 4.6.3 stable** restent absents : les presets sont configurés, mais aucun binaire ARM64 autonome n'est livré ou testé ici. Installer ces modèles, exporter puis jouer sur le Pi est nécessaire. Le pack de ressources chargeable par Godot ne remplace pas cette étape.

La source peut être présentée sur PC avec Godot après répétition visuelle et manette. Pour la soutenance sur Pi, vérifier le rendu réel, la lisibilité, le plein écran labwc, le son et le contrôleur. [Liste de recette matérielle et problèmes connus](KNOWN_ISSUES.md).

**Quitter** ferme seulement l'application après sauvegarde. **Arrêt système non configuré** reste indisponible dans PlatformService. Le lanceur automatique distinct doit lancer `current/console-ciel.arm64 --fullscreen` dans la session utilisateur ; ses fichiers ne sont pas présents dans ce dépôt. L'arrêt de Raspberry Pi OS et la coupure électrique restent distincts et ne sont pas prétendus fonctionnels dans l'application.

## Complément Windows — 12 octobre 2026

La version portable Windows x86_64 (`Console_CIEL_Windows_x86_64.zip`, nom historique ; utiliser la livraison 0.6.1) a été réellement exportée avec Godot officiel 4.6.3 et ses modèles Windows correspondants. Décompresser puis lancer **Console_CIEL.exe** sans installer Godot. Le [guide Windows](WINDOWS.md) indique les commandes, données utilisateur, script PowerShell de réexport et résultats détaillés.

Le preset Windows, le nom de l'exécutable, la fenêtre initiale redimensionnable et l'affichage du chemin utilisateur dans À propos ont été complétés. La fermeture par la croix réutilise la confirmation et la sauvegarde existantes. Les fichiers associés, aide et licences sont inclus ; aucune sauvegarde personnelle n'est distribuée. Le script PowerShell conserve la livraison précédente si l'export échoue ; le remplacement d'un ZIP existant a été corrigé et testé.

La nouvelle recette source passe **3 694 assertions**, les fermetures **105**, le pack réellement embarqué **47**, les contrats Windows **16** et l'exporteur PowerShell **22**, tous sans échec. L'exécutable PE x86_64 non signé et les **95 fichiers intégrés** ont été contrôlés, ainsi que les CRC de l'archive. Les tests de logique et du pack sont exécutés avec le moteur Linux headless ; **aucun lancement Windows ni rendu visuel n'est annoncé comme testé**. Essayer le parcours de recette Windows sur le PC destinataire avant la démonstration.
