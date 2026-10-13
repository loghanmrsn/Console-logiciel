# Vérification des services et de l'enquête

Les suites utilisent Godot **4.6.3 stable** sans dépendance supplémentaire. Elles démarrent les services de l'application et redirigent les écritures vers un dossier temporaire unique sous `user://tests/`, supprimé après l'essai. Les vrais profils, réglages et achats restent intacts.

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/investigation_tests.gd
# Regroupe les suites et une vraie fermeture/relance dans trois processus :
python3 tools/run_acceptance.py --log-dir tests/release_results
# Politique de manette active, avec périphériques virtuels déclarés pour l'essai :
godot --headless --path . --script res://tests/controller_tests.gd
```

Si le dossier personnel est en lecture seule, donner à Godot des répertoires de travail isolés :

```sh
XDG_DATA_HOME="$PWD/.runtime-data" \
XDG_CONFIG_HOME="$PWD/.runtime-config" \
XDG_CACHE_HOME="$PWD/.runtime-cache" \
godot --headless --path "$PWD" --script res://tests/investigation_tests.gd
```

Une suite retourne `1` en cas d'échec, `0` si ses assertions réussissent. Une sortie `0` seule ne remplace pas la lecture du journal : une erreur de script Godot doit également être repérée.

## Couverture de la suite de services

`tests/run_tests.gd` conserve les vérifications de la première livraison et utilise désormais les réponses réelles de l'enquête :

- création, sélection, renommage et suppression ciblée de deux profils ; pseudos et identifiants indépendants ;
- achats, débit exact, article inconnu, solde insuffisant, prix invalides, double achat, équipement persistant ;
- récompenses attribuées une seule fois, même après rechargement, réinitialisation et nouvelle partie ;
- échecs d'écriture injectés pour les transactions, sans conservation d'un état mémoire partiel ;
- types, bornes, inventaire, équipement, checkpoint, identifiants et versions de données ;
- JSON corrompu, refus d'écrasement, conservation de l'original et récupération explicitement demandée ;
- aperçus des réglages, annulation, sauvegarde, rechargement, bus audio et zone morte ;
- récupération d'un ConfigFile corrompu, y compris échec d'écriture puis nouvelle tentative.

## Couverture de la suite d'enquête

`tests/investigation_tests.gd` vérifie les règles métier avec des profils temporaires :

- nouvelle partie sans mission terminée, objectifs verrouillés puis disponibles selon les prérequis ;
- refus d'une mission hors ordre et refus d'attribuer une réussite sans réponse validée ;
- circuit incomplet ou erroné, puis boucle correcte ;
- consultation des observations, faux diagnostic et fausse réparation de la serrure, puis correction justifiée ;
- symptômes de l'ordinateur, vérifications insuffisantes ou mauvaises hypothèses, puis diagnostic du câble vidéo ;
- plusieurs validations successives et absence de gain double ;
- lecture sur disque et reprise après chaque mission, indices, observations, checkpoint et compteur des gains de partie ;
- isolation entre deux profils et points disponibles pour la boutique après réussite ;
- nouvelle partie et remise à zéro conservant achats, solde et identifiants de récompenses, avec zéro nouvelle récompense au rejeu ;
- échec d'écriture pendant une réussite, rollback complet en mémoire, puis nouvelle tentative sans gain double ;
- adaptation d'un profil issu des interactions simulées et validation des nouveaux champs.

L'injection d'échec contrôle le comportement transactionnel du logiciel. Elle ne simule pas toutes les défaillances d'une carte microSD ou toutes les coupures d'alimentation. Les règles restent locales, sans système anti-triche.

## Compléments de stabilité 0.3.0

`tests/stability_tests.gd` ajoute les régressions de démarrage et récupération : copie précédente sans principal, session invalide, stockage inaccessible puis réessai, réglages défectueux et conservation des fichiers lors d’une écriture refusée. Les contrôles suspendus et la déconnexion sont vérifiés dans la suite d’interface décrite dans UI_TESTS.md. Ces scénarios utilisent les services et l'interface natifs avec des données de test.

`tests/controller_tests.gd` déclare explicitement des périphériques **virtuels de test** pour vérifier sélection d'une seule manette, conservation de la manette active, changement après retrait, filtrage des actions et absence de reprise automatique. Ce résultat ne prouve ni un branchement USB réel, ni le mapping du contrôleur fabriqué.

`tools/run_acceptance.py` utilise une racine temporaire marquée et lance les suites, puis **trois processus Godot indépendants** :

1. `write` crée deux profils, joue les missions, achète, équipe et sauvegarde.
2. `read_replay` repart de ces documents, vérifie identité/équipement/points, rejoue sans récompense supplémentaire et teste le second profil.
3. `read_final` redémarre encore et vérifie la persistance finale.

Les journaux et `summary.json` sont dans `tests/stability_results/` par défaut ; la commande de recette finale ci-dessus utilise `--log-dir tests/release_results`. Le runner compte une erreur de script comme un échec même si Godot sort avec 0, et exige le résumé final de chaque suite. La racine de données est supprimée à la fin et les vrais joueurs ne sont pas concernés. Pour ne lancer que la persistance multiprocessus :

```sh
python3 tools/run_acceptance.py --process-only
```

L'outil de préparation de démonstration fait également l'objet d'un test isolé : profil neuf à zéro, préremplissage explicite par validation réelle, conservation à la relance, suppression ciblée via manifeste et refus d'une racine normale ou d'un lien symbolique.

```sh
python3 tools/check_demo.py
```

`tools/check_close.py` lance **quatre autres processus Godot**, ouvre les vrais menus et paramètres, modifie le volume par une touche de slider puis ferme avec le code de production. Les cas sont appliquer, abandonner l'aperçu, écriture refusée puis réessai, écriture refusée puis annulation/restauration. Le test relit les documents après la sortie : mission, récompense, avatar acheté et équipé, points, réglages et session doivent être cohérents ; aucun temporaire ne subsiste. Les données marquées de cet essai sont créées sous `/tmp` puis supprimées.

```sh
python3 tools/check_close.py
```

## Résultats de recette intégrée 0.3.0

Exécution réelle le **11 octobre 2026**, moteur `4.6.3.stable.official.7d41c59c4`, headless. La recette groupée s'est terminée à **15:58 UTC** : huit jobs complets, sortie 0, **2 500 assertions et zéro échec**. [Résumé JSON](../tests/release_results/summary.json).

| Suite | Assertions, échecs | Journal |
|---|---|---|
| Services, profils, boutique et paramètres | 190, **0** | [business.log](../tests/release_results/business.log) |
| Validation et transactions d'enquête | 189, **0** | [investigation.log](../tests/release_results/investigation.log) |
| Manette active et action diagnostic | 22, **0** | [controllers.log](../tests/release_results/controllers.log) |
| Interface native, collisions, focus et matrice de géométrie | 1 937, **0** | [native_ui.log](../tests/release_results/native_ui.log) |
| Démarrage, réessais et récupération | 97, **0** | [stability.log](../tests/release_results/stability.log) |
| Trois processus de persistance | 28 + 26 + 11 = 65, **0** | `tests/release_results/persistence_*.log` |
| Quatre fermetures réelles et lecture externe des documents | 105, **0** | [close_summary.json](../tests/stability_results/close_summary.json), `close_*.log` |
| Préparation du profil de démonstration | 36 **vérifications**, **0** | [demo-preparation-results.log](../tests/demo-preparation-results.log) |

Les 105 assertions de fermeture sont complémentaires aux 2 500 de la recette groupée. Une relance rapide de l'interface a également réussi **309 assertions, zéro échec** dans [stability-ui-quick-results.log](../tests/stability-ui-quick-results.log) ; elle recoupe des scénarios du parcours complet et n'est pas ajoutée au total de référence.

Aucune erreur de script inattendue dans les suites réussies. La corruption volontaire de ConfigFile émet son message de parse attendu ; le test vérifie ensuite la récupération. Les assertions mesurent les données, entrées, collisions et géométrie, sans preuve de rendu visuel, son perçu, branchement USB physique ou performance sur Pi.

## Résultats historiques de l'enquête 0.2.0

Exécution réelle le **11 octobre 2026**, avec `4.6.3.stable.official.7d41c59c4`, en mode headless :

| Suite | Résultat | Journal |
|---|---|---|
| Services existants adaptés aux défis réels | **190 assertions, zéro échec**, sortie 0 | [`tests/latest-results.log`](../tests/latest-results.log) |
| Validation, progression et transactions d'enquête | **189 assertions, zéro échec**, sortie 0 | [`tests/investigation-results.log`](../tests/investigation-results.log) |

Aucune erreur de script n'apparaît dans ces exécutions. Les cinq validations successives d'une même réussite restent à une seule récompense. La suite vérifie aussi 150 points gagnés pour l'enquête et un solde de 130 après un achat, pour que le bilan ne confonde pas les deux valeurs.

Historique de la première livraison 0.1.0, exécutée les 10 et 11 octobre 2026 : **166 assertions de services, zéro échec** dans [`tests/backend-results.log`](../tests/backend-results.log). Ce résultat concerne l'ancien prototype et ne constitue pas à lui seul une validation des nouveaux défis.

La corruption volontaire d'un ConfigFile produit un message moteur `ConfigFile parse error` attendu ; le test vérifie ensuite le refus du document et sa récupération explicite. Le démarrage normal ne doit pas produire cette erreur.

Les entrées natives, collisions et géométrie des écrans sont décrites dans [UI_TESTS.md](UI_TESTS.md). Les essais réels avec écran, son et contrôleur, puis les performances, l'export ARM64 et le rendu labwc restent à réaliser sur le Raspberry Pi.
