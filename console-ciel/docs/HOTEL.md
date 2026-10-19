# Hôtel CIEL — chambre 206, petit déjeuner et départ pour sudo hack

Après le défi du labyrinthe, revenez au palier et descendez les quatre étages de l’ascenseur. Au premier niveau de l’enquête (rez-de-chaussée), sortez par la porte en bas à gauche. Traversez la cour et entrez dans l’hôtel d’en face.

## Réception et réservation

Le grand hall s’inspire d’un hôtel cinq étoiles : réception, marbre, touches dorées et salons. Approchez la réception et confirmez la réservation de la **chambre 206**. Aucun paiement ni renseignement personnel n’est demandé. La panne du système de réservation survient après cette confirmation.

## Salle informatique voisine

La réparation se déroule au même niveau que le hall. Entrez dans la salle informatique, consultez les quatre observations, puis choisissez le diagnostic et la réparation. Le serveur reste alimenté et connecté au réseau ; son stockage est plein et son service de réservation est arrêté. La solution simulée consiste à **archiver les anciens journaux puis relancer le service**. Un simple redémarrage ou une désactivation de protection ne corrige pas la cause.

Aucune commande n’est exécutée sur votre ordinateur. Cette étape prolonge le récit de l’hôtel et n’ajoute pas de points au portefeuille de l’enquête.

## Escaliers et chambre 206

Après la réparation, les escaliers deviennent accessibles. Les volées arrondies montantes et descendantes sont côte à côte et reviennent du même côté du palier. Au **premier étage**, seul le palier est accessible : le passage vers les pièces est fermé. Montez à nouveau pour atteindre le **deuxième étage**.

Le panneau de mission apparaît automatiquement et indique **Rendez-vous chambre 206**. Entrez par la porte 206, déposez vos bagages à l’emplacement prévu, puis interagissez avec le lit.

## Le lit et la nuit

Le premier choix propose exactement **Dormir** ou **Se poser sur le lit**. Dormir fait passer la nuit et mène au matin, où commence le trajet vers le petit déjeuner.

En choisissant de vous poser, le personnage reste assis sur le lit. Après **dix secondes de jeu actif**, deux choix apparaissent : **Dormir** ou **Continuer à attendre**. Attendre relance dix secondes, puis les mêmes choix reviennent. Il n’y a pas de choix pour descendre du lit avant de dormir.

Pause, paramètres, déconnexion de manette et confirmations suspendent l’attente. Un retour au menu conserve la position assise ; Continuer reprend cette séquence. Les transitions de nuit respectent le réglage de réduction des animations. Au réveil, le personnage peut quitter le lit et suivre les nouveaux objectifs.

## Au réveil : descendre au rez-de-chaussée

Le tableau de missions indique automatiquement **Aller au rez-de-chaussée**. Sortez de la chambre 206, prenez les escaliers pour descendre au palier du premier étage, puis descendez à nouveau jusqu’au grand hall. Le premier étage reste limité aux escaliers. Cette arrivée au rez-de-chaussée après la nuit rapporte **50 points**, une seule fois par profil.

## Petit déjeuner et machine à café

Dans le hall, prenez la porte de la salle du petit déjeuner et asseyez-vous à la table. Le personnage remarque qu’il a oublié son café. Approchez la machine en panne et interagissez pour ouvrir la vue rapprochée de son panneau électrique.

Le panneau présente **six fils**, répartis en deux rangées : **A, B, C** en haut et **1, 2, 3** en bas. Sélectionner un fil le fait briller ; appuyer à nouveau sur ce fil annule la sélection. Choisissez ensuite le fil de même couleur dans l’autre rangée pour former une paire.

| Fil du haut | Fil du bas | Couleur |
|---|---|---|
| A | 3 | Rouge |
| B | 2 | Vert |
| C | 1 | Marron |

Une combinaison de couleurs différentes n’est pas acceptée. Après les trois liaisons correctes, la machine est réparée : prenez votre café avant de poursuivre. Les fils sont une simulation et ne commandent aucun appareil réel. La réparation et le café ne rapportent pas de points.

## Récupérer le sac et quitter l’hôtel

Le prochain objectif vous ramène à la **chambre 206**, au deuxième étage, pour récupérer le sac à dos contenant votre ordinateur. Cette récupération rapporte **50 points**, une seule fois par profil. Redescendez ensuite les deux volées d’escaliers, rejoignez le rez-de-chaussée et sortez par la porte de l’hôtel.

## Bus et accueil du CTF sudo hack

À l’extérieur, approchez l’arrêt de bus et interagissez pour prendre le bus. Vous arrivez à un autre arrêt, devant le bâtiment du CTF **sudo hack**. Entrez par sa porte pour découvrir son hall d’accueil.

Ce hall termine le parcours disponible dans la version **0.13.0**. Les **cinq missions du CTF seront ajoutées plus tard** ; aucun défi ni terminal supplémentaire n’est encore proposé. Le trajet en bus et l’entrée du bâtiment ne rapportent pas de points.

## Récompenses du matin

Les treize missions des cinq chapitres gardent leurs **650 points**. Les deux objectifs récompensés du matin ajoutent **100 points**, pour **750 points au maximum gagnés par profil** dans le parcours actuel.

Chaque récompense est liée au profil : reprendre une sauvegarde, refaire le trajet ou choisir Nouvelle partie ne permet pas de la recevoir une deuxième fois. Les points et la progression correspondante sont enregistrés ensemble ; une erreur de sauvegarde ne valide ni l’étape ni son gain.

## Carte, commandes et sauvegardes

La carte reste en haut à gauche et montre la zone actuelle, votre position et ses passages, y compris dans la salle du petit déjeuner et près du CTF. **Un appui sur →** l’affiche ou la masque. Dans l’hôtel, **D**, les autres touches **ZQSD**, le joystick et la croix directionnelle servent à marcher. Les flèches gardent leur fonction de navigation dans les menus.

Les interactions utilisent **Espace / bouton de face bas**. Les opérations sont enregistrées avant de changer d’état ou de décor. Si l’écriture échoue, le dernier état reste intact et une nouvelle tentative est proposée. Les profils et achats existants sont conservés ; Nouvelle partie réinitialise le récit de l’hôtel en préservant le portefeuille et l’inventaire.

## Traverser entre les bâtiments

La cour dispose maintenant d’un passage piéton et de feux. Attendez le vert ; les véhicules sont lents et s’arrêtent avant le passage. Une traversée commencée au rouge et terminée sans collision coûte 200 points. Un choc ramène au trottoir de départ, sans modifier l’histoire ni ajouter une pénalité. Le reste du trajet vers la réception, puis le bus après le séjour, est conservé. [Règles du passage et des pénalités](TRAFFIC.md).
