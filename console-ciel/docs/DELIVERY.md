# Livraison 0.3.0 — console CIEL intégrée

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

L'archive source [console-ciel-source.zip](../builds/console-ciel-source.zip) se régénère avec `python3 tools/package_source.py`, sans caches ni profils personnels. L’archive a également été extraite dans un dossier temporaire neuf : import avec Godot puis lancement 30 frames réussis, sans erreur de script ; journaux `tests/source-import-results.log` et `tests/source-launch-results.log`. Le pack [console-ciel-arm64.zip](../builds/packs/console-ciel-arm64.zip) **0.3.0** inclut contrôleur, mapping JSON, démarrage, diagnostic et ressources de l'enquête ; outils, tests et docs de développement en sont exclus. Il a été chargé par le moteur Godot installé, mais **ce n'est pas un exécutable autonome ARM64**.

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

La [version portable Windows x86_64](../builds/Console_CIEL_Windows_x86_64.zip) a été réellement exportée avec Godot officiel 4.6.3 et ses modèles Windows correspondants. Décompresser puis lancer **Console_CIEL.exe** sans installer Godot. Le [guide Windows](WINDOWS.md) indique les commandes, données utilisateur, script PowerShell de réexport et résultats détaillés.

Le preset Windows, le nom de l'exécutable, la fenêtre initiale redimensionnable et l'affichage du chemin utilisateur dans À propos ont été complétés. La fermeture par la croix réutilise la confirmation et la sauvegarde existantes. Les fichiers associés, aide et licences sont inclus ; aucune sauvegarde personnelle n'est distribuée. Le script PowerShell conserve la livraison précédente si l'export échoue ; le remplacement d'un ZIP existant a été corrigé et testé.

La nouvelle recette source passe **3 694 assertions**, les fermetures **105**, le pack réellement embarqué **47**, les contrats Windows **16** et l'exporteur PowerShell **22**, tous sans échec. L'exécutable PE x86_64 non signé et les **95 fichiers intégrés** ont été contrôlés, ainsi que les CRC de l'archive. Les tests de logique et du pack sont exécutés avec le moteur Linux headless ; **aucun lancement Windows ni rendu visuel n'est annoncé comme testé**. Essayer le parcours de recette Windows sur le PC destinataire avant la démonstration.
