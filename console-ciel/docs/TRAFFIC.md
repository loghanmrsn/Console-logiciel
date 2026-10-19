# Objets, collisions et passage piéton — 0.13.0

Les cinq étages du premier bâtiment, le labyrinthe, la cour et les huit zones du séjour et du CTF ont été revus. Les modèles conservent le style du projet : bois nuancé, façades des appareils et détails des meubles. Les meubles de l’hôtel et du petit déjeuner possèdent désormais des modèles indépendants avec leur collision ; le personnage se dessine devant ou derrière selon sa position. Les chaises, le pied des plantes, les colonnes rondes et la fontaine suivent leur forme au sol. La commande de porte et le battant ouvert du premier étage sont solides. Les écrans et le portable restent attachés à leur bureau.

## Traverser la cour

Une chaussée à deux voies sépare le premier bâtiment et l’hôtel. Le passage piéton central reste accessible ; des garde-corps empêchent de contourner la route par les côtés. Bancs, bases des feux, panneau du bus et jardinières sont solides. Le bus reste au même endroit.

| Situation | Résultat |
|---|---|
| Entrer sur la chaussée au vert | Traversée gratuite ; les voitures attendent avant le passage. |
| Le vert arrive à son terme pendant cette traversée | Le passage reste protégé jusqu’à la sortie du piéton. |
| Entrer au rouge et atteindre le trottoir opposé sans choc | Une pénalité de **200 points**, enregistrée une fois pour cette traversée. |
| Faire demi-tour vers son trottoir de départ | Aucune pénalité. |
| Toucher une voiture | Retour au départ de cette traversée, sur le même trottoir. Missions, achats et points conservés ; aucune pénalité de traversée ajoutée. |
| Mettre en pause ou ouvrir un dialogue | Les voitures et le chronomètre du feu s’arrêtent. |

Les voitures roulent à **85 unités/seconde**, contre 190 pour le personnage, et gardent leur distance dans une file. Le cycle comprend dix secondes vertes, dix secondes rouges puis une phase rouge d’évacuation d’au moins quatre secondes. Le vert attend que les véhicules déjà engagés aient dégagé le passage. Le panneau indique **VERT / ROUGE** en plus des couleurs. Une traversée est jugée d’après le feu à l’entrée sur la chaussée.

## Points et dette

Une pénalité coûte toujours **200 points** : les points disponibles sont retirés, puis le montant restant devient une dette. Par exemple, avec 50 points, le solde devient 0 et la dette 150. Une récompense suivante de 50 points ramène cette dette à 100, sans créditer le portefeuille. Une fois la dette remboursée, le surplus rejoint le solde.

La dette apparaît dans l’en-tête ; le profil affiche le nombre de pénalités, les points déjà payés et le reste dû. Elle est propre au profil et survit au redémarrage ainsi qu’à **Nouvelle partie**. Les anciens profils sans pénalité restent utilisables. Les récompenses restent uniques ; le maximum nominal du parcours demeure **750 points avant achats et pénalités**.

Solde, dette et compteur sont écrits ensemble. En cas d’échec de sauvegarde d’une pénalité, la traversée ramène au trottoir de départ avec un message ; aucun débit partiel n’est appliqué. Les récompenses et leur remboursement de dette sont également enregistrés dans une seule transaction.

## Vérifications

Les tests utilisent les véritables collisions du moteur dans tous les lieux, contrôlent les points de reprise et cherchent un chemin physique jusqu’aux interactions. Les scénarios de circulation font marcher le personnage au clavier dans le monde : passage au vert, protection du piéton, rouge sans choc, demi-tour, collision dans les deux sens, pause, reprise et erreur d’écriture. Les services vérifient aussi la dette, son remboursement et l’isolation des profils.

Les captures réelles et le résultat final sont dans le [bilan de livraison](DELIVERY.md) et le [résumé de recette](../tests/traffic_0.13.0_results/summary.json). Le rendu vérifié dans le cloud est celui de Godot Linux x86_64 ; le lancement natif des exécutables Windows et Raspberry Pi reste à essayer sur les appareils concernés.
