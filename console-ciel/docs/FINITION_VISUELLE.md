# Finition visuelle 0.3.1 — 13 octobre 2026

Le projet est conservé : Godot **4.6.3.stable.official.7d41c59c4**, Compatibility, mêmes services et format de sauvegarde. Aucun changement des réponses, prérequis, prix ou récompenses. Aucun profil utilisateur utilisé ; aucun envoi ni publication externe.

## Rendu réellement disponible

Un serveur **Xorg avec pilote dummy**, démarré pour cet essai avec une configuration temporaire, permet maintenant de lancer Godot via **X11**. Le renderer est **Mesa llvmpipe**, OpenGL 4.5, rendu logiciel sur CPU. Les images proviennent de `Viewport.get_texture().get_image()` après `RenderingServer.frame_post_draw`. Ce sont des captures de l'application exécutée, pas des illustrations générées.

Les essais utilisent des dossiers XDG temporaires distincts et `user://tests/visual_review`. Les deux profils portent les noms « Démo Loghan » et « Démo Camille ». Les points de la recette viennent des trois validations métier réelles ; aucune règle ni sauvegarde normale n'est modifiée. Le son est dirigé vers le pilote **Dummy** : les réglages sont vérifiés, pas leur restitution sonore.

## Défauts observés et corrections

| Observation dans le rendu précédent | Correction ciblée |
|---|---|
| « Retour » presque vide, largeur rétrécie | Largeur minimale explicite de 112 px ; libellé lisible en normal/grand |
| Notification recouvrant les boutons et rappels | Notification intégrée au conteneur vertical, au-dessus du bandeau de commandes ; espace réservé lorsqu'elle apparaît |
| Notification trop brève pour certains messages | Durée de 6 à 12 secondes selon la longueur ; erreurs importantes toujours modales avec action |
| Sliders dessinés comme de gros panneaux avec ombre | Piste fine avec StyleBox dédié ; zone de commande de 36 px conservée, focus de 3 px |
| Valeur audio occupant une ligne séparée | Titre et valeur réunis dans une ligne ; retour à la ligne désactivé pour la valeur |
| Accueil tronqué en 1280 × 720 au premier focus | Actions secondaires regroupées, illustration plus compacte et descriptions redondantes retirées |
| Motifs translucides nuisant à la lecture | Opacité 0,94 pour cartes/boutons ; mode opaque toujours respecté |
| Petites légendes et commande désactivée ambiguë | Type produit et pied de page agrandis ; texte désactivé plus contrasté ; raison de Continuer affichée dans la carte |
| Commandes de jeu partiellement sous le bas en 800 × 480 grand texte | Hauteur minimale de la vue adaptée et consigne compacte ; Pause et interaction visibles |

Les titres, boutons, pistes de sliders, espacements, opacité et états restent centralisés dans `theme_factory.gd` et les composants existants. Focus par bordure nette ; succès accompagné de « ✓ » et de texte. Les notifications de création et d'équipement nomment simplement le résultat après la sauvegarde réussie. Les rappels utilisent des positions de boutons génériques, sans affirmer le mapping USB du contrôleur fabriqué.

Une nouvelle requête de redimensionnement pouvait reprendre après le retrait du jeu de l'arbre ; `_resize_viewport()` vérifie désormais `is_inside_tree()` avant de lire le viewport.

## Écrans inspectés

Démarrage, création/clavier virtuel, profils, accueil, paramètres audio, boutique, inventaire, enquête et objectifs, pause, dialogue de prérequis, défi électrique, conclusion et confirmation d'erreur. La matrice du pilote de capture couvre **1280 × 720**, **1024 × 600**, **800 × 480**, en texte normal et en grand texte avec réduction de transparence/animations. Les longues pages défilent et le focus est automatiquement rendu visible ; tous les boutons d'un écran défilant ne sont pas simultanément visibles.

Captures finales : `docs/screenshots/finition/` (**62 captures**, plus le démarrage). Inventaire réel : `tests/visual_results/captures.json`. Les images d'avant correction sont dans `tests/visual_results/before/`. Les captures portant seulement `conclusion_1280x720.png`, issues d'un premier essai de pilotage, montraient la pièce terminée ; elles ne servent pas de preuve du panneau de conclusion. Les fichiers finaux `conclusion_<taille>_<mode>.png` ouvrent explicitement le panneau réel.

## Recette et reproduction

- `tests/visual_review.gd` : capture réelle et transactions ciblées, achat/équipement, changement de profil, relecture et erreur d'écriture simulée.
- `tests/ui_smoke.gd` : navigation native, focus, sliders, modales, clavier virtuel, transitions jeu/menu et géométrie des trois tailles. La passe headless complète a exécuté **1 937 assertions sans échec**.
- La relance avec affichage **X11/Mesa** et événements injectés, accumulation désactivée uniquement dans le pilote de test, a exécuté **309 assertions sans échec**. Journal : `graphical-navigation-unbuffered.log`. Cela ne constitue pas une frappe humaine ni un branchement USB physique.
- `tests/run_tests.gd` : **190 assertions sans échec**, profils, paramètres, boutique, sauvegardes et récupération. Le diagnostic ConfigFile volontaire concerne uniquement une copie de test.
- `tools/check_windows_export.py` : **22 assertions sans échec**, publication de l'archive après succès, erreurs et conservation de l'ancienne livraison.
- `tools/audit_project.py` : compilation Godot, références/UID, Python, JSON et Bash. Journaux dans `tests/visual_results/static/`.
- Le **pack embarqué dans le nouvel EXE Windows** a été chargé par Godot Linux headless : **47 assertions sans échec**, dont trois missions, achats, équipement et reprise. CRC du ZIP contrôlés, aucun profil personnel, ancien ZIP inchangé par SHA-256. Résultat : `tests/visual_results/windows-package.json`.

Le premier essai de navigation avec rendu a révélé des attentes entre images et une accumulation des entrées qui faussaient le test de validations « rapides » sur llvmpipe. Le pilote de test désactive l'accumulation pour ses événements synthétiques **uniquement avec affichage**, conserve une image pour livrer le relâchement à la GUI, puis déclenche la rafale immédiatement après l'ouverture. Le mode headless conserve son réglage habituel. Le pilote vérifie aussi qu'un dialogue est encore valide avant de l'utiliser : l'ancien test pouvait poursuivre avec un objet libéré et faire planter le moteur. Le comportement d'entrée de l'application en livraison n'est pas modifié. Les échecs initiaux et intermédiaires restent consignés, pas supprimés. Les résultats finaux réussis sont dans `graphical-navigation-unbuffered.log` (**309 assertions**) et `navigation-layout-final.log` (**1 937 assertions**).

Pour les captures, démarrer un affichage X11 adapté puis lancer depuis la racine avec des données isolées (remplacer `:91` par l'affichage disponible) :

```bash
DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 \
XDG_DATA_HOME=/tmp/ciel-rendu/data \
XDG_CONFIG_HOME=/tmp/ciel-rendu/config \
XDG_CACHE_HOME=/tmp/ciel-rendu/cache \
godot --audio-driver Dummy --path . --script res://tests/visual_review.gd
```

L'outil refuse le mode headless pour les captures. Le serveur Xorg de cet essai n'est pas un autostart du projet et ne modifie aucun réglage de démarrage de la machine.

## Export Windows distinct

Nouvelle version : **`builds/Console_CIEL_Windows_x86_64_finition_0.3.1.zip`** ; exécutable dans `builds/windows-x86_64-finition-0.3.1/Console_CIEL.exe`. L'ancien **`builds/Console_CIEL_Windows_x86_64.zip`** reste la version 0.3.0. Sa taille et son SHA-256 sont conservés dans `tests/visual_results/previous_windows.json` pour vérifier l'absence de modification.

Le script accepte désormais des destinations explicites pour conserver les versions précédentes :

```powershell
.\tools\export_windows.ps1 `
  -GodotPath 'C:\Outils\Godot_v4.6.3-stable_win64_console.exe' `
  -ArchiveName 'Console_CIEL_Windows_x86_64_finition_0.3.1.zip' `
  -OutputDirectory 'windows-x86_64-finition-0.3.1'
```

Avec ses paramètres par défaut, le script conserve le comportement d'export précédent. Les modèles officiels Windows 4.6.3 sont utilisés ; preset Linux ARM64 conservé. Le binaire Windows reste non signé et n'est pas annoncé comme exécuté sous Windows.

## Limites

Rendu logiciel X11, pas écran physique Windows/Pi. Aucune manette USB réelle, aucun mapping du contrôleur fabriqué, aucune écoute audio ni mesure des performances Raspberry Pi. Le pilote ne permet pas le réglage V-Sync ; l'avertissement est attendu. Une inspection sur l'écran final et une répétition à la manette restent nécessaires. L'affichage des images dans la conversation ne garantit pas que l'explorateur de fichiers iPhone permette leur téléchargement.
