# Personnages et discussions — 0.16.0

Les six PNJ conservent les tons doux, les volumes arrondis et les petites ombres du projet. Leurs visages, coiffures et vêtements sont plus détaillés : carré court, boucles et lunettes, chignon et tablier, veste d’accueil, casquette et gilet, ou tenue d’agent avec badge. Le portrait reprend le même modèle en vue rapprochée. Un léger geste accueille le joueur ; les regards suivent son approche, sans animation permanente.

| Personnage | Emplacement | Explications |
|---|---|---|
| Nora, technicienne | Première salle du premier bâtiment | Contexte, trois premières réparations, commandes, carnet de missions et points. |
| Idris, responsable | Dernier étage du premier bâtiment | Portable et exploration, puis retour à la sortie après réussite. La solution du mystère reste secrète. |
| Lucie, équipe du buffet | Salle du petit déjeuner | Table, machine en panne, fils à relier, café réparé et sac à récupérer selon la progression. |
| Camille, accueil | Devant l’Hôtel CIEL | Réception, chambre 206, escaliers et départ en bus. |
| Sam, circulation | Trottoir du passage piéton | Feu vert, voitures lentes, pénalité au rouge et retour après un choc. |
| Alex, agent d’étage | Palier du premier étage de l’hôtel | Étage fermé au public, passage maintenu entre rez-de-chaussée et deuxième étage. |

Le premier étage du premier bâtiment conserve ses défis réseau. Les PNJ de la cour restent sur les trottoirs et ne bloquent ni le passage piéton ni les points de retour après un choc. Les six emprises physiques sont conservées ; les personnages sont triés devant ou derrière le joueur selon leur position.

## Approche et commandes

Une petite bulle signale chaque personnage ; elle s’ouvre sur son nom lorsqu’il est à portée. **Approchez-vous par un côté libre**, puis utilisez **Espace** ou le **bouton de face bas**. Le PNJ peut être abordé de face, de côté ou par derrière ; les murs et les autres obstacles empêchent toujours une discussion à travers eux.

La fenêtre présente le portrait, le nom, le rôle et la page courante. Le texte est placé dans une bulle arrondie, avec les couleurs du thème. **Suite / Précédent** permettent de lire et relire ; **Espace** avance aussi d’une page. Le bouton **×**, **Échap** ou le **bouton de face droit** ferme directement la discussion. La dernière page propose aussi **Fermer la discussion**.

Sur petit écran, le **portrait et les boutons restent visibles**. Seul le texte défile : molette de souris, ou **↑↓ / croix de manette** lorsque sa zone est sélectionnée. La navigation permet de revenir aux boutons. La hauteur reste stable entre les pages ; les fondus courts ne retardent pas la pagination. Le grand texte et le thème nuit sont pris en charge. Le réglage de **réduction des animations** rend les changements immédiats.

## Reprise et progression

Une conversation suspend le joueur, les voitures et le feu. Elle ne crée ni mission ni récompense et ne demande aucune écriture de sauvegarde. Les conseils lisent uniquement la progression existante. Une touche maintenue ne rouvre pas la discussion après sa fermeture.

Une déconnexion de manette suspend la fenêtre sans perdre sa page. Même si elle interrompt un fondu de fermeture, la reprise retrouve le même panneau, son opacité et ses boutons. Les animations sont locales, brèves et annulées quand la scène est détachée.

## Vérifications

La recette utilise les vrais boutons et des événements clavier, souris et manette simulée. Elle vérifie les quatre côtés d’approche, les obstacles intermédiaires, les corps solides, la lecture en 800 × 480 avec grand texte, les pages stables, Espace, les touches maintenues, les animations réduites et la déconnexion pendant une fermeture. Les anciens chapitres, l’hôtel et la circulation sont vérifiés séparément.

Le rendu est capturé avec Godot sur Linux x86_64. Les exports Windows et Raspberry Pi sont contrôlés, mais le lancement sur ces matériels et une manette physique restent à essayer sur leurs appareils.

[Bilan de livraison](DELIVERY.md) · [Résumé de recette](../tests/npc_polish_0.16.0_results/summary.json) · [Architecture](ARCHITECTURE.md).
