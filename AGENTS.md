# Préférences de travail pour Console CIEL

L'utilisateur souhaite des commits GitHub séparés pour chaque fichier modifié.

- Préparer et vérifier les changements avant de les publier.
- Utiliser une branche de travail pour publier les commits par fichier ; garder `main` utilisable jusqu'à la livraison complète.
- Ne pas créer de commits vides ou répéter artificiellement un même changement pour augmenter le compteur.
- À la fin, publier un commit de livraison comprenant les archives du projet courant et de Windows, puis intégrer la branche complète dans `main`.
- Garder les anciennes livraisons et les sauvegardes. Les archives peuvent contenir seulement les binaires courants si les anciennes versions restent conservées séparément.
- Godot est fixé à `4.6.3.stable.official.7d41c59c4`, édition standard, Compatibility. Utiliser les profils et services existants.
- Les tâches cloud sont déjà isolées : utiliser le checkout existant, sans créer de worktree sauf demande explicite.
- Vérifier l'application native, le clavier et les contrôleurs avec des données de test isolées. Distinguer rendu réel, tests headless, export Windows et test Windows natif.
