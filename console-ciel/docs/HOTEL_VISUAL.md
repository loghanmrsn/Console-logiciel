# Épreuves de l’hôtel — rendu 0.14.0

Cette mise à jour enrichit les **deux épreuves actuelles du deuxième bâtiment**, en conservant les tons ivoire, bois, vert doux et doré, les formes arrondies et les ombres sobres de l’hôtel.

## Local informatique

Les baies présentent des rails, des vis, des grilles, des tiroirs et des voyants liés à la panne du récit. Le poste de contrôle passe de « disque plein » à « en ligne » après la réparation. Un onduleur et un chariot de maintenance complètent la salle. Les joints du plancher et les conduits restent à plat ; les nouveaux meubles sont des obstacles physiques et se placent devant ou derrière le personnage selon sa position.

Le panneau de diagnostic comporte une illustration du serveur, un compteur d’observations, quatre cartes d’indices puis les parties diagnostic et intervention. Les résultats proviennent de HotelService. Réexaminer une carte affiche son propre détail, sans ajouter d’observation ni de récompense. Les boutons restent accessibles au clavier, à la souris et à la manette ; le focus fait défiler les longues pages sur petit écran. Les cartes héritent des couleurs du thème et les textes s’adaptent au réglage grand texte.

## Petit déjeuner et machine à café

Rideaux, chemin de table, verres, couverts et plateaux du buffet ajoutent des détails dans la même palette. Le meuble à tasses possède une collision et laisse l’approche de la machine dégagée. Le cadran, le plateau d’égouttage et les connecteurs de la machine reflètent sa progression. Après la prise du café, la tasse quitte le distributeur et se trouve à la table.

Le panneau électrique garde les six boutons natifs et les noms de couleurs. Un cadre doré, des vis, des prises, des embouts et des câbles avec des courbures différentes améliorent leur lecture. La sélection reste lumineuse et réversible ; les connexions enregistrées se retrouvent après une reprise. Les trois indicateurs du panneau correspondent au nombre de paires validées.

Les paires restent **A–3 rouge, B–2 vert, C–1 marron**. Les erreurs et les refus d’écriture conservent les bonnes connexions. Les règles du séjour, les points, la dette, les achats et les sauvegardes ne changent pas. Les repères de l’informatique réparée et du café pris restent masqués. Les cinq futures épreuves du CTF attendent toujours les consignes de l’utilisateur.

## Organisation et vérifications

`hotel_diagnostic_panel.gd` possède la présentation du diagnostic et émet des signaux ; `hotel_story_ui.gd` transmet les choix à HotelService. Les modèles restent dans HotelVisual et les emprises dans HotelLayout, partagés par la carte, les collisions et les parcours de test. Aucun shader, texture externe ou clignotement continu n’est nécessaire.

La recette combine les vrais contrôles, le parcours du séjour jusqu’au café, les erreurs, les reprises, le grand texte, le thème nuit et la physique des meubles. Tous les lieux précédents sont aussi parcourus par le contrôle de collisions. [Bilan de livraison](DELIVERY.md) · [Résumé de recette](../tests/hotel_visual_0.14.0_results/summary.json) · [Parcours de l’hôtel](HOTEL.md).
