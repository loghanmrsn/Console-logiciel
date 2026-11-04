# Salles et lycée — rendu 0.28.0

Les cinq ateliers et le laboratoire réseau conservent leurs portes, missions et géométries physiques. Le mobilier est remplacé par des rendus de modèles originaux créés dans Blender : plateaux en bois, pieds métalliques, sièges rembourrés, claviers, ordinateurs, imprimante 3D, baies, platines de câblage, instruments, tiroirs, banc hydraulique et mezzanine. Les volumes, les biseaux, les matières et les ombres sur les objets proviennent de ces modèles.

La façade reprend le bâtiment bas et asymétrique de Louise Michel : entrée à gauche, aile claire, menuiseries en retrait, volets roulants, poignées, seuils, descentes d’eau, horloge et couvertines. Les photographies de la visite servent de référence et ne sont pas incluses. Le logo déjà fourni conserve ses droits réservés et est ajouté séparément.

Les murs intérieurs restent blancs. Des textures légères donnent une matière aux sols, et des dégradés adoucissent les murs et la lumière des fenêtres. Les ombres de contact au sol restent bornées et progressives pour éviter de voir les rectangles des images. Le personnage a une échelle visuelle adaptée aux meubles des salles ; ses pieds, sa vitesse et son collider restent inchangés. L’échelle extérieure est rétablie en sortant.

Le jeu conserve son fonctionnement 2D : les modèles sont rendus à l’avance. Il n’y a ni visite intégrée, ni serveur d’images, ni calcul 3D permanent pendant le déplacement. Le catalogue relie chaque image à son empreinte physique et à son origine de dessin. Les images Blender utilisent un alpha droit ; les anciens précalculs Godot conservent leur alpha prémultiplié.

Les 23 empreintes de mobilier et la façade sont encodées en WebP sans perte. Le générateur vérifie que chaque pixel visible et chaque valeur alpha restent identiques au rendu PNG. Les sources, les dimensions, les empreintes SHA-256, les versions et le résultat de la vérification sont conservés dans `assets/art/school_realism/manifest.json`. Les dessins originaux sont CC0 ; voir [les licences](../assets/LICENSES.md).

Le CLI `game-dev` du plugin de production n’était pas installé. Les modèles et les rendus ont donc été réalisés directement avec Blender 4.3.2, puis importés et vérifiés avec Godot 4.6.3. Aucun fournisseur payant ni téléchargement de modèle n’a été utilisé. Il ne s’agit pas d’un paquet GLB certifié par ce CLI.

## Régénération

Depuis le dossier `console-ciel`, Blender produit les PNG et leur catalogue :

```bash
blender -b -t 6 --python tools/render_school_assets.py -- --project .
```

Copier ensuite tous les PNG et `manifest.json` de `assets/art/school_realism/` dans un dossier de travail distinct, par exemple `/tmp/ciel-renders`. Encoder les rendus depuis ce dossier :

```bash
godot --headless --path . --script res://tools/pack_school_renders.gd -- --source=/tmp/ciel-renders
godot --headless --path . --import
```

Après la réussite des 24 comparaisons sans perte, conserver les PNG originaux dans le dossier de travail et retirer leurs copies et `.png.import` du projet. Dans les `.webp.import`, conserver `mipmaps/generate=true`, `process/fix_alpha_border=false` et `process/premult_alpha=false`. Régénérer ensuite le catalogue de décors avec un affichage graphique disponible :

```bash
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3_es --script res://tools/bake_static_art.gd
godot --headless --path . --import
godot --headless --path . --script res://tests/school_realism_asset_tests.gd
```

Le jeu doit être contrôlé au niveau des portes, des pieds du mobilier, des contours transparents et du tri du personnage devant et derrière les équipements. Les résultats de livraison et les limites des essais matériels figurent dans [DELIVERY.md](DELIVERY.md).

## Décors de ville

La mairie reçoit deux mâts avec les drapeaux français et européen (douze étoiles). La bibliothèque possède une boîte à livres garnie et un banc ; la médiathèque, un panneau avec une bobine de film et un banc. Ces éléments restent sur les côtés des parvis, sans bloquer les portes ni les rues. Le bassin de la fontaine est modelé en pierre, avec une vasque supérieure et une surface d’eau ; Godot ajoute les jets et les ondulations. Pause et animations réduites immobilisent l’eau.

Les cinq rendus supplémentaires suivent la même chaîne sans perte. Pour les régénérer : `blender -b -t 6 --python tools/render_town_details.py -- --project .`. Copier les PNG et le catalogue dans un dossier externe, puis utiliser le compresseur avec `--source=/chemin/rendus-ville --destination=res://assets/art/town_details/`. Retirer les copies PNG après vérification, importer les WebP avec les mêmes réglages que ceux du lycée, puis régénérer le cache. Le catalogue `assets/art/town_details/manifest.json` conserve les empreintes des deux générateurs.
