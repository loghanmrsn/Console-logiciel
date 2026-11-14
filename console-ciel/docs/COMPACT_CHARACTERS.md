# Petits personnages et accessoires — 0.37.0

Dans **Mon personnage 3D**, le sélecteur au-dessus de l’aperçu propose **Petit humain**, **Petit lapin** et **Silhouette classique**. Les nouveaux profils commencent avec le petit humain. Les profils qui possédaient déjà un personnage reprennent leur silhouette classique, leurs couleurs et leurs achats, sans réécriture automatique du fichier.

Les deux nouvelles silhouettes s’inspirent des images fournies : grande tête arrondie, corps court, yeux expressifs, cheveux bruns ou longues oreilles. Ce sont des modèles articulés en vraie 3D, interprétés dans un style de dessin animé. La silhouette et la taille restent fixes. Le bouton **Essayer le lapin à écharpe** propose un lapin ivoire habillé de blanc avec une écharpe rouge, sans aucun achat requis.

Le pelage du lapin propose ivoire, sable, gris, cacao et anthracite. Les yeux, le sourire, les couleurs des habits et les couvre-chefs restent personnalisables. Les coiffures sont réservées aux modèles humains ; les achats existants restent conservés lorsqu’on choisit le lapin. Les habits sont adaptés à chaque morphologie.

Le dressing et la boutique possèdent une catégorie **Accessoires** :

| Accessoire | Déblocage | Couleurs |
|---|---|---|
| Écharpe d’aventure | Gratuit | Palette complète |
| Petit sac à dos avec poche | 45 points de jeu | Palette complète |
| Lunettes rondes | 35 points de jeu | Palette complète |

Un accessoire à la fois. L’essayage ne débite rien ; l’achat et l’enregistrement sont explicites. Aucun argent réel ni marque. Le même accessoire peut être porté par les trois modèles sans rachat. Le personnage choisi apparaît dans le quartier 3D et les scènes existantes qui utilisent l’avatar 3D.

## Production et compatibilité

`tools/build_compact_characters.py` lit `art_sources/character_modular.blend` sans le modifier. Les modèles humains compacts et lapins possèdent leur propre pose de référence dans Blender, avec la garde-robe adaptée. Le visage compact est reconstruit : tête ronde, yeux et reflets, petit nez et trois sourires. Le squelette conserve treize os, les clips de marche et de repos, ainsi que la remise à zéro des poses avant chaque échantillonnage.

```bash
blender -b -t 4 --python tools/build_compact_characters.py -- --project .
godot --headless --path . --import
```

Les sorties sont dans `assets/character3d/compact/`. Le manifeste contient la provenance, les empreintes, le nombre de triangles de toutes les variantes et la licence CC0-1.0. Aucune image de référence n’est copiée dans les textures. Le modèle original reste dans le dépôt.

Godot reste en **4.6.3 officiel, Compatibility**. Les modèles sont chargés à la demande. Le budget de la combinaison visible reste inférieur à 40 000 triangles. L’aperçu immobile ne redessine pas en continu ; les cartes de boutique utilisent des images précalculées. La capsule de gameplay reste de 1,70 m de haut et 0,23 m de rayon pour tous les modèles ; les vêtements et les oreilles n’ajoutent aucune collision. La hauteur visuelle des personnages compacts est volontairement plus petite.

## Recommandations consultées

Le skill **Game Asset Production** du plugin Game Development Studio a été consulté pour la spécification, la provenance et la vérification. Sa commande `game-dev` n’est pas installée dans cet environnement : aucune exécution de cette CLI ni aucun fournisseur payant n’est revendiqué. La production utilise le Blender local et les tests du projet.

Les instructions [Create Game Assets](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/create-game-assets/SKILL.md), [Godot Animation](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-animation/SKILL.md) et [Save Systems](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/save-systems/SKILL.md) ont été consultées depuis GitHub : silhouette cohérente, pose de référence, contrôle des animations, migration additive et sauvegarde atomique. Aucun skill n’est installé dans le dépôt. Les API propres à Godot 4.7 ne sont pas utilisées.

## Vérification

`tests/compact_characters_tests.gd` vérifie le choix des personnages, les couleurs, la reprise des anciens profils, les achats, l’échec disque, les accessoires, la stabilité de la marche, les collisions fixes, le petit écran et la présence du lapin dans le quartier. Les rendus natifs et les contrôles clavier/manette simulée sont complétés par les suites existantes. Les ressources des packs Windows et ARM64 sont chargées avec le moteur Linux ; cela ne remplace pas une exécution sur le matériel cible.

Les résultats courants sont dans `tests/compact_0.37.0_results/summary.json`. Le lancement Windows, le Raspberry Pi et la manette physique restent à vérifier sur le matériel réel.
