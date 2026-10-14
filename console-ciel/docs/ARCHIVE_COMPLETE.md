# Archive complète Console CIEL 0.6.1 — Raspberry Pi

[Télécharger le projet complet Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.6.1.zip). Le ZIP réunit les sources, ressources, documentation, outils, tests et le logiciel **Linux ARM64 courant**, sous **console-ciel/**.

Après extraction complète :

- **Jouer sur le Pi 4 64 bits** : ouvrir un terminal dans `console-ciel/builds/linux-arm64-raspberry-pi-0.6.1/` puis lancer `bash ./Lancer_Console_CIEL.sh`. Le véritable exécutable est **console-ciel.arm64**, avec pack intégré ; Godot n’est pas nécessaire pour jouer.
- **Ouvrir les sources** : importer `console-ciel/project.godot` dans Godot standard **4.6.3.stable.official.7d41c59c4**, rendu Compatibility.
- **Ajouter des photos** : utiliser **images_profil/** à côté du binaire ARM64 ; en édition Godot, utiliser `console-ciel/images_profil/`. Puis **Profil → Personnaliser → Mes images → Actualiser les images**.
- **Consulter l’inventaire** : `CONTENU_ARCHIVE.json` donne les chemins, tailles et SHA-256 des fichiers inclus ; le [rapport externe Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.6.1.verification.json) donne l’empreinte finale du ZIP.

Le contenu jouable reste celui de la version **0.6.1** : deux chapitres, six missions, ascenseur, profil en haut à gauche, jeux Test à 200 points, panneau de missions et repères masqués après réussite. [Guide Raspberry Pi](RASPBERRY_PI.md), [enquête](ENQUETE.md) et [bibliothèque](BIBLIOTHEQUE_ET_THEMES.md).

Ce projet complet inclut seulement le binaire **ARM64 0.6.1**. Les ZIP Windows et les autres livraisons restent conservés séparément sur GitHub, sans être imbriqués dans cette archive. Les caches, modèles Godot téléchargeables, secrets et données personnelles sont exclus. Les sauvegardes des joueurs ne sont pas distribuées. Les licences des ressources et des polices intégrées au moteur restent incluses.

Pour refaire l’assemblage après avoir préparé et vérifié la livraison ARM64, depuis `console-ciel/` :

```sh
python3 tools/package_linux_complete.py \
  --linux-directory builds/linux-arm64-raspberry-pi-0.6.1 \
  --output builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.6.1.zip
```

Le programme assemble et vérifie l’archive ; il ne reconstruit pas le binaire. Le [rapport ARM64](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.6.1.verification.json) décrit séparément l’export portable et son intégrité. [Bilan des vérifications](DELIVERY.md). Le lancement natif, l’affichage, le son et la manette restent à essayer sur votre **Pi 4 avec Raspberry Pi OS 64 bits et bureau**.

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
