# Ressources, crédits et redistribution

- **Loghan** : logiciel du projet scolaire ; **binôme — nom à compléter** : construction et assemblage. Établissement et promotion à compléter.
- **Graphismes et icônes locaux originaux** (`console.svg`, dessins GDScript d'avatars, enquête, cartes et interface) : créations de cette première version ; mise à disposition sous **CC0 1.0**. Aucun logo, capture ou ressource Apple repris. Voir `licenses/CC0.txt`.
- **Collection atelier 0.4.0** (`art/world/`, `art/character/`, `art/icons/`) : **36 fichiers SVG originaux, CC0 1.0**, dessinés pour cette application avec `tools/generate_art.py`. Sols, murs, mobilier, états de porte/écran, personnage (quatre directions, trois poses) et cinq pictogrammes. Aucune ressource tierce téléchargée. Les captures dans `docs/screenshots/refonte/` proviennent du jeu Godot exécuté ; ce ne sont pas des illustrations de maquette.
- **Chapitre 2 — 0.6.0** (`art/world/`) : **7 SVG originaux, CC0 1.0**, dessinés pour cette application : ascenseur verrouillé et prêt, sol et murs de la salle réseau, baie réseau, poste d’adressage et borne Wi-Fi. La collection comprend désormais **43 SVG** ; aucune image tierce n’a été intégrée.
- **Chapitre 3 — 0.7.0** (`art/world/code_*.svg`) : **5 SVG originaux, CC0 1.0**, créés pour l’atelier du code : sol, murs et postes Python, HTML et Markdown. La collection complète compte **48 SVG**. Les mots et symboles des exercices sont affichés comme du texte, sans logo tiers.
- **PNJ — 0.16.0** (`scripts/game/npc_visual.gd`, `npc_speech_marker.gd`, portraits et bulles de dialogue) : dessins vectoriels originaux réalisés avec les primitives Godot, **CC0 1.0** pour les graphismes. Six coiffures, vêtements et accessoires ; aucune image externe, police supplémentaire ou ressource de fournisseur intégrée.
- **Sons WAV locaux originaux**, lorsqu'ils sont présents dans `assets/audio/` : synthèse créée pour cette première version ; **CC0 1.0**. Aucun extrait musical propriétaire. Voir `licenses/CC0.txt`.
- **Police** : police de secours intégrée au moteur Godot ; aucune police du PC requise ou téléchargée. Godot distribue notamment Noto Sans sous SIL Open Font License 1.1. Les licences intégrées du moteur sont reprises dans `licenses/GODOT_THIRD_PARTY.json` après extraction depuis le moteur exact.
- **Godot Engine 4.6.3** : licence **MIT**, texte dans `licenses/GODOT_MIT.txt`, composants tiers dans `licenses/GODOT_THIRD_PARTY.json` et textes de licences dans `licenses/GODOT_LICENSE_TEXTS.json`. Référence : https://godotengine.org/license/.

Les licences des ressources n'attribuent pas une licence globale au code scolaire : l'équipe pourra choisir cette licence ultérieurement. Conserver les notices Godot et tierces lors de la redistribution des exécutables.

Le logo fourni du lycée Louise Michel de Ruffec (`lycee/logo_louise_michel.jpg`) est exclu de CC0. Droits réservés à ses titulaires ; voir `lycee/NOTICE.md`.

- **Graphismes 0.26.0** : personnages, mobilier, façades, végétation et éléments d’interface redessinés localement en SVG/GDScript, CC0 pour ces créations originales. Les PNG de `art/baked/` sont des précalculs de ces dessins par le moteur Godot ; leurs sources et le générateur `tools/bake_static_art.gd` sont conservés. Les reproductions du logo du lycée dans la façade et les panneaux restent **exclues de CC0**, y compris dans les sprites précalculés. Leurs droits restent réservés aux titulaires du logo, selon `lycee/NOTICE.md`. Aucun modèle ou texture de fournisseur payant ajouté.

- **Salles et lycée 0.28.0** (`art/school_realism/`) : mobilier, instruments et façade modélisés localement dans Blender, puis rendus en images, **CC0 1.0** pour ces créations graphiques originales. Sources reproductibles : `tools/render_school_assets.py` et `tools/pack_school_renders.gd`. Compression WebP sans perte vérifiée sur les pixels visibles et l’alpha. Aucune photographie, modèle téléchargé ou texture de fournisseur intégrée. Le logo du lycée, ajouté séparément par Godot, reste exclu de CC0, y compris dans le précalcul de façade utilisé en ville.

- **Décors civiques 0.28.0** (`art/town_details/`) : drapeaux français et européen, boîte à livres, panneau de médiathèque et fontaine en pierre, modèles et rendus originaux **CC0 1.0**. Générateur `tools/render_town_details.py`, avec le dispositif de rendu du lycée. Aucun modèle ni photographie externe. L’eau est animée dans Godot.

- **Décors de ville 0.29.0** (`art/town_details/`) : 34 rendus à double résolution issus de modèles Blender originaux, **CC0 1.0**. Sources reproductibles : `tools/town_prop_models.py`, `tools/render_town_details.py`, catalogue des 40 bâtiments `data/town_forecourts.json`. Pierre, métal, bois, céramique et tissus procéduraux ; aucun modèle, photographie ou texture externe. Les animations d’eau sont tracées par `scripts/game/fountain_water.gd`.

- **Surveillante 0.30.0** : modèle Blender et neuf poses rendues originales, **CC0 1.0**, créés localement avec `tools/render_supervisor.py`. Source `art_sources/surveillante.blend`, atlas et provenance dans `art/supervisor/`. Aucun modèle, photographie ou fournisseur externe.

- **Personnage modulaire 0.32.0** (`character3d/character.glb`, `art_sources/character_modular.blend`) : modèle, coiffures, vêtements, chaussures et animations originaux créés dans Blender, **CC0 1.0** pour les créations graphiques. Générateur `tools/build_character_3d.py`, provenance et empreintes dans `character3d/manifest.json`. Squelette unique, aucun modèle téléchargé, texture photographique, marque ni logo intégré. Les gestes supplémentaires de démarche sont animés par le moteur.

- **Matières et boutique 0.33.0** : huit cartes de détail procédurales originales (`character3d/materials/`), créées avec `tools/generate_character_materials.py`, et trente vignettes du modèle original rendues par Godot (`character3d/shop/`), générées avec `tools/bake_wardrobe_thumbnails.gd`. **CC0 1.0** pour ces graphismes originaux ; aucun modèle, photographie, logo ou texture externe. Les manifestes conservent les sources, paramètres et empreintes.

Personnage et tenue 0.35.0 : géométrie et vêtements originaux créés localement dans Blender, CC0-1.0 pour les fichiers créés. La photo de référence fournie par l’utilisateur sert à guider la coupe ; elle n’est pas intégrée aux textures ni distribuée. La dénomination Madison indique l’inspiration, sans affiliation officielle. Voir `character3d/manifest.json`.

## Quartier et intérieurs 3D (0.36.0)

Géométries originales créées par script dans Blender 4.3.2 : `tools/build_campus_3d.py`, exportées dans `assets/campus3d/`. Aucun modèle commercial ni logo tiers. Sources, échelle, matériaux, collisions simples et empreintes sont consignés dans `assets/campus3d/manifest.json`. Mise à disposition CC0 comme les autres dessins originaux du projet.

## Personnages compacts et accessoires — 0.37.0

Les modèles de `character3d/compact/` sont des créations originales CC0-1.0 produites localement dans Blender à partir du personnage original du projet. Les deux images fournies par l’utilisateur servent de référence de proportions et de silhouette ; aucune texture ni géométrie tierce n’est copiée. Le générateur `tools/build_compact_characters.py` conserve la source adulte et exporte trois variantes, avec leurs empreintes et leur provenance dans `manifest.json`.
