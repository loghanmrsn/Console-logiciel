# Graphismes 0.26.0

La refonte reste un jeu 2D vu du dessus. Elle donne du relief aux objets par leurs silhouettes, leurs matériaux, leurs ombres et leurs détails : toitures variées, lucarnes, volets, encadrements de fenêtres, arbres à couronnes irrégulières, tables de terrasse, mobilier rembourré et équipements informatiques. Les douze poses du personnage ont des membres et des vêtements plus arrondis. Les cartes de la console, les boutons, les aperçus des thèmes et les sièges du bus suivent cette direction.

Les géométries des routes, des murs et des obstacles proviennent toujours des layouts existants. Les petites lumières d’entrée restent au-dessus des décors ; les façades décoratives ne deviennent pas des portes utilisables. La façade particulière de Louise Michel et le logo fourni sont conservés.

## Comparaisons réelles

Captures du moteur Godot Compatibility, fenêtre 1 280 × 720 ; préférences sombres et grand texte également vérifiés en 800 × 480. Les images sont des captures du jeu exécuté, sans retouche. Les deux versions utilisent les mêmes profils de test isolés, positions de caméra et vues dégagées.

| Vue | Avant, version 0.25.0 | Après, version 0.26.0 |
|---|---|---|
| Ville | [Avant](screenshots/graphics_0.26.0/baseline/jeu_courtyard_challenge.png) | [Après](screenshots/graphics_0.26.0/graphics_gallery_tests/jeu_courtyard_challenge.png) |
| Laboratoire réseau | [Avant](screenshots/graphics_0.26.0/baseline/jeu_school_network_lab_challenge.png) | [Après](screenshots/graphics_0.26.0/graphics_gallery_tests/jeu_school_network_lab_challenge.png) |
| Chambre 206 | [Avant](screenshots/graphics_0.26.0/baseline/jeu_hotel_room_206_challenge.png) | [Après](screenshots/graphics_0.26.0/graphics_gallery_tests/jeu_hotel_room_206_challenge.png) |
| Console | [Avant](screenshots/graphics_0.26.0/baseline/console_home_challenge.png) | [Après](screenshots/graphics_0.26.0/graphics_gallery_tests/console_home_challenge.png) |

[Directions du personnage](screenshots/graphics_0.26.0/graphics_gallery_tests/personnage_directions_challenge.png) · [Interface compacte sombre](screenshots/graphics_0.26.0/graphics_gallery_tests/console_compact_nuit_challenge.png) · [Sièges du bus](screenshots/graphics_0.26.0/town_ui_tests/bus_attente_assise_challenge.png).

## Décors précalculés

Les premiers dessins détaillés augmentaient trop le coût de rendu dans la ville et le laboratoire. Les parties fixes sont donc générées une fois en 117 petits sprites PNG, avec transparence prémultipliée, marges transparentes supprimées et mipmaps. La somme théorique des textures RGBA et de leurs mipmaps est inférieure à 40 Mio. Les feux et la fontaine restent animés par leurs composants habituels. Les sauvegardes, les missions et le prix du bus ne dépendent pas de ces images.

Les dessins GDScript restent les sources modifiables et le rendu de secours si un sprite manque. `assets/art/baked/manifest.json` relie chaque sprite à son origine dans le monde, conserve les empreintes des sources et du générateur, et fait partie des trois profils d’export. Le logo garde ses droits réservés, y compris dans les sprites précalculés ; voir [les licences](../assets/LICENSES.md).

Pour régénérer les sprites après modification des dessins, depuis le dossier du projet et avec un affichage graphique disponible :

```bash
godot --path . --rendering-method gl_compatibility --script res://tools/bake_static_art.gd
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/baked_art_tests.gd
```

Conserver `mipmaps/generate=true`, `process/fix_alpha_border=false` et `process/premult_alpha=false` dans les fichiers `.png.import` des sprites précalculés. Les PNG du viewport contiennent déjà leurs couleurs prémultipliées ; le matériau `BLEND_MODE_PREMULT_ALPHA` assure leur mélange à l’exécution.

## Mesures et limites

La galerie mesure quatre scènes après trente images d’échauffement, sur quatre-vingt-dix intervalles entre images. Elle rapporte médiane, 95e percentile, appels de dessin et mémoire vidéo signalée par Godot. Le matériel de mesure est Linux x86_64 avec X11 et Mesa llvmpipe. Ce sont des observations de l’hôte, pas une mesure de FPS sur Raspberry Pi.

Le rapport compare la version précédente au pack ARM64 final chargé par Godot sur l’hôte. Le contrôle avant publication exige, pour ces quatre vues, une médiane et un 95e percentile ne dépassant pas 1,30 fois la référence ; un écart supérieur doit être analysé avant livraison. Cette marge couvre la variabilité de l’hôte et ne garantit pas le comportement sur d’autres appareils. Les sprites consomment davantage de mémoire que les primitives seules ; cette contrepartie est chiffrée dans le rapport.

[Résultats et mesures](../tests/graphics_0.26.0_results/summary.json). L’exécution native Windows et ARM64 sur le matériel cible, la manette physique et le son restent à vérifier.
