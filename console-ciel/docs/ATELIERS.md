# Les cinq ateliers du lycée — 0.27.0

Les cinq espaces sont reconstruits dans le jeu 2D à partir des panoramas de la [visite du lycée Louise Michel](https://lycee-louise-michel.fr/360/BAC%20PRO%20CIEL/index.html). Leurs proportions et leurs connexions sont adaptées à la circulation du personnage ; il ne s’agit pas d’un relevé architectural coté. Les photographies restent des références externes et ne sont pas redistribuées. Le logiciel fonctionne hors ligne.

| Salle | Éléments repris | Accès |
|---|---|---|
| 1 · BAC PRO CIEL | Grande halle, mezzanine à garde-corps, poteaux métalliques, boxes techniques, établis de prototypage, allée bleue | Couloir des ateliers ; laboratoire réseau sur la gauche |
| 2 · 2TNE | Platines de câblage verticales, cloisons de poste, établis bois, outils, instruments et tiroirs à composants | Porte 2 du couloir |
| 3 · Réunion | Tableau blanc, fenêtres hautes, tables de groupe, poste enseignant et rangement | Porte 3 du couloir |
| 4 · Informatique CIEL | Rangées d’ordinateurs, baie réseau, banc de mesure séparé par une cloison | Parvis du lycée ; accès au premier couloir |
| 5 · BTS FED DBC | Boxes techniques, armoires de régulation, banc thermique/hydraulique, tables et postes informatiques | Porte 5 du couloir |

Les murs sont blancs avec des plinthes gris bleu. Les peintures jaune et vert vif de certaines références sont remplacées par une palette claire, du bois naturel et des accents bleus. Le mobilier possède des pieds, des faces en relief, des ombres douces et des commandes lisibles. Les fenêtres hautes éclairent les sols ; la toiture reste ouverte dans cette représentation en coupe pour permettre le jeu.

Les 54 positions de la visite correspondent à cinq ateliers. Les vues d’accueil et des vues complémentaires des postes, cloisons, tables et équipements ont été consultées. Aucune pièce supplémentaire n’est présentée comme un relevé vérifié : le laboratoire IPv4 / IPv6 est l’extension pédagogique déjà présente dans le logiciel.

Les repères d’interaction permettent d’observer les équipements et de franchir les portes avec Espace ou le bouton 0. La porte sécurisée et ses trois connexions restent nécessaires pour entrer dans les ateliers. Chaque salle dispose d’une reprise de sauvegarde ; les sorties reviennent près de leur porte dans le couloir. Une erreur d’écriture conserve la position et le profil précédents. Les anciennes missions réseau restent disponibles.

Validation : `school_ateliers_ui_tests.gd` parcourt les salles et vérifie observations, portes clavier/manette simulée, échec disque, reprise et petit écran. `world_collision_tests.gd` recherche des chemins réels pour un personnage de rayon 10,2 à travers les collisions de toutes les zones. Les preuves de rendu proviennent de captures du moteur, pas d’images conceptuelles. Les limites matérielles figurent dans [DELIVERY.md](DELIVERY.md).

Captures de la version livrée : [atelier 1](screenshots/ateliers_0.27.0/school_ateliers_ui_tests/school_workshop_ensemble_challenge.png) · [atelier 2](screenshots/ateliers_0.27.0/school_ateliers_ui_tests/school_tne_ensemble_challenge.png) · [salle 3](screenshots/ateliers_0.27.0/school_ateliers_ui_tests/school_meeting_ensemble_challenge.png) · [salle 4](screenshots/ateliers_0.27.0/school_ateliers_ui_tests/school_cyber_ensemble_challenge.png) · [atelier 5](screenshots/ateliers_0.27.0/school_ateliers_ui_tests/school_fed_ensemble_challenge.png).
