# Préférences de travail pour Console CIEL

L'utilisateur souhaite des commits GitHub séparés pour chaque fichier modifié.

- Préparer et vérifier les changements avant de les publier.
- Utiliser une branche de travail pour publier les commits par fichier ; garder `main` utilisable jusqu'à la livraison complète.
- Ne pas créer de commits vides ou répéter artificiellement un même changement pour augmenter le compteur.
- À la fin, publier un commit de livraison comprenant l’archive du projet courant et le paquet de la plateforme demandée par l’utilisateur (Windows ou Linux Raspberry Pi), puis intégrer la branche complète dans `main`.
- Réutiliser la présentation actuelle des README à chaque mise à jour : conserver les rubriques et leur ordre (téléchargement Windows, téléchargement Linux / Raspberry Pi, puis descriptif), actualiser les liens de téléchargement et uniquement les faits devenus nécessaires. L’utilisateur complétera lui-même le détail manquant plus tard.
- Garder les anciennes livraisons et les sauvegardes. Les archives peuvent contenir seulement les binaires courants si les anciennes versions restent conservées séparément.
- Godot est fixé à `4.6.3.stable.official.7d41c59c4`, édition standard, Compatibility. Utiliser les profils et services existants.
- Les tâches cloud sont déjà isolées : utiliser le checkout existant, sans créer de worktree sauf demande explicite.
- Vérifier l'application native, le clavier et les contrôleurs avec des données de test isolées. Distinguer rendu réel, tests headless, ressources compilées, export Windows ou ARM64 et lancement natif sur le matériel cible.
