# Première enquête CIEL

Le joueur entre dans un local technique où une préparation pédagogique a été interrompue. Il rétablit l'éclairage, ouvre le bureau puis remet le signal vidéo de l'ordinateur. Le message final explique l'incident et le bilan rappelle les trois notions apprises.

Le personnage se déplace en vue du dessus. Les murs, les meubles et la porte fermée bloquent ses déplacements. Un indicateur désigne l'objet proche avec lequel interagir ; les objets suivants donnent un indice si leur prérequis n'est pas terminé. Les défis et les dialogues suspendent le déplacement.

## Éclairage : fermer une boucle

La simulation représente une source d'énergie en **très basse tension virtuelle**, un interrupteur et une lampe. Il ne s'agit pas d'un tutoriel de câblage secteur.

Les connexions possibles sont des choix navigables au clavier ou à la manette. La configuration correcte forme le parcours **source → interrupteur → lampe → retour à la source**. Le service vérifie les connexions sélectionnées ; un bouton « Valider » seul ne suffit pas. Une boucle incomplète ou une liaison qui contourne un élément produit une explication et laisse les choix modifiables.

La réussite allume la salle, révèle un indice pour la serrure, termine le premier objectif et sauvegarde la transaction. Notion à retenir : une source ne suffit pas ; le courant ne circule dans cette simulation que si le trajet est fermé et correctement relié.

## Serrure : distinguer énergie et commande

Après l'éclairage, le lecteur de la serrure fictive devient lisible. Les observations indiquent que le badge est reconnu et que l'alimentation est correcte, mais que l'actionneur ne reçoit pas la commande.

Le joueur doit consulter les quatre observations — badge, alimentation, actionneur, liaison — puis choisir le diagnostic justifié et la réparation correspondante. La cause est **la liaison de commande déconnectée**. Changer la source d'énergie ou accuser le badge ne correspond pas aux éléments observés ; les réponses erronées expliquent cette contradiction.

Une correction virtuelle de la liaison ouvre la porte et retire sa collision seulement après sauvegarde réussie. Notion à retenir : alimenter un appareil et lui transmettre un ordre sont deux fonctions différentes. Un récepteur peut avoir de l'énergie sans recevoir la commande attendue.

## Ordinateur : vérifier avant de conclure

Derrière la porte, l'unité centrale semble démarrer, l'écran est alimenté et affiche **« Aucun signal »**. Le joueur consulte ces trois symptômes puis vérifie les alimentations et inspecte la liaison vidéo avant d'identifier la cause.

L'observation du câble vidéo révèle qu'il est débranché. Le diagnostic correct est **l'absence de liaison vidéo** ; la correction consiste à reconnecter ce câble dans la simulation. Les hypothèses qui ignorent les vérifications ne terminent pas la mission. Le bureau fictif et le message final apparaissent après réussite.

Notion à retenir : « Aucun signal » ne signifie pas nécessairement une panne de l'ordinateur ou de l'écran. Vérifier le chemin du signal avec les symptômes observés permet de justifier un diagnostic. Aucun terminal réel, réseau ou fichier du système hôte n'est utilisé.

## Progression, points et reprise

Les objectifs indiquent **Verrouillé**, **Disponible**, **En cours** ou **Terminé** avec un texte ou une coche, sans dépendre uniquement de la couleur. Les prérequis imposent éclairage → serrure → ordinateur.

Les missions terminées, indices, observations et checkpoint sont conservés dans le profil actif. Une reprise restaure la lumière et l'état de la porte et de l'ordinateur depuis ces données. Le changement de profil utilise les sauvegardes propres à chaque joueur.

Chaque première réussite rapporte 50 points. Le bilan affiche les **nouveaux points gagnés dans cette partie**, séparés du **solde total**. Rejouer conserve les achats et les récompenses déjà attribuées : réussir à nouveau sert à refaire les défis, sans obtenir une deuxième récompense.

## Parcours manuel de validation

1. Avec un nouveau profil, commencer une partie, essayer la serrure avant l'éclairage et vérifier son indice de prérequis.
2. Dans le circuit, soumettre une configuration incomplète, constater le retour explicatif, puis former la boucle correcte.
3. Revenir au menu et reprendre : la salle doit être éclairée, les indices conservés et le premier objectif terminé.
4. Consulter la serrure, choisir une hypothèse erronée puis le diagnostic et la réparation corrects. Vérifier que la porte bloque avant, puis devient franchissable après réussite.
5. Revenir au menu et reprendre ; observer l'ordinateur, essayer une mauvaise hypothèse, vérifier le câble vidéo puis effectuer la correction virtuelle.
6. Lire le message et le bilan : trois missions terminées, 150 nouveaux points pour ce profil neuf. Revenir à la boutique et vérifier que ces points sont utilisables.
7. Rejouer et résoudre de nouveau les missions : nouveaux gains à zéro, solde inchangé. Comparer avec un second profil neuf.
8. Essayer Échap et la pause avant, pendant et après chaque défi ; après fermeture, les déplacements doivent reprendre. Tester les commandes sans souris et les paramètres d'accessibilité aux trois résolutions.

Les tests automatisés injectent aussi des erreurs d'écriture dans des dossiers de test ; ne pas modifier les droits ou corrompre les vrais profils pour reproduire ce cas.
