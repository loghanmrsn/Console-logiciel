# Archive complète Console CIEL 0.5.0

[Télécharger le projet complet](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.5.0.zip). Le ZIP regroupe les sources, ressources, documentation, outils, tests et la livraison Windows courante sous **console-ciel/**.

Après **Extraire tout**, ouvrir :

- **Le logiciel Windows** : `console-ciel/builds/windows-x86_64-bibliotheque-0.5.0/Console_CIEL.exe`. Godot n’est pas nécessaire pour jouer. Garder l’aide, les licences et **images_profil/** à côté de l’exécutable.
- **Les sources** : importer `console-ciel/project.godot` dans Godot standard **4.6.3 stable**, version exacte `4.6.3.stable.official.7d41c59c4`. Le preset Raspberry Pi ARM64 est conservé.
- **Les photos personnelles** : en export, les déposer dans le dossier **images_profil/** voisin de l’EXE ; en édition Godot, utiliser `console-ciel/images_profil/`. Ouvrir **Profil → Modifier → Mes images → Actualiser les images**. [Guide du profil et du clavier](PROFILS_ET_CLAVIER.md).
- **La bibliothèque et les paramètres** : [guide de la version 0.5.0](BIBLIOTHEQUE_ET_THEMES.md), avec les prix des emplacements Test et les styles/couleurs.
- **Les profils et leur clavier** : `docs/screenshots/profils_0.4.2/` et `tests/profils_0.4.2_results/` conservent la recette de leur introduction ; les rapports de livraison distinguent les contrôles courants.
- **L’inventaire de l’archive** : `CONTENU_ARCHIVE.json` contient chemins, tailles et SHA-256 de chaque fichier inclus.

Les dossiers réservés aux caches, les modèles Godot téléchargeables, les secrets, les données personnelles et les ZIP imbriqués sont exclus. Les notices de licences des polices intégrées au moteur sont incluses ; aucune police du PC n’est nécessaire.

Les livraisons Windows **0.4.0**, **0.4.1** et **0.4.2** restent conservées séparément dans le dépôt GitHub. L’archive complète courante inclut seulement le binaire **0.5.0**, pour éviter de redistribuer plusieurs copies du moteur. Les liens historiques vers les anciens ZIP se consultent sur GitHub.

Pour refaire cet assemblage, depuis `console-ciel/`, après un export vérifié dans le dossier indiqué :

```sh
python3 tools/package_complete.py --windows-directory builds/windows-x86_64-bibliotheque-0.5.0 --current-windows-only
```

Le programme vérifie les CRC, les SHA-256 des entrées et leur correspondance aux sources avant de publier le ZIP. Il ne reconstruit pas les exécutables. Le rapport externe `builds/Console_CIEL_Projet_Complet_0.5.0.verification.json` décrit la taille, l’empreinte finale et chaque fichier inclus.

L’export Windows utilise les modèles officiels. Les essais du pack compilé et les captures sont effectués sous Linux ; le double-clic Windows reste à tester sur un PC Windows.
