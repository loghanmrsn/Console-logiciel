# Archives complètes Console CIEL 0.18.0

Chaque ZIP réunit les sources, ressources, documentation, outils, tests et le logiciel de sa plateforme, sous **console-ciel/**. Choisir l’archive correspondant à son appareil :

| Plateforme | Projet complet | Logiciel après extraction |
|---|---|---|
| Windows x86_64 | [Projet complet Windows](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Windows_0.18.0.zip) | `console-ciel/builds/windows-x86_64-ctf-0.18.0/Console_CIEL.exe` |
| Raspberry Pi 4 ARM64 | [Projet complet Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.18.0.zip) | `console-ciel/builds/linux-arm64-raspberry-pi-0.18.0/Lancer_Console_CIEL.sh` |

Après extraction complète :

- **Jouer sur Windows** : double-cliquer sur **Console_CIEL.exe** dans le dossier indiqué. Garder l’aide, les licences et **images_profil/** à côté.
- **Jouer sur le Pi 4 64 bits avec bureau** : ouvrir un terminal dans le dossier indiqué, puis lancer `bash ./Lancer_Console_CIEL.sh`. Le véritable exécutable est **console-ciel.arm64**. Godot n’est pas nécessaire pour jouer sur les deux plateformes.
- **Ouvrir les sources** : importer `console-ciel/project.godot` dans Godot standard **4.6.3.stable.official.7d41c59c4**, rendu Compatibility.
- **Ajouter des photos** : utiliser **images_profil/** à côté du programme ; en édition Godot, utiliser `console-ciel/images_profil/`. Puis **Profil → Modifier → Mes images → Actualiser les images**.
- **Consulter l’inventaire** : `CONTENU_ARCHIVE.json` donne les chemins, tailles et SHA-256 des fichiers inclus. Les rapports externes [Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.18.0.verification.json) et [Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.18.0.verification.json) donnent les empreintes finales des ZIP.

Le contenu jouable **0.18.0** est identique : cinq chapitres, treize missions, dont Python, HTML et Markdown dans l’atelier du code. Les treize missions rapportent 650 points, puis les deux récompenses du matin ajoutent 100 points, soit 750 au maximum par profil ; chaque jeu Test coûte 200 points et reste un jeu en préparation. Le profil, les thèmes, les photos, le tableau de missions et les repères masqués sont conservés. Le parcours continue après la nuit : petit déjeuner, machine à café à réparer, sac à dos en chambre 206 et bus vers le hall du CTF **sudo hack**. Ses cinq défis seront ajoutés plus tard. [Guide de l’hôtel](HOTEL.md), [guide Windows](WINDOWS.md), [guide Raspberry Pi](RASPBERRY_PI.md), [enquête](ENQUETE.md) et [bibliothèque](BIBLIOTHEQUE_ET_THEMES.md).

Chaque archive complète inclut seulement le **binaire courant de sa plateforme**. Les autres ZIP et les anciennes livraisons restent conservés séparément sur GitHub, sans être imbriqués dans les nouvelles archives. Les caches, modèles Godot téléchargeables, secrets et données personnelles sont exclus. Les sauvegardes des joueurs ne sont pas distribuées. Les licences des ressources et des polices intégrées au moteur restent incluses.

Pour refaire l’assemblage après avoir préparé et vérifié la livraison, depuis `console-ciel/` :

```sh
# Windows : l’API permet de nommer explicitement le projet complet.
python3 - <<'PYTHON'
from pathlib import Path
from tools.package_complete import create_archive
create_archive(Path('.'), Path('builds/Console_CIEL_Projet_Complet_Windows_0.18.0.zip'),
               'builds/windows-x86_64-ctf-0.18.0', current_windows_only=True)
PYTHON

# Raspberry Pi :
python3 tools/package_linux_complete.py \
  --linux-directory builds/linux-arm64-raspberry-pi-0.18.0 \
  --output builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.18.0.zip
```

Ces outils vérifient l’archive ; ils ne reconstruisent pas les binaires. Les rapports [Windows portable](../builds/Console_CIEL_Windows_x86_64_ctf_0.18.0.verification.json) et [ARM64 portable](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.18.0.verification.json) décrivent séparément les exports. [Résultats et portée des vérifications](DELIVERY.md). Le lancement natif, l’affichage, le son et la manette restent à essayer sur les appareils destinataires.

# Livraison Windows conservée — archive complète 0.6.1

[Télécharger le projet complet](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.6.1.zip). Le ZIP regroupe les sources, ressources, documentation, outils, tests et la livraison Windows courante sous **console-ciel/**.

Après **Extraire tout**, ouvrir :

- **Le logiciel Windows** : `console-ciel/builds/windows-x86_64-confort-0.6.1/Console_CIEL.exe`. Godot n’est pas nécessaire pour jouer. Garder l’aide, les licences et **images_profil/** à côté de l’exécutable.
- **Les sources** : importer `console-ciel/project.godot` dans Godot standard **4.6.3 stable**, version exacte `4.6.3.stable.official.7d41c59c4`. Le preset Raspberry Pi ARM64 est conservé.
- **Les photos personnelles** : en export, les déposer dans le dossier **images_profil/** voisin de l’EXE ; en édition Godot, utiliser `console-ciel/images_profil/`. Ouvrir **Profil → Modifier → Mes images → Actualiser les images**. [Guide du profil et du clavier](PROFILS_ET_CLAVIER.md).
- **L’enquête et son ascenseur** : [parcours courant](ENQUETE.md), six missions en deux chapitres et tableau de missions dépliable par T ou le bouton de face haut. Les repères des missions terminées disparaissent après sauvegarde ; l’ascenseur reste utilisable.
- **La bibliothèque et les paramètres** : [guide actualisé](BIBLIOTHEQUE_ET_THEMES.md), avec le profil en haut à gauche, quatre onglets centrés et les emplacements Test à 200 points chacun, ainsi que les styles/couleurs.
- **Les profils et leur clavier** : `docs/screenshots/profils_0.4.2/` et `tests/profils_0.4.2_results/` conservent la recette de leur introduction ; les rapports de livraison distinguent les contrôles courants.
- **L’inventaire de l’archive** : `CONTENU_ARCHIVE.json` contient chemins, tailles et SHA-256 de chaque fichier inclus.

Les dossiers réservés aux caches, les modèles Godot téléchargeables, les secrets, les données personnelles et les ZIP imbriqués sont exclus. Les notices de licences des polices intégrées au moteur sont incluses ; aucune police du PC n’est nécessaire.

Les livraisons Windows **0.4.0**, **0.4.1**, **0.4.2**, **0.5.0** et **0.6.0** restent conservées séparément dans le dépôt GitHub. L’archive complète courante inclut seulement le binaire **0.6.1**, pour éviter de redistribuer plusieurs copies du moteur. Les liens historiques vers les anciens ZIP se consultent sur GitHub.

Pour refaire cet assemblage, depuis `console-ciel/`, après un export vérifié dans le dossier indiqué :

```sh
python3 tools/package_complete.py --windows-directory builds/windows-x86_64-confort-0.6.1 --current-windows-only
```

Le programme vérifie les CRC, les SHA-256 des entrées et leur correspondance aux sources avant de publier le ZIP. Il ne reconstruit pas les exécutables. Le rapport externe `builds/Console_CIEL_Projet_Complet_0.6.1.verification.json` décrit la taille, l’empreinte finale et chaque fichier inclus.

La recette **0.6.1** compte **11 844 assertions source**, **65 de persistance**, **58 contrôles de rendu X11** avec 8 captures, **6 547 assertions du pack compilé**, **18 contrats Windows** et **27 contrôles de packaging**, zéro échec. [Résumé courant](../tests/confort_0.6.1_results/summary.json) et [liens des huit captures réelles](DELIVERY.md). Les résultats historiques restent inclus avec leurs versions et dates.

L’export Windows utilise les modèles officiels. Les essais du pack compilé et les captures sont effectués sous Linux ; le double-clic Windows reste à tester sur un PC Windows.

La version 0.11.0 ajoute les trois livres animés du coin ressources (chapitre 3) et le chapitre 4 : pare-feu, conflit IPv4 et masque /26. L’ascenseur propose Descendre d’étage, Monter d’étage et Retour au menu ; Échap reste dans la pièce. Les anciennes sauvegardes sont conservées.

Le **chapitre 5** reste disponible : portable → **Y aller** → labyrinthe avec inscriptions murales et terminal simulé. Une seule mission est affichée **???** ; le clavier virtuel apparaît pour les identifiants, les mots de passe et les commandes. Les quatre premiers chapitres conservent trois missions chacun. La connexion et la reprise sont sauvegardées. Aucune commande n’est exécutée sur le système hôte.

La version **0.11.0** prolonge l’exploration après le chapitre 5 : descente jusqu’au premier niveau, porte de sortie en bas à gauche, cour et immeuble d’en face. Le second bâtiment devient un hôtel doté d’un grand hall de **6 400 × 4 200** et de salles dédiées au parcours de la chambre 206. La carte en haut à gauche affiche la position et la sortie ; **→** l’affiche ou la masque, **D / ZQSD ou le joystick** restent disponibles pour marcher. La réparation de l’hôtel prolonge le récit ; le plafond des récompenses de l’enquête reste à **treize missions et 650 points**. Les portes enregistrent les zones avant chaque déplacement.

La version **0.11.0** ajoute le parcours de l’hôtel : réservation, panne informatique, escaliers et chambre **206**. [Guide de l’hôtel](HOTEL.md).

Les modèles et collisions revus dans la version 0.13.0 sont conservés. Le personnage passe devant ou derrière les objets selon sa position. Dans la cour, un passage piéton, des feux et des voitures lentes encadrent la traversée : départ au vert sans frais ; traversée achevée au rouge sans choc, **200 points** ; collision, retour au trottoir de départ en gardant la progression. Les points disponibles paient la pénalité, puis une dette conserve le reste et se rembourse sur les prochains gains. [Règles et vérifications](TRAFFIC.md).

La version **0.14.0** a enrichi les deux épreuves existantes de l’hôtel : local informatique, cartes du diagnostic, buffet, machine à café et panneau de câblage. Les trois nouveaux meubles ont leur collision. La direction artistique, la progression, les points et les pénalités restent ceux du projet. [Détails du rendu et des contrôles](HOTEL_VISUAL.md).

La version **0.15.0** a ajouté six personnages solides et des discussions à plusieurs pages : première salle, dernier étage, buffet, entrée de l’hôtel, passage piéton et palier fermé du premier étage de l’hôtel. Les explications suivent la progression sans modifier les missions ni les points. **Espace / face bas** ouvre la discussion ; **Échap / face droite** la ferme. [Rencontres et commandes](PNJ.md).

La version **0.16.0** a affiné les six PNJ : coiffures et tenues distinctes, regards, geste d’accueil, portraits rapprochés et bulles portant leur nom. La discussion fonctionne depuis les côtés libres, avec de courts fondus, un portrait et des boutons fixes, un texte défilant et un bouton de fermeture directe. Espace avance aussi les pages ; les obstacles et les sauvegardes sont conservés. [Visuel et commandes](PNJ.md).

La version **0.18.0** propose le bouton **Dev · Super administrateur** : profil séparé, treize défis, épreuves de l’hôtel et cinq postes du CTF validés, étages accessibles et 1 000 points initiaux. La réutilisation conserve sa sauvegarde et les autres profils restent indépendants. [Utiliser Dev](DEV.md).

Le dossier **solution/** est également inclus à côté de **console-ciel/** dans les deux ZIP complets. Sa fiche donne toutes les bonnes réponses et affiche les captures correspondantes, présentes dans les sources.
