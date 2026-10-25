# Console CIEL 0.4.2 — profils, images locales et clavier

L'éditeur de profil réunit le portrait, l'aperçu du pseudo et le clavier dans une même carte. Le pseudo conserve sa casse et accepte de **1 à 16 caractères**. L'aperçu suit la saisie et le choix d'avatar ; **Valider** enregistre les changements, **Annuler** revient au profil enregistré.

## Choisir un avatar

Dans **Profil → Modifier**, l'onglet **Avatars** présente les avatars gratuits et ceux déjà achetés dans la boutique. L'onglet **Mes images** présente les images personnelles du dossier local. Sélectionner une image remplace le portrait dans l'aperçu ; il faut ensuite valider pour la conserver.

L'image choisie apparaît aussi dans la carte du profil et dans la barre de navigation. Les cadres équipés restent visibles autour du portrait. Choisir un avatar du catalogue ou retirer la photo revient à l'avatar classique, sans changer les points ni les achats.

## Ajouter ses images hors ligne

Le dossier est **`images_profil/`**, à côté de **`Console_CIEL.exe`** dans la version Windows. Dans le projet source, il se trouve à la racine de `console-ciel/`. Il est livré avec un fichier d'aide ; aucune image personnelle n'est fournie.

1. Ouvrir **Profil → Modifier → Mes images → Ouvrir le dossier**.
2. Copier ses fichiers **PNG, JPG/JPEG ou WebP** directement dans ce dossier.
3. Revenir dans l'application et cliquer sur **Actualiser les images**.
4. Choisir le portrait, puis **Valider**.

Aucune connexion, aucun compte et aucune réexportation ne sont nécessaires. Les sous-dossiers ne sont pas parcourus. La bibliothèque affiche au maximum **128 images valides**, avec une limite de **8 Mio par fichier** et de **4 096 pixels par côté**. Les fichiers illisibles ou dépassant ces limites sont ignorés.

La sauvegarde contient seulement le **nom du fichier**, dans le champ facultatif `avatar_image`. Elle ne copie pas la photo et ne conserve pas son chemin absolu. Garder un nom stable permet de retrouver le portrait après déplacement de l'application : copier aussi le dossier `images_profil` au nouvel emplacement. Si une image est renommée, sélectionner son nouveau fichier puis valider à nouveau.

Une photo absente ou illisible laisse apparaître l'avatar classique. Le profil reste utilisable avec sa progression, ses points et son inventaire. On peut toujours modifier son pseudo, puis sélectionner une autre image. Les profils existants restent compatibles avec le schéma de sauvegarde 1.

Le fichier `.gdignore` du dossier source empêche l'import des photos dans le pack Godot. Le conserver permet d'ajouter et remplacer les images directement sur disque.

## Utiliser le clavier

Le clavier commence en **AZERTY minuscule**. Il reste utilisable avec la souris, les flèches et **Entrée**, ou la croix/le joystick et le bouton de face bas de la manette. Le clavier physique reste disponible.

| Touche | Effet |
| --- | --- |
| **⇧** | Met la prochaine lettre en majuscule, puis revient aux minuscules. |
| Deux activations rapides de **⇧** | Verrouille les majuscules ; la touche affiche **⇪**. Une nouvelle activation revient aux minuscules. |
| **123** | Affiche chiffres et ponctuation. |
| **#+=** | Affiche d'autres symboles et lettres accentuées. |
| **ABC** | Revient aux lettres, en conservant l'état de majuscule. |
| **Espace / Effacer** | Insère un espace ou efface la sélection/le caractère précédent. |
| **Valider / Annuler** | Enregistre le profil ou abandonne les changements. |

Changer de page conserve le texte et la position de saisie. Les touches respectent la sélection et la limite de seize caractères. Sur un petit écran, la carte défile pour garder le contrôle actif accessible ; le réglage **Grand texte** reste pris en charge.

## Vérifications

Godot reste fixé à **4.6.3.stable.official.7d41c59c4**, édition standard, rendu Compatibility.

| Suite exécutée | Résultat |
| --- | --- |
| Clavier virtuel | 784 assertions, zéro échec |
| Éditeur de profil | 644 assertions, zéro échec |
| Images locales | 122 assertions, zéro échec |
| Interface générale | 1 988 assertions, zéro échec |
| Navigation | 1 829 assertions, zéro échec |
| Services et sauvegardes | 190 assertions, zéro échec |
| Enquête pédagogique | 189 assertions, zéro échec |
| Outils des archives (séparé) | 27 assertions, zéro échec |

Ces **5 746 assertions réussies** couvrent notamment la casse, les pages chiffres/symboles, le focus, les entrées de manette synthétiques, le choix et la sauvegarde des images, leur retrait, les profils existants et le parcours général. Le rendu réel X11 a également passé **662 contrôles**, à 1280 × 720 et 800 × 480, en texte normal et grand texte. Les [captures](screenshots/profils_0.4.2/) montrent le profil, ses images, le clavier des chiffres et les cartes de joueurs. Ces essais Linux ne valident pas le double-clic Windows, le son ni une manette USB physique.

Pour reproduire les suites depuis `console-ciel/`, utiliser des données utilisateur isolées :

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/keyboard_tests.gd
godot --headless --path . --script res://tests/local_avatar_tests.gd
godot --headless --path . --script res://tests/profile_editor_tests.gd
godot --headless --path . --script res://tests/ui_smoke.gd
```

L'aide du paquet Windows se trouve dans [windows/LIRE_MOI.txt](windows/LIRE_MOI.txt).

Le pack Windows exporté a passé **751 assertions** (47 métier, 60 ressources/interface, 644 profil/clavier/photos), et sa configuration **18 contrôles**, sans échec. Le ZIP et les 175 ressources embarquées sont vérifiés. [Rapport Windows](../builds/Console_CIEL_Windows_x86_64_profils_0.4.2.verification.json).

## Dev — 0.17.0

Le bouton **Dev · Super administrateur**, présent dans Profil et à la première création, ouvre un compte séparé déjà terminé. Il conserve sa sauvegarde entre les sélections et les autres joueurs restent indépendants. [Progression et fonctionnement](DEV.md).
