# Console CIEL — version intégrée de démonstration

## Jouer sur Raspberry Pi 4, système 64 bits

**[Télécharger Console CIEL 0.6.1 pour Raspberry Pi ARM64](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Raspberry_Pi_ARM64_0.6.1.zip)**. Sur **Raspberry Pi OS 64 bits avec bureau**, extraire tout le ZIP, ouvrir un terminal dans le dossier extrait, puis :

```sh
bash ./Lancer_Console_CIEL.sh
# Pour le plein écran :
bash ./Lancer_Console_CIEL.sh --fullscreen
```

Le logiciel est **console-ciel.arm64**, avec ses ressources intégrées ; Godot n’a pas besoin d’être installé pour jouer. `uname -m` doit indiquer **aarch64**. Bookworm ou Trixie à jour sont recommandés. Le lanceur utilise le rendu **Compatibility / OpenGL ES 3** et la session graphique de l’utilisateur. Un raccourci facultatif s’ajoute avec `bash ./Installer_raccourci.sh`.

**[Projet complet Raspberry Pi avec les sources](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.6.1.zip)** : après extraction, lancer depuis `console-ciel/builds/linux-arm64-raspberry-pi-0.6.1/`. Déposer vos photos dans **images_profil/** à côté de `console-ciel.arm64`. Les profils restent généralement dans `~/.local/share/console-ciel/`, séparés de l’exécutable.

Le jeu conserve les deux chapitres et les ajustements Windows 0.6.1 : profil en haut à gauche, jeux Test à 200 points et repères masqués après réussite. [Installation et données Raspberry Pi](console-ciel/docs/RASPBERRY_PI.md), [notice Linux](console-ciel/builds/README_LINUX.md) et [rapports de livraison](console-ciel/docs/DELIVERY.md). Le lancement natif, les pilotes, le son et la manette réelle restent à essayer sur votre Pi 4 ; aucun FPS matériel n’est annoncé comme mesuré dans le cloud.

**Confort visuel et tarifs — 0.6.1 :** le profil actif, son avatar et ses points sont en haut à gauche, avec quatre onglets centrés dans la barre du bas. **Test 1 à Test 4 coûtent désormais 200 points chacun** ; les anciens achats sont conservés sans supplément. Après une mission réussie et sauvegardée, son repère et son bouton d’interaction disparaissent ; les meubles réparés et l’ascenseur restent visibles. Un chapitre terminé peut être revu par **Pause → Bilan du chapitre**. [Parcours de l’enquête](console-ciel/docs/ENQUETE.md) et [bibliothèque et tarifs](console-ciel/docs/BIBLIOTHEQUE_ET_THEMES.md).

**Enquête, chapitre 2 — 0.6.0 :** après les trois épreuves du local technique, l’ascenseur situé en bas du bureau donne accès à la salle réseau à l’étage. Trois nouvelles missions portent sur la liaison RJ45, l’adressage IPv4 et la protection Wi-Fi. Le tableau de missions compact à droite se déplie ou se replie avec **T** ou le **bouton de face haut** de la manette. [Parcours des deux chapitres](console-ciel/docs/ENQUETE.md).

**Bibliothèque et apparence 0.5.0 :** accueil avec enquête à gauche et quatre jeux à droite, ou couvertures égales avec défilement horizontal. La boutique a introduit **Test 1 à Test 4**, emplacements provisoires initialement à **20, 30, 40 et 50 points** ; en 0.6.1, ils coûtent **200 points chacun**. Les vrais jeux sont encore en préparation. Le profil affiche ses jeux acquis. **Paramètres → Apparence** ajoute six styles gratuits et des couleurs indépendantes pour le fond et les boutons ; **Crédits** termine les catégories. [Guide des nouveautés](console-ciel/docs/BIBLIOTHEQUE_ET_THEMES.md).

## Jouer sur Windows sans installer Godot

**[Télécharger la version Windows 0.6.1](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_confort_0.6.1.zip)**.

1. Décompresser tout ce ZIP avec **Extraire tout**.
2. Ouvrir le dossier extrait.
3. Double-cliquer sur **Console_CIEL.exe**, situé directement dans ce dossier.

Si vous avez téléchargé tout le dépôt avec **Code → Download ZIP**, ouvrez d'abord `console-ciel/builds/Console_CIEL_Windows_x86_64_confort_0.6.1.zip`, puis extrayez également ce ZIP Windows. Le véritable EXE est dans ce paquet ; sa taille dépasse la limite GitHub de 100 Mio pour un fichier Git ordinaire.

Les rapports de la livraison détaillent les contrôles du paquet exporté. Les essais Godot sous Linux ne remplacent pas le lancement du binaire Windows, à essayer sur votre PC. [Notice Windows](console-ciel/builds/README_WINDOWS.md) et [rapport de vérification](console-ciel/builds/Console_CIEL_Windows_x86_64_confort_0.6.1.verification.json).

**Navigation 0.4.1 :** introduction de la barre inférieure translucide avec **Accueil → Boutique → Paramètres → Profil**. Depuis 0.6.1, avatar, pseudo et points sont en haut à gauche ; la barre conserve ses quatre onglets centrés. Les crédits figurent dans la dernière catégorie **Paramètres → Crédits** ; l’aide reste dans **À propos**. [Captures réelles et détails](console-ciel/docs/NAVIGATION_TRANSLUCIDE.md). La [version Windows 0.4.0](console-ciel/builds/Console_CIEL_Windows_x86_64_refonte_0.4.0.zip) est conservée.

**Profils 0.4.2 :** nouvel aperçu du profil, photos locales et clavier AZERTY avec minuscules, **⇧**, **123** et **ABC**. Déposez vos photos dans **images_profil/** à côté de `Console_CIEL.exe` sur Windows ou de `console-ciel.arm64` sur le Pi, puis ouvrez **Profil → Modifier → Mes images → Actualiser les images**. [Guide des profils](console-ciel/docs/PROFILS_ET_CLAVIER.md).

**[Télécharger le projet complet 0.6.1](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.6.1.zip)** : sources et version Windows réunies. Après extraction, le logiciel est dans `console-ciel/builds/windows-x86_64-confort-0.6.1/Console_CIEL.exe`. [Contenu du dossier complet](console-ciel/docs/ARCHIVE_COMPLETE.md).

Les sources, la documentation et les outils sont dans `console-ciel/`. Exécuter les commandes de développement ci-dessous depuis ce dossier.

Application native hors ligne **Godot 4.6.3 stable**, GDScript, rendu **Compatibility**, version logiciel **0.6.1**. Le projet réunit profils locaux, menu, paramètres, enquête pédagogique jouable, boutique et inventaire. Aucun compte, serveur ou paiement réel.

Refonte graphique **0.4.0** : [changements, captures avant/après et recette](console-ciel/docs/REFONTE_GRAPHIQUE.md). Navigation inférieure, grand accueil, atelier illustré, personnage animé et objectifs compacts. Captures réelles dans `docs/screenshots/refonte/`. Les sources et rapports historiques reçus sont conservés ; les anciens exécutables Windows 0.3.0 et 0.3.1 n'étaient pas inclus dans l'archive de sources fournie.

Versions Windows conservées : [0.6.0 — chapitre 2](console-ciel/builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.zip), [0.5.0 — bibliothèque et thèmes](console-ciel/builds/Console_CIEL_Windows_x86_64_bibliotheque_0.5.0.zip), [0.4.2 — profils et clavier](console-ciel/builds/Console_CIEL_Windows_x86_64_profils_0.4.2.zip), [0.4.1 — navigation](console-ciel/builds/Console_CIEL_Windows_x86_64_navigation_0.4.1.zip), [0.4.0 — refonte](console-ciel/builds/Console_CIEL_Windows_x86_64_refonte_0.4.0.zip).

## Lancer la version

**Test sur Windows x86_64 :** décompresser tout [Console_CIEL_Windows_x86_64_confort_0.6.1.zip](console-ciel/builds/Console_CIEL_Windows_x86_64_confort_0.6.1.zip), puis double-cliquer sur **Console_CIEL.exe**. Godot n'a pas besoin d'être installé sur le PC destinataire. Le ZIP contient le `LIRE_MOI.txt` français et les licences ; les ressources sont intégrées à l'exécutable. [Guide Windows, export et vérifications](console-ciel/docs/WINDOWS.md).

Version exacte du moteur utilisée : `4.6.3.stable.official.7d41c59c4`, édition standard. Importer `console-ciel/project.godot` dans cet éditeur et appuyer sur **F5**, ou lancer depuis le dossier `console-ciel` :

```sh
godot --headless --path . --import
godot --path .
# Interface attendue par le lanceur de la console :
godot --path . --fullscreen
```

Le démarrage affiche les étapes de chargement réelles, charge les réglages et les données, applique l'accessibilité puis ouvre la sélection du profil. Sans profil, il propose la création et un clavier virtuel utilisable sans clavier physique. Une erreur essentielle ouvre une page avec réessai ou récupération disponible ; aucune donnée défectueuse n'est effacée automatiquement.

Sélectionner un profil puis **Commencer / Nouvelle partie**. La barre du bas donne accès à Accueil, Boutique, Paramètres et Profil ; l’aide reste dans Paramètres → À propos ; les crédits sont dans la dernière catégorie Paramètres → Crédits. Haut/bas depuis les onglets rejoignent le contenu ; gauche/droite parcourent la barre. Elle est masquée pendant l’enquête. **Paramètres → Quitter l’application** ferme le logiciel. **Continuer** reprend sa progression enregistrée. Le chapitre 1 comprend le circuit d’éclairage, la liaison de commande de la serrure et le diagnostic vidéo. Une fois les trois missions terminées, rejoindre l’ascenseur en bas du bureau et interagir pour monter au chapitre 2 : liaison RJ45, adressage IPv4, puis protection Wi-Fi. Les bilans sont séparés par chapitre ; Continuer restaure aussi l’étage atteint. Voir [les notions et le parcours de l'enquête](console-ciel/docs/ENQUETE.md).

Les manipulations sont des **simulations pédagogiques fictives**, avec observations, choix corrects, erreurs possibles et explications. Le circuit utilise une très basse tension virtuelle ; il ne constitue pas un tutoriel de câblage secteur. Aucun équipement, terminal ou réglage du système hôte n'est modifié.

## Parcours de démonstration

[Le guide de soutenance](console-ciel/docs/DEMONSTRATION.md) décrit les huit étapes : profil → menu → réglage → enquête → mission → sauvegarde et points → achat et équipement → fermeture et relance. Il indique les réponses attendues pour le présentateur et la préparation d'un environnement de démonstration isolé.

Chaque mission réussie pour la première fois rapporte **50 points**, au maximum **300 par profil** sur les six missions. Les points sont utilisables immédiatement en boutique : chaque emplacement Test coûte **200 points**, soit **800 pour les quatre**. Sans autre dépense, quatre premières réussites financent un jeu ; les six missions donnent 300 points, donc 100 restent après cet achat. Le plafond reste de 300 points : les autres jeux attendent de futurs défis ou un solde déjà présent dans un ancien profil. Les jeux acquis avant le changement de prix restent achetés sans supplément. Leur ouverture affiche un jeu en préparation et ne rapporte aucun point. Un solde nul ou insuffisant interdit un achat payant ; un article possédé ne peut pas être facturé deux fois. Les achats appartiennent au profil actif. Chaque bilan distingue les gains nouveaux cumulés dans cette partie et le solde total ; le passage à l’étage ne remet pas ces gains à zéro. Nouvelle partie et réinitialisation conservent achats, équipement, solde et identifiants des récompenses déjà attribuées. Supprimer un profil efface l'ensemble de ses données après confirmation.

## Commandes

L'Input Map est centralisée dans `scripts/input_setup.gd`. La souris est facultative.

| Action | Clavier | Manette : mapping Godot standard |
|---|---|---|
| Naviguer dans menus et défis | Flèches | Croix / joystick gauche |
| Valider | Entrée ou Entrée numérique | Bouton de face bas |
| Retour / fermer un dialogue | Échap | Bouton de face droit |
| Déplacer le personnage | Flèches ou ZQSD | Croix / joystick gauche |
| Interagir avec l'objet proche | Espace | Bouton de face bas |
| Afficher / masquer le tableau de missions | T | Bouton de face haut (Triangle / Y / X selon la manette) |
| Pause | P | Start / Menu |
| Catégorie précédente / suivante | Q / E, hors saisie de texte | Épaules gauche / droite |
| Focus suivant / précédent | Tab / Maj+Tab | Navigation directionnelle |
| Diagnostic de développement | F3, en exécution debug | Pas de raccourci imposé |

Dans les défis, sélectionner connexions, observations et réponses puis valider ; aucun glisser-déposer. Sur un slider, gauche/droite modifie la valeur et haut/bas change de ligne. Le personnage s'arrête pendant dialogues, défis, pause et paramètres. Revenir des paramètres ouverts en pause ramène à la pause ; il faut choisir **Reprendre**.

La manette active possède le plus petit identifiant Godot au démarrage, puis reste sélectionnée tant qu'elle est branchée. Son retrait met l'enquête en pause. Le clavier reste disponible ; la reconnexion ne reprend pas automatiquement les déplacements. Si plusieurs périphériques sont présents, consulter [les règles de contrôleur et le diagnostic](console-ciel/docs/ARCHITECTURE.md).

**Paramètres → Commandes → Test des commandes** affiche les noms, boutons et axes réellement reçus, la zone morte et l'état de repos du joystick. Le mapping USB HID du contrôleur fabriqué doit être mesuré sur le vrai matériel. Les numéros de boutons Godot ne prouvent pas la correspondance d'un périphérique futur.

Le **tableau de missions**, à droite de l’écran de jeu, reste compact lorsqu’il est replié. Son bouton **Afficher / Masquer**, **T**, le **bouton de face haut**, ou **Pause → Afficher les objectifs** permettent de déplier ou replier la liste du chapitre courant. Les états et les coches se mettent à jour après chaque sauvegarde réussie. Le bouton d’interaction reste compact et affiche le nom de l’objet ciblé. Une mission réussie et sauvegardée perd son repère et son bouton d’interaction ; son décor réparé reste visible. L’ascenseur conserve son interaction et **Pause → Bilan du chapitre** permet de revoir le bilan du chapitre courant terminé.

Les réglages comprennent volumes réels sur bus distincts, plein écran, disposition de la bibliothèque, texte agrandi, animations réduites, transparence réduite et zone morte. Apparence propose **Thème du profil, Brume, Sable, Sauge, Nuit et Aurore**, avec couleur du fond et couleur des boutons indépendantes, y compris un choix RGB personnalisé. Les styles gratuits ne dépensent aucun point ; les thèmes cosmétiques du profil restent en boutique. **Annuler** restaure les aperçus ; **Appliquer** persiste les valeurs. Le focus possède une bordure et les états disposent de textes explicites.

## Sauvegardes et récupération

`user://` désigne le dossier personnalisé `console-ciel` : généralement `~/.local/share/console-ciel/` sous Linux, `%APPDATA%\console-ciel\` sous Windows et `~/Library/Application Support/console-ciel/` sous macOS. Sous Linux, Godot respecte `XDG_DATA_HOME`. **Paramètres → À propos** affiche le chemin effectif donné par Godot et celui des journaux (`logs/godot.log`). Les données ne sont pas écrites à côté de l'exécutable.

| Document | Contenu |
|---|---|
| `profiles/<id>.json` | Identité, progression, observations, indices, checkpoint, gains de la partie, portefeuille, inventaire, équipement et récompenses déjà attribuées |
| `settings.cfg` | Réglages globaux via ConfigFile |
| `session.json` | Dernier profil sélectionné |
| `.tmp`, `.bak`, copies de récupération | Écriture vérifiée dans le même dossier et version précédente exploitable |

Le pseudo ne construit aucun chemin. Les missions, points et identifiants de récompense sont enregistrés ensemble dans le profil ; un achat enregistre également débit et inventaire ensemble. L'état mémoire change après sauvegarde réussie. Un échec ne produit pas de gain ou débit partiel et laisse une possibilité de réessai. Une erreur importante attend une action explicite.

Les profils créés avant 0.6.0 reçoivent les trois objectifs du chapitre 2 sans perdre leur chapitre 1, leurs observations, leurs points ou leurs achats. Un chapitre 1 déjà terminé donne accès à l’ascenseur à la reprise. Le schéma de sauvegarde reste en version 1. Les profils plus anciens du prototype sont adaptés par une migration signalée : les anciennes réussites simulées sont remises au début des vrais défis, tandis que points, achats et récompenses restent conservés. Les documents ont une version de schéma ; les versions inconnues ouvrent la récupération au lieu d'être supprimées. [Décisions et migration](console-ciel/docs/ASSUMPTIONS.md).

Cette stratégie réduit les incohérences ; elle ne garantit pas la survie à toute coupure électrique. Fermer normalement l'application, puis arrêter le système avant de couper l'alimentation du montage.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `project.godot`, `scenes/main.tscn`, `scripts/ui/main.gd` | Configuration, chargement initial, menu et transitions |
| `scenes/startup.tscn`, `scripts/ui/startup_panel.gd` | Nom du projet et étapes de chargement réelles |
| `scripts/services/` | Sauvegarde, profils, paramètres, boutique, récompenses, enquête, contrôleur, navigation et plateforme |
| `scenes/demo_game.tscn`, `scripts/game/demo_game.gd` | Enquête intégrée ; nom historique conservé |
| `scenes/investigation_world.tscn`, `scripts/game/` | Salle, personnage, collisions, objets interactifs et défis |
| `data/game_rules.json` | Six missions réparties en deux chapitres, prérequis, indices, réponses et récompenses configurables |
| `data/shop_catalog.json` | Dix cosmétiques, dont un avatar, un thème et un cadre gratuits, et quatre emplacements de jeux payants |
| `data/controller_mapping.json` | Actions de manette configurables ; mapping standard à adapter après mesure USB HID |
| `scripts/ui/`, `themes/` | Thème, navigation persistante et aperçus de cosmétiques |
| `assets/art/`, `scripts/game/room_art.gd`, `tools/generate_art.py` | 43 SVG originaux CC0 : 36 pour l’atelier et 7 pour l’ascenseur et la salle réseau |
| `tests/`, [bilan de recette](console-ciel/docs/TESTS.md) | Tests isolés et résultats exécutés |
| `export_presets.cfg`, `tools/export.sh`, `tools/export_windows.ps1` | Export PC et Linux ARM64 ; PowerShell produit le ZIP Windows |
| `docs/windows/LIRE_MOI.txt`, [guide Windows](console-ciel/docs/WINDOWS.md) | Aide portable et réexport Windows avec les modèles exacts |
| `tools/package_source.py` | Archive source sans caches ni profils personnels |
| `tools/run_demo.sh` | Préparation et lancement d'un profil de soutenance dans des données isolées |
| `assets/LICENSES.md`, `assets/licenses/` | Crédits et licences des ressources locales |

Ne pas renommer les identifiants de missions ou d'articles déjà enregistrés sans migration. Prix et récompenses sont des entiers validés. [Architecture et contrats](console-ciel/docs/ARCHITECTURE.md).

## Tester sans toucher aux vrais profils

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/investigation_tests.gd
godot --headless --path . --script res://tests/ui_smoke.gd
# Recette groupée, dont trois processus indépendants :
python3 tools/run_acceptance.py --log-dir tests/release_results
# Barre inférieure et quatre résolutions (0.4.0) :
godot --headless --path . --script res://tests/refonte_navigation.gd
# Navigation et politique des périphériques virtuels de test :
godot --headless --path . --script res://tests/controller_tests.gd
# Quatre fermetures réelles avec brouillon et erreur d'écriture :
python3 tools/check_close.py
# Sécurité de la préparation du profil de démonstration :
python3 tools/check_demo.py
```

Les suites utilisent leurs propres données temporaires. Les compléments de recette, résultats et limites sont dans [TESTS.md](console-ciel/docs/TESTS.md) et [UI_TESTS.md](console-ciel/docs/UI_TESTS.md). Une sortie 0 doit être accompagnée d'un journal sans erreur de script inattendue.

Recette **0.6.1 du 14 octobre 2026** : **11 844 assertions source** dans 16 suites, **65 assertions de persistance** sur trois processus, **58 contrôles avec rendu X11** et 8 captures, **6 547 assertions du pack compilé**, **18 contrats Windows** et **27 contrôles de packaging**, zéro échec. [Résultats courants](console-ciel/tests/confort_0.6.1_results/summary.json), [8 captures réelles](console-ciel/docs/screenshots/confort_0.6.1/) et [avant/après de la commande de porte](console-ciel/docs/DELIVERY.md). Le pack compilé est exécuté avec Godot Linux ; le lancement natif Windows reste à vérifier sur votre PC.

Recette historique **0.6.0 du 14 octobre 2026** : **9 568 assertions source**, **65 de persistance** entre trois processus, **694 contrôles de rendu X11** et 12 captures, **4 351 assertions du pack compilé**, **18 contrats Windows** et **27 contrôles de packaging**, zéro échec. [Résultats](console-ciel/tests/chapitre_2_0.6.0_results/summary.json) et [captures réelles](console-ciel/docs/screenshots/chapitre_2_0.6.0/). Le pack Windows est testé avec Godot Linux ; son lancement natif et le matériel restent à essayer sur votre PC.

Recette historique intégrée exécutée le **11 octobre 2026** : **2 500 assertions, zéro échec**, puis **105 assertions de fermeture, zéro échec** et **36 vérifications de préparation démo, zéro échec**. Cette recette ancienne inclut la géométrie des trois résolutions et les entrées natives en headless ; elle ne comprend pas d’inspection visuelle ni de manette USB physique. Les captures et contrôles des versions ultérieures sont décrits dans leurs propres rapports de livraison.

Pour un essai interactif indépendant des profils habituels sous Linux :

```sh
XDG_DATA_HOME=/tmp/console-ciel-essai \
XDG_CONFIG_HOME=/tmp/console-ciel-config \
XDG_CACHE_HOME=/tmp/console-ciel-cache \
godot --path .
```

Après fermeture, supprimer uniquement ces dossiers d'essai pour réinitialiser cet environnement. Pour un profil de démonstration préparé, utiliser la procédure ciblée du guide de soutenance.

## Export, Raspberry Pi et limites

[Le guide Raspberry Pi](console-ciel/docs/RASPBERRY_PI.md) précise les fichiers à copier, l'installation par versions, les journaux, la conservation des profils et le retour à la version précédente. [EXPORT.md](console-ciel/docs/EXPORT.md) indique les modèles requis et les commandes.

Les presets Linux x86_64, **Windows Desktop x86_64** et Linux **ARM64** utilisent les modèles officiels **4.6.3 stable**. Les livraisons portables Windows et Raspberry Pi sont séparées. Le paquet Pi 4 contient un exécutable **ELF ARM64 autonome avec pack intégré**, ses lanceurs, l’aide et les licences. L’export, l’intégrité des ressources et les essais avec Godot Linux sont distingués du lancement natif sur le Pi dans les rapports de livraison.

L'export et les tests du projet ont été exécutés sous Linux. Aucun lancement par double-clic, rendu, son ou périphérique USB n'a été testé sous Windows ici. Le [guide Windows](console-ciel/docs/WINDOWS.md) sépare ces vérifications et donne le parcours à tester sur votre PC.

Le lanceur automatique est un livrable distinct : un exécutable utilisateur lancé avec `--fullscreen` dans la session graphique, après ouverture de labwc. Aucun deuxième autostart n'est créé et Godot n'est jamais lancé en root.

**Quitter** ferme l'application après sauvegarde. `PlatformService` conserve **« Arrêt système non configuré »** indisponible. Fermeture de l'application, arrêt du système et coupure électrique sont trois opérations distinctes. Aucun état fictif de batterie, température ou réseau n'est affiché.

[Le bilan de livraison](console-ciel/docs/DELIVERY.md) distingue tests automatiques, rendu visuel, essais manuels et matériel. [Les problèmes connus](console-ciel/docs/KNOWN_ISSUES.md) listent ce qui doit être vérifié avant une démonstration sur le Pi : rendu réel, son, manette, mapping fabriqué, plein écran dans la session bureau et performances. Aucun chiffre de FPS sur Raspberry Pi n'est acquis ici.

Crédits : **Loghan**, logiciel ; **binôme — nom à compléter**, construction et assemblage. Formes, icônes, décor et sons locaux originaux ; police intégrée à Godot. [Licences](console-ciel/assets/LICENSES.md).

Audit du 12 octobre 2026 : [périmètre, corrections, tests et limites](console-ciel/docs/AUDIT_CODE.md). Les outils de démonstration Linux requièrent `flock` (util-linux) et refusent deux sessions partageant la même racine.
