# Archive complète Console CIEL 0.4.0

`Console_CIEL_Projet_Complet_0.4.0.zip` rassemble les fichiers du projet sous le dossier **console-ciel/**, en conservant leurs chemins. Aucun nouvel export n'est réalisé pendant cet assemblage.

Après extraction :

- **Jouer sous Windows x86_64** : lancer `console-ciel/builds/windows-x86_64-refonte-0.4.0/Console_CIEL.exe`. Conserver tous les fichiers de ce dossier, notamment son `LIRE_MOI.txt` et les licences. Aucun Godot à installer pour jouer.
- **Ouvrir les sources** : importer `console-ciel/project.godot` dans Godot standard **4.6.3 stable**, version officielle `4.6.3.stable.official.7d41c59c4`. Les modèles exacts doivent être installés pour refaire un export. Le preset Pi ARM64 est conservé.
- **Voir les captures et la recette** : `docs/screenshots/refonte/`, `docs/REFONTE_GRAPHIQUE.md`, `tests/refonte_results/`.
- **Consulter l'inventaire** : `CONTENU_ARCHIVE.json` liste chaque fichier source inclus, sa taille et son SHA-256.

Les scènes, scripts, ressources, sons, images, données, thèmes, UID, tests, outils et documentation sont inclus. Les polices de secours sont intégrées à Godot et à son exécutable ; leurs notices sont dans `assets/licenses/`. Aucun installateur/autostart distinct n'existe dans ce projet : les outils disponibles et les procédures d'installation/export sont inclus, sans inventer ce livrable.

Les anciens binaires Windows 0.3.0 et 0.3.1 sont également conservés dans leurs dossiers d'origine `builds/windows-x86_64/` et `builds/windows-x86_64-finition-0.3.1/`, conformément au périmètre complet. **La version à tester est celle de `windows-x86_64-refonte-0.4.0`.** Aucun ZIP précédent n'est imbriqué. Les liens historiques du README vers des archives ZIP ne désignent donc pas des fichiers présents dans cette archive complète ; utiliser directement les sources ou le dossier Windows extrait.

Sont exclus : cache `.godot`, caches Python, dossiers d'exécution temporaires `.runtime-*`, fichiers temporaires, archives ZIP/TPZ, secrets et sauvegardes personnelles. Les dossiers réservés à l'environnement (`.aws`, `.codex`, `.agents`, `.git` vide) ne sont pas des sources du projet et ne sont pas distribués. Les comptes rendus de test isolés sont conservés. Aucune sauvegarde de joueur normal n'est fournie.

Pour reproduire cet assemblage, depuis le projet extrait :

```sh
python3 tools/package_complete.py
```

Le programme lit la version dans `project.godot` et crée l'archive correspondante dans `builds/`. Le paramètre facultatif `--windows-directory builds/<dossier>` désigne une autre livraison Windows existante. Il vérifie tous les CRC ZIP, compare les SHA-256 de chaque entrée aux sources puis publie la sortie. Le rapport externe `builds/Console_CIEL_Projet_Complet_0.4.0.verification.json` contient la taille et le SHA-256 de l'archive finale. Un échec conserve l'archive précédente.

L'application Windows demeure non signée. Les captures et tests du projet ont été réalisés sous Linux ; aucun lancement Windows natif ou essai matériel Raspberry Pi n'est ajouté par cet archivage.
