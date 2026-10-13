# Audit du code et des parcours — Console CIEL

Audit repris et terminé le **12 octobre 2026**, sur le projet natif **0.3.0**. Les corrections sont dans les sources ; le thème et l’architecture existants sont conservés. Ce rapport décrit les vérifications exécutées et leurs limites, sans garantir l’absence de tout bug.

## Environnement et méthode

- Godot **4.6.3.stable.official.7d41c59c4**, édition standard, rendu configuré Compatibility (`gl_compatibility`).
- Linux x86_64, Python **3.12.14**, Bash **5.2.37**, `flock` disponible. Aucun AGENTS.md trouvé. README et documents du projet lus.
- Aucun affichage graphique, Xvfb ou périphérique de manette utilisable ; tests Godot en headless. ShellCheck absent : `bash -n`, lecture et tests de commandes avec chemins contenant des espaces ont été utilisés.
- `.git` est un emplacement fourni par l’environnement, sans dépôt Git exploitable : `git status` échoue. Il est impossible d’identifier des modifications non commises par rapport à un commit. Une copie et des empreintes des sources présentes avant les corrections ont servi à produire [le diff de cette passe](../tests/audit_results/changes.diff), sans remise à zéro.
- Tous les essais utilisent des données sous des dossiers temporaires ou une sous-racine `user://tests/` propre au cas ; aucun vrai profil n’a été modifié. Les sous-processus de recette redirigent données, configuration et cache XDG vers un dossier temporaire supprimé après leur exécution.

La passe finale inventorie **134 fichiers** : 81 sources/documents, 46 métadonnées, cinq fichiers de licences tierces et deux ressources WAV. Elle résout 43 UID de scripts et contrôle 74 références res:// littérales. Le suivi fichier par fichier est dans [inventory.json](../tests/audit_results/static/inventory.json) : catégorie, analyses effectuées, références, UID et résultats. Les journaux utiles sont sous `tests/audit_results/`.

## Périmètre examiné

| Catégorie | Méthode et portée |
|---|---|
| Tous les GDScript de scripts/, tests/ et tools/ | Lecture de la logique des services, du menu, des composants, du jeu et des outils ; compilation/chargement de chaque script par ResourceLoader dans le **contexte du projet avec ses Autoloads** ; exécution des suites pertinentes |
| Quatre scènes .tscn, thème et AudioBusLayout .tres | Chargement et instanciation natifs ; vérification des chemins, de la scène principale et du nœud Status du démarrage |
| project.godot, export_presets.cfg | Lecture, import natif, noms/scripts des dix Autoloads, actions Input Map, trois bus audio, trois presets dont ARM64 et pack intégré |
| JSON règles, catalogue, mapping | Parsing, validation métier et tests de mutations de champs ; les transactions et parcours couverts dans les suites existantes et nouvelles |
| Python, dont générateur audio | AST de chaque fichier ; lecture des outils, tests réels ou simulations isolées ; le générateur audio n’a pas été exécuté pour réécrire les ressources |
| Tous les Bash | bash -n ; tests d’import/export/preparation, erreurs, chemins avec espaces et verrou de lancement |
| Documentation et procédures | Lecture, liens locaux, cohérence versions/commandes/données ; corrections des exemples d’installation et sauvegarde pour éviter fusion et réemploi d’un dossier temporaire |
| UID et métadonnées .import | Unicité, format, fichier source présent ; résolution native des UID de scripts. Métadonnées importées régénérées uniquement par l’import normal Godot |
| Ressources binaires | Présence, références et en-têtes WAV ; chargement natif lors de l’import/lancement. Aucune analyse assimilant le binaire à du code ni écoute audio revendiquée |
| Licences tierces | Présence, JSON et liens ; conservées sans modification. Le moteur et son code tiers ne sont pas réaudités |
| Shaders, installation et autostart | Aucun shader ni installateur/autostart propre au projet trouvé. Le lanceur Pi annoncé reste externe ; aucune installation système exécutée |
| Générés | .godot, caches XDG, anciens journaux et archives distingués des sources ; pas de modification du cache pour masquer une erreur |

Une tentative de `--check-only --script` sur un service isolé ne charge pas les Autoloads et produit des « Identifier not found » artificiels. La vérification finale utilise donc le chargement natif de **tous** les scripts dans le projet, pas ces diagnostics hors contexte. Les dossiers `docs/screenshots` et `builds/demo-runtime` sont des sorties créées à l’exécution, pas des ressources manquantes.

## Défauts confirmés et corrections

| Priorité | Défaut et cause | Correction / fichiers |
|---|---|---|
| **P0** | Une version CFG booléenne déclenchait une comparaison bool/int invalide. Le chargement pouvait s’interrompre en laissant le démarrage bloqué. Le mapping avait la même comparaison non protégée. | Vérifier les types avant les comparaisons ; SettingsService et InputSetup retournent désormais une erreur contrôlée et récupérable |
| **P1** | `room_id`, état initial et solutions de mission mal typés provoquaient des erreurs GDScript au lieu d’un refus de validation. | Gardes String dans `save_service.gd` ; 1 160 mutations null/bool/tableau/objet vérifient un résultat structuré sans erreur du moteur |
| **P0** | Retirer seulement `investigation_version` d’une progression récente la faisait reconnaître comme un prototype et effacer ses missions/indices lors de migration. | Migration limitée aux quatre champs connus du prototype. Une progression enrichie sans version est refusée et conservée ; la vraie migration historique reste testée |
| **P1** | Échap dans la confirmation Rejouer quittait le bilan et reprenait l’exploration. | `demo_game.gd` restitue la conclusion, comme le bouton Annuler |
| **P2** | Fermer un défi/panneau ne libérait pas ses enfants et conservait `challenge` masqué. | Fermeture retire/libère les enfants et vide la référence. Le contexte conservé pendant une perte de manette reste distinct et préservé |
| **P1** | Les listes/récupérations de profils ignoraient un échec de refresh et pouvaient montrer des données périmées. | `main.gd` présente une erreur avec réessai dans les trois chemins concernés. Le dossier bloqué par un fichier produit un diagnostic contrôlé |
| **P2** | Le thème prévisualisé n’actualisait pas la coche de sélection. | Rafraîchir les choix en conservant leur focus ; Annuler garde le thème enregistré |
| **P1** | P et espace pouvaient être avalés pendant la saisie du pseudo durant le verrou de transition. | Les raccourcis de jeu/onglets sont exclus quand un LineEdit reçoit le texte ; Entrée/Échap conservent la protection de transition |
| **P1** | Déconnexion pendant la confirmation de fermeture de réglages : le message différé n’était transmis que par les dialogues classiques. | Fin de modale centralisée dans `main.gd` ; le jeu conservé reçoit la perte et exige une reprise explicite, puis retrouve sa pause |
| **P2** | Une attente de disposition de dialogue pouvait appeler get_tree après son retrait ; des contrôles survivants restaient sans focus lors d’un retrait inattendu. | Gardes avant/après attente et restauration à la sortie d’arbre dans `confirmation_dialog.gd` |
| **P1** | Export/démo pouvaient poursuivre après une erreur de script avec sortie Godot 0, ou annoncer un ancien binaire comme nouveau. | `godot_checked.sh` vérifie les diagnostics ; export en dossier temporaire, contrôle du nouveau fichier non vide, conservation du binaire précédent en cas d’échec |
| **P1** | Deux démonstrations pouvaient préparer/utiliser simultanément la même racine. | Verrou flock conservé pendant la préparation et l’exécution ; aucun nouveau mécanisme d’autostart |
| **P1** | Le paquet source suivait un lien de fichier et pouvait inclure une cible hors des sources ou écraser une cible liée. | Refus des symlinks, création/CRC en temporaire puis remplacement du ZIP dans `package_source.py` |
| **P2** | Le runner acceptait des versions non stables et des ERROR moteur génériques ; check_close donnait une traceback avec moteur absent. | Version stable vérifiée, erreurs inattendues rejetées ; seules corruptions ConfigFile intentionnelles des copies de deux suites sont reconnues ; diagnostic de moteur absent |
| **P2** | Exemples Pi/template pouvaient fusionner une copie ou réutiliser un répertoire d’extraction ; exemple de test lié à /workspace. | Répertoire de version neuf, copie sans destination préexistante, mktemp pour modèles, chemins basés sur le dossier courant |

Aucune erreur de syntaxe dans les sources initiales n’a été confirmée ; les erreurs importantes ci-dessus étaient des erreurs de types et de logique à l’exécution. Les défauts identifiés sont corrigés et leur périmètre voisin a été réessayé. Les achats, récompenses uniques, isolation entre profils et récupération ne sont pas remplacés par une nouvelle architecture.

## Exécuter les vérifications

Depuis la racine, avec Godot 4.6.3 stable :

```sh
python3 tools/audit_project.py
python3 tools/run_acceptance.py --log-dir tests/audit_results/final
python3 tools/check_audit_tools.py
python3 tools/check_close.py --log-dir tests/audit_results/close
python3 tools/check_demo.py
```

Le runner ajoute `tests/audit_regressions.gd` et `tests/audit_validation.gd` à la recette existante. `tests/audit_resources.gd` compile les scripts, résout les UID et charge les scènes/ressources. Les rapports finaux sont listés ci-dessous.

## Résultats et limites de livraison

La dernière recette du **12 octobre** passe **3 694 assertions**, zéro échec, dans dix processus/jobs terminés : services 190, enquête 189, contrôleurs 22, régressions audit 34, mutations de champs 1 160, interface 1 937, démarrage/récupération 97, persistance multiprocessus 28 + 26 + 11. [Résumé complet](../tests/audit_results/final/summary.json).

| Vérification complémentaire | Résultat | Preuve |
|---|---|---|
| Syntaxe/formats/références de tous les fichiers inventoriés | Aucune erreur dans la passe finale | [Inventaire](../tests/audit_results/static/inventory.json), [sortie](../tests/audit_results/static.log) |
| Compilation des 43 GDScript, ressources, UID, Autoloads, bus et presets | 144 assertions, zéro échec | [Contexte Godot](../tests/audit_results/static/godot-project-context.log) |
| Quatre véritables fermetures avec réglages appliqués/annulés, erreur et réessai | 105 assertions, zéro échec ; fichiers relus après sortie | [Résumé](../tests/audit_results/close/close_summary.json) |
| Préparation démo et conservation d’un deuxième profil | 36 vérifications, zéro échec | [Journal](../tests/audit_results/demo.log) |
| Outils, erreurs Godot, chemins avec espaces, ZIP/liens et double lancement | 16 assertions, zéro échec ; stubs dans des dossiers temporaires | [Journal](../tests/audit_results/tools.log) |
| Import de l’archive source extraite puis démarrage source/pack 30 frames | Sorties 0, sans erreur de script ; socket de l’éditeur refusé durant import | [Source](../tests/audit_results/source-launch.log), [pack](../tests/audit_results/pack-launch.log) |
| Export ARM64 autonome réellement tenté | Sortie 1 ; modèles linux_debug.arm64 / linux_release.arm64 absents | [Journal](../tests/audit_results/arm64-export.log) |

Les journaux historiques du 11 octobre restent historiques ; ils ne remplacent pas cette passe. Les chiffres complémentaires ne sont pas ajoutés aux 3 694 de la recette : ils comprennent des vérifications qui se recoupent. Le pack exporté contient les ressources, sans outils ni tests, et se charge avec Godot installé ; ce n’est pas un exécutable Pi.


- **Pas de validation visuelle** : géométrie/focus contrôlés à 1280 × 720, 1024 × 600, 800 × 480, texte normal/grand et transparence réduite par le moteur headless ; contraste, rendu perçu et captures non vérifiés.
- **Pas de manette physique** : événements natifs et périphériques virtuels déclarés pour les tests. USB HID, joystick au repos réel, retrait/reconnexion matériels restent à essayer.
- **Pas de binaire ARM64 autonome** : presets et ressources contrôlés, modèles d’export 4.6.3 absents. Import/export d’éditeur montrent aussi un refus de socket TCP imposé par cet environnement ; ce refus est signalé, pas présenté comme un lancement Pi.
- **Pas de modifications système** : installation, lien current et autostart non exécutés sur la machine ; fichiers du lanceur externe absents. Les snippets Pi sont examinés, pas annoncés installés.
- Arrêt système et coupure électrique toujours non intégrés. Quitter ferme seulement l’application ; pas de mesure fictive de batterie/température/performance.
- Répétition matérielle avant soutenance : export ARM64, lancement labwc/fullscreen, parcours sans souris, sons/bus, deux profils, reprise après chaque mission, boutique/équipement, retrait USB, trois tailles et FPS réels sur Pi. Crédits du binôme à compléter.

Les fichiers conservés en `.corrupt`, `.bak.previous` ou `.deleting` après une interruption physique exceptionnelle peuvent encore demander une réparation manuelle. La stratégie locale n’est pas une garantie contre toute coupure ni un système anti-triche. Le lancement direct de plusieurs instances Godot hors du wrapper de démonstration n’est pas verrouillé ; le lanceur Pi externe devra garantir une seule instance. Aucun dispositif matériel non disponible n’est déclaré validé.
