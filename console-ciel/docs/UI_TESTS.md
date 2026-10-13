# Vérification de l'interface et de l'exploration

Depuis le **13 octobre 2026**, des captures réelles X11/Mesa sont disponibles. Voir [la passe de finition 0.3.1](FINITION_VISUELLE.md), la matrice `docs/screenshots/finition/` et les résultats `tests/visual_results/`. Les limites historiques ci-dessous décrivent les essais précédents.

`tests/ui_smoke.gd` instancie la scène native `scenes/main.tscn` avec Godot 4.6.3. Il injecte des événements clavier, boutons et axes dans le système d'entrée Godot ; les boutons ne sont pas activés par un simple signal `pressed`. Les scénarios de mise en page peuvent ouvrir un écran directement pour couvrir toutes les catégories.

```sh
godot --headless --path . --script res://tests/ui_smoke.gd
```

Pour ne relancer que le parcours fonctionnel et les entrées, sans la matrice complète de géométrie :

```sh
godot --headless --path . --script res://tests/ui_smoke.gd -- --quick
```

Le mode complet reste le comportement par défaut et le résultat de référence ci-dessous.

Les services de profils et de réglages utilisent un dossier `user://tests/ui_<identifiant>/` créé pour l'essai, puis supprimé. Les vrais profils et réglages restent intacts.

## Périmètre

La suite conserve la couverture du menu : création sans clavier physique, clavier virtuel, saisie physique, absence de raccourci d'onglet pendant la saisie, sélection de profil, aide, boutique, paramètres, achat confirmé et équipement persistant.

Elle vérifie le focus initial, sa mémorisation au retour, la capture des commandes par les confirmations, gauche/droite sur les sliders et haut/bas entre leurs lignes. Des axes injectés sous la zone morte ne déplacent pas le focus ; au-dessus du seuil, la navigation reprend. Les changements de catégorie au clavier et à la manette simulée sont inclus.

Le parcours d'enquête vérifie l'entrée depuis le menu, une interaction verrouillée, les trois défis avec réponses incorrectes puis correctes, le refus de conclure sans observations ou vérifications et une erreur d'écriture suivie d'une nouvelle tentative. Il couvre aussi les contrôles suspendus pendant un défi ou une pause, les retours aux paramètres et au menu, les reprises après les missions, le rejeu sans nouvelle récompense, puis l'achat et l'équipement en boutique. Les données enregistrées sont relues pour distinguer un état affiché d'une transaction réellement sauvegardée.

La matrice de géométrie porte sur **1280 × 720**, **1024 × 600** et **800 × 480**, en texte normal puis grand texte avec transparence réduite. Elle vérifie les contrôles essentiels, libellés, focus et défilement. Les écrans longs peuvent défiler : chaque bouton focalisé doit rester accessible et visible. Les collisions utilisent le moteur de physique Godot ; les scénarios automatisés et leurs résultats finaux sont précisés dans le bilan.

Pour préparer certaines interactions, le script place le personnage près de l'équipement puis injecte la commande Espace ; il ne parcourt pas automatiquement toute la pièce depuis l'entrée. Les collisions font l'objet de scénarios distincts : les déplacements réellement injectés doivent être bloqués par les murs, le mobilier et la porte fermée, puis franchir la porte réparée.

## Compléments de recette intégrée 0.3.0

La suite ajoute une manette virtuelle active et une autre inactive, les pertes de connexion pendant exploration, défi et paramètres ouverts depuis la pause, ainsi que la reconnexion sans reprise automatique. Elle conserve les choix du défi et exige une action explicite pour reprendre. Ces scénarios utilisent les signaux du service et les événements injectés ; ils ne constituent pas un retrait USB physique.

Le diagnostic F3 et les fermetures avec brouillon de réglages sont couverts. Une erreur d'écriture doit garder la session ouverte ; une nouvelle tentative réussie permet la sortie. Les validations rapides répétées ne doivent pas superposer les dialogues ou franchir deux écrans.

La matrice des trois tailles et des deux modes de texte comprend aussi les confirmations d'achat, de fermeture et de brouillon, la pause de perte de manette et le diagnostic de développement. Les résultats de la version intégrée sont repris dans [DELIVERY.md](DELIVERY.md) et dans les journaux de recette.

Exécution réelle finale le **11 octobre 2026**, Godot `4.6.3.stable.official.7d41c59c4` headless : **1 937 assertions, zéro échec, sortie 0**, dans [native_ui.log](../tests/release_results/native_ui.log). Le journal ne contient aucune erreur de script ni alerte de ressource orpheline. Le scénario ajouté confirme notamment que P ne réagit pas derrière une confirmation de fermeture.

La relance rapide du parcours a également réussi **309 assertions, zéro échec**, dans [stability-ui-quick-results.log](../tests/stability-ui-quick-results.log). Elle recoupe une partie des essais complets ; elle ne remplace pas la matrice de géométrie.

Les **105 assertions de fermeture** de `python3 tools/check_close.py` utilisent quatre sorties réelles de l'application et relisent les documents dans le processus Python : réglages appliqués/annulés, échec d'écriture, réessai, restauration, progression, solde, équipement et session. [Résumé de fermeture](../tests/stability_results/close_summary.json).

## Résultats historiques 0.2.0 et portée

Exécution réelle le **11 octobre 2026**, avec `4.6.3.stable.official.7d41c59c4` en mode headless : **1743 assertions, zéro échec, sortie 0**, dans [`tests/ui-results.log`](../tests/ui-results.log). Le journal final ne contient aucune erreur de script, alerte `WARNING`, erreur moteur ou débordement de mise en page.

Les trois tailles, les deux modes de texte et la transparence réduite couvrent le menu, les paramètres et l'enquête : les trois défis, la pause, le dialogue de prérequis, la conclusion et la confirmation de rejeu. Les boutons de défis utilisent réellement 18 px en mode normal et 22 px en grand texte. Des validations rapides répétées et un appui de manette qui ouvre un défi ne produisent pas de réponse ou récompense supplémentaire.

Le parcours gagne 150 points, rejoue avec zéro gain nouveau puis vérifie un achat qui ramène le solde à 130 et un équipement persistant. La porte fermée bloque physiquement le CharacterBody2D ; la porte réparée devient franchissable. Murs et mobilier sont également testés par déplacements.

Les résultats sont regroupés dans [DELIVERY.md](DELIVERY.md). L'historique 0.1.0 avait **830 assertions, zéro échec**, pour les menus et anciennes interactions simulées ; il ne prouve pas la jouabilité des défis ajoutés.

Aucun affichage graphique utilisable n'est disponible dans cet environnement. Les contrôles headless sont des mesures de géométrie, de texte, d'entrée et de physique du moteur ; ils ne sont pas une inspection visuelle. Aucun screenshot censé prouver un rendu n'est fabriqué.

Sur une machine disposant d'un affichage, le mécanisme de capture existant peut être lancé :

```sh
godot --path . --script res://tests/ui_smoke.gd -- --screenshots
```

Les captures sont les textures réellement rendues par le viewport, enregistrées dans `docs/screenshots/`. Sans affichage, aucune image n'est produite.

## Vérifications manuelles restantes

- Jouer une enquête entière sans souris sur PC, puis avec une manette physique ; vérifier les mauvais choix, le focus visible et la récupération des déplacements après chaque dialogue.
- Vérifier visuellement les trois tailles d'écran et le grand texte : lisibilité du décor tamisé, caméra, collisions, schéma du circuit, porte ouverte et message final.
- Mesurer les axes au repos, le mapping, les appuis maintenus et la répétition avec le vrai contrôleur USB HID ; tester déconnexion et reconnexion.
- Écouter les sons, vérifier les réglages de volume et le plein écran effectif, y compris `--fullscreen` sous labwc.
- Exporter et lancer le binaire ARM64 sur Raspberry Pi 5 ; mesurer les performances du menu et de l'enquête. Aucun chiffre de performance Pi n'est acquis ici.

Quitter n'arrête pas le Raspberry Pi. Aucun test ne présente de batterie, réseau ou arrêt système non mesuré comme fonctionnel.
