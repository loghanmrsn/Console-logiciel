# Personnages et quartier 3D — 0.36.0

Depuis l’accueil de la console, **Explorer le quartier et le lycée en 3D** ouvre un parcours jouable à la troisième personne. Le personnage reprend l’apparence enregistrée dans le dressing. Les cinq chapitres de l’enquête existante conservent leur fonctionnement et leurs décors 2D ; ce parcours constitue une nouvelle partie du jeu en vraie 3D.

Le parvis comprend le lycée, la poste et son enveloppe, le fleuriste et ses plantations, une bibliothèque avec boîte à livres, des bancs, des arbres et une fontaine. L’accueil et l’atelier sont des intérieurs en volume, aux murs blancs. Leur disposition est une interprétation conçue pour le jeu, pas un relevé architectural du lycée.

Approcher un objet affiche son action. Interagir ouvre une conversation ou un choix : entrer/sortir, parler à la surveillante, consulter les livres, commander la pompe ou répondre aux deux diagnostics du poste informatique et de la baie réseau. Ces exercices fournissent une explication sans modifier les points ni la progression des chapitres.

La surveillante blonde porte un pull ample. Elle peut accompagner le joueur par l’escalier droit : deux personnages animés, trajet de 2,7 secondes, contrôle restauré à l’arrivée. Avec la réduction des animations, le trajet est immédiat. Échap ouvre une pause, ou ferme la conversation en cours. Les menus fonctionnent au clavier et à la manette.

Le modèle humain est retravaillé dans Blender : silhouette adulte, épaules inclinées, taille et bassin, mains avec doigts et visage sculpté. Les habits comportent coutures, revers et coupes ajustées. La tenue Madison reprend la référence fournie (robe grise, manches séparées, chignon et escarpins), sans marque ni modèle commercial. Le rendu reste stylisé. La capsule du joueur reste de 1,70 m × 0,23 m de rayon quelle que soit sa tenue. La marche suit le déplacement réellement obtenu après collision ; le personnage tourne progressivement sans incliner tout son corps. Une respiration discrète anime le repos dans le parcours 3D.

## Sources et régénération

- `tools/build_character_3d.py` et `art_sources/character_modular.blend` : personnage modulaire, même squelette à treize os.
- `tools/build_campus_3d.py` : géométrie originale du quartier, de l’accueil et de l’atelier.
- `assets/campus3d/manifest.json` : unités en mètres, modèles GLB, empreintes, nombres de triangles, collisions simplifiées et repères d’interaction.
- `scripts/campus3d/` : monde, caméra, interactions et matières ; `scripts/ui/campus_3d_panel.gd` : interface et dialogues.

```bash
blender -b -t 4 --python tools/build_campus_3d.py -- --project .
godot --headless --path . --import
godot --headless --path . --script res://tests/campus_3d_tests.gd
```

Godot **4.6.3.stable.official.7d41c59c4**, rendu **Compatibility**. Un seul décor est chargé à la fois. Géométrie statique regroupée par matériau, collisions en boîtes, caméra `SpringArm3D`, interpolation du joueur, résolution 3D plafonnée à 960 pixels de large ; l’interface garde la résolution native. Les dialogues et la pause suspendent le monde et son rendu continu. Les aperçus immobiles du dressing continuent à être rendus à la demande. Aucun effet réservé à Forward+ n’est requis.

## Skills consultés à distance

Révision consultée : `c6ca6c41c839b68319ffc08430b99ab768debc32` du [routeur GameDev](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/router/SKILL.md). Scènes et matériaux : `godot-3d-essentials` ; collisions : `godot-physics` ; caméra : `camera-systems` ; personnages et clips : `godot-animation` ; production : `create-game-assets` ; interactions : `dialogue-systems` ; interface : `godot-ui-control` et `game-ui-ux` ; commandes : `input-systems` ; validation : `godot-gdscript-headless-testing` et `godot-export`.

Ces instructions ont été lues depuis GitHub. Aucun skill n’a été installé dans le projet. Les API 4.7 spécifiques sont exclues ; les services et sauvegardes existants sont réutilisés.

## Vérification

Le rapport courant est dans `tests/campus3d_0.36.0_results/summary.json`, avec des captures natives dans `docs/screenshots/campus3d_0.36.0/`. Les suites vérifient le parcours, les collisions, l’apparence, la pause, les choix, la réduction des animations, le petit écran, le clavier et un joystick simulé. Les packs Windows et ARM64 sont chargés par le moteur Linux pour vérifier leurs ressources : cela ne constitue pas une exécution native sur ces plateformes.

Les performances sur Raspberry Pi, le lancement Windows, le son et la manette physique restent à vérifier sur le matériel cible. Aucune promesse de fréquence d’images n’est déduite du rendu logiciel Mesa utilisé ici.
