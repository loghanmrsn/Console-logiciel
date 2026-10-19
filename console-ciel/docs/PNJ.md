# Personnages et discussions — 0.15.0

Six personnages fixes accompagnent l’enquête, dans les mêmes tons doux et formes arrondies que le joueur et les décors. Leurs vêtements et accessoires différencient leurs rôles. Une bulle indique la personne proche avec laquelle discuter.

| Personnage | Emplacement | Explications |
|---|---|---|
| Nora, technicienne | Première salle du premier bâtiment | Contexte du jeu, trois premières réparations, interactions, carnet de missions et points. Après les réparations, elle rappelle l’ascenseur. |
| Idris, responsable | Dernier étage du premier bâtiment, chapitre 5 | Portable, exploration et inscriptions, sans révéler les identifiants ou la solution. Après réussite, il indique le retour au rez-de-chaussée puis l’hôtel. |
| Lucie, équipe du buffet | Salle du petit déjeuner | Table, machine à café, sélection des fils, café réparé puis sac à récupérer, selon la progression. |
| Camille, accueil | Devant le deuxième bâtiment, l’Hôtel CIEL | Réception et chambre 206, escaliers et bus après récupération du sac. |
| Sam, circulation | Trottoir près du passage piéton | Feu vert, voitures lentes, pénalité de 200 points au rouge et retour sur le trottoir en cas de choc. |
| Alex, agent d’étage | Palier du premier étage de l’hôtel | Étage fermé au public, passage maintenu entre rez-de-chaussée et deuxième étage. |

Le palier fermé est celui de l’hôtel : le premier étage du premier bâtiment conserve les trois défis réseau du chapitre 2 et son ascenseur. Aucune porte ni mission existante n’est rendue inaccessible par les personnages.

## Commandes

Approchez-vous du personnage puis utilisez **Espace** ou le **bouton de face bas** de la manette. Les boutons **Suite** et **Précédent** permettent de lire les deux pages. **Fermer la discussion**, **Échap** ou le **bouton de face droit** rend les commandes au jeu. La souris fonctionne aussi. Le focus fait défiler la fenêtre sur les écrans compacts ; le thème nuit et le réglage grand texte restent disponibles.

La conversation suspend le personnage, les voitures et le feu. Elle peut être relue et fermée à tout moment ; elle ne déclenche aucune récompense, quête, réservation ou écriture de sauvegarde. Les conseils sont choisis depuis la progression déjà enregistrée. Le défi mystère conserve son objectif « ??? ».

## Objets, collisions et carte

Les pieds de chaque PNJ ont une petite collision solide, indépendante de sa silhouette. Le personnage se dessine devant ou derrière le joueur selon sa position, comme les autres objets. Les zones d’approche restent libres et les PNJ de la cour restent sur les trottoirs, à l’écart de la chaussée, du passage piéton et des points de retour après collision. La carte de l’hôtel signale ses personnages par des points violets.

La recette vérifie les six interactions avec de vrais événements clavier et manette simulée, les boutons, les retours, la souris, l’arrêt du joueur et de la circulation, la relecture, les collisions, le grand texte et les sauvegardes intactes. Le parcours physique des quinze lieux et les anciennes épreuves sont vérifiés séparément. Le rendu réel est capturé avec Godot sur Linux x86_64 ; Windows, Raspberry Pi et manette physique restent à essayer sur leurs appareils.

[Bilan de livraison](DELIVERY.md) · [Résumé de recette](../tests/npc_0.15.0_results/summary.json) · [Architecture](ARCHITECTURE.md).
