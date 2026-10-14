# Enquête CIEL — deux chapitres

Le joueur commence dans un local technique où une préparation pédagogique a été interrompue. Il rétablit l’éclairage, ouvre le bureau et remet le signal vidéo de l’ordinateur. Après ces trois réussites, l’ascenseur **en bas de la deuxième pièce, le bureau**, se déverrouille et mène à la salle réseau du **chapitre 2**. L’étage propose trois nouvelles missions, avec les mêmes observations, diagnostics, erreurs expliquées et sauvegardes que le premier chapitre.

Tout se joue hors ligne dans une simulation fictive. Aucun câble réel, terminal, accès Internet ou réglage réseau du PC n’est utilisé ni modifié.

## Exploration et tableau de missions

Le personnage se déplace en vue du dessus. Les murs, les meubles et les portes fermées bloquent ses déplacements. Un indicateur désigne l’objet proche avec lequel interagir ; un objet dont le prérequis manque explique ce qu’il reste à accomplir. Les défis, dialogues et pauses suspendent le déplacement.

Le **tableau de missions** se trouve à droite de l’écran. Replié, il occupe peu de place ; déplié, il montre les trois missions du chapitre courant et leur état **À débloquer**, **Disponible**, **En cours** ou **Terminé**, avec une coche après réussite. Les états ne reposent pas seulement sur la couleur.

En exploration, utiliser son bouton **Afficher / Masquer**, la touche **T**, ou le **bouton de face haut** : Triangle sur PlayStation, Y sur une manette Xbox, X sur une manette Nintendo reconnue avec son mapping standard. **Pause → Afficher les objectifs** donne aussi accès à cette action. Le mapping Godot standard utilise le bouton 3 ; le contrôleur fabriqué doit être mesuré dans **Paramètres → Commandes → Test des commandes** pour confirmer le bouton réellement envoyé.

## Chapitre 1 — le local technique

### Éclairage : fermer une boucle

La simulation représente une source d’énergie en **très basse tension virtuelle**, un interrupteur et une lampe. Elle ne constitue pas un tutoriel de câblage secteur.

Les connexions sont des choix navigables au clavier ou à la manette. Le parcours correct est **source → interrupteur → lampe → retour à la source**. Une boucle incomplète ou une liaison contournant un élément produit une explication et laisse les choix modifiables ; le bouton Valider seul ne suffit pas.

La réussite allume la salle, révèle l’indice de la serrure, termine le premier objectif et sauvegarde la transaction. Une source ne suffit pas : le courant circule ici seulement lorsque le trajet est fermé et correctement relié.

### Serrure : distinguer énergie et commande

Après l’éclairage, consulter les quatre observations : badge reconnu, alimentation correcte, actionneur sans commande et liaison déconnectée. Le diagnostic justifié est **la liaison de commande déconnectée** ; la réparation consiste à **reconnecter la commande** dans la simulation.

Les autres réponses expliquent pourquoi remplacer l’alimentation ou changer de badge ne corrige pas le défaut observé. Après sauvegarde réussie, la porte s’ouvre et sa collision disparaît. Alimenter un appareil et lui transmettre un ordre sont deux fonctions différentes.

### Ordinateur : vérifier avant de conclure

Dans le bureau, l’unité centrale semble démarrer, l’écran est alimenté et affiche **« Aucun signal »**. Consulter ces trois symptômes, vérifier les alimentations et inspecter la liaison vidéo avant d’identifier la cause.

Le câble vidéo virtuel est débranché. Choisir **Câble vidéo débranché**, puis **Rebrancher le câble vidéo virtuel**. Les hypothèses qui ignorent les vérifications ne terminent pas la mission. Le message du local et le bilan du chapitre 1 deviennent disponibles après réussite.

« Aucun signal » ne prouve pas une panne d’alimentation : les observations permettent de suivre le trajet du signal et de justifier le diagnostic.

### Ascenseur vers l’étage

L’ascenseur est visible en bas du bureau. Il reste verrouillé tant qu’une des trois missions du chapitre 1 n’est pas terminée ; l’interaction explique le prérequis sans permettre de monter.

Après le bilan du premier chapitre, reprendre l’exploration, rejoindre l’ascenseur et utiliser **Espace** ou le **bouton de face bas**, puis choisir **Monter au chapitre 2**. Le passage sauvegardé mène à la salle réseau. L’ascenseur de l’étage permet aussi de **Revenir au chapitre 1** sans perdre les réussites des deux chapitres. Une reprise restaure le chapitre et la salle atteints ; une transition dont la sauvegarde échoue ne doit pas changer de salle.

## Chapitre 2 — la salle réseau

Les prérequis imposent **liaison RJ45 → adressage IPv4 → protection Wi-Fi**. Chaque défi demande de consulter ses trois observations avant de choisir le diagnostic et la correction.

### Liaison Ethernet : commencer par le trajet physique

Le commutateur est alimenté, les autres ports fonctionnent, mais le port du poste affiche **Liaison absente**. Le câble RJ45 virtuel du poste est débranché. Choisir **Câble RJ45 débranché**, puis **Rebrancher le câble RJ45 virtuel**.

Changer le DNS n’explique pas un câble débranché ; remplacer un commutateur dont les autres ports fonctionnent ne traite pas la cause observée. La réussite remet la liaison physique en service et révèle l’indice de l’adressage.

### IPv4 : comparer le poste et sa passerelle

Le poste utilise **192.168.20.42/24** et la passerelle **192.168.10.1/24**. Le masque **255.255.255.0** désigne ici deux sous-réseaux différents. Le plan du local réserve une adresse disponible, **192.168.10.42/24**, à ce poste.

Choisir **Poste dans le mauvais sous-réseau**, puis **Appliquer le plan IPv4 fictif**. Le poste rejoint virtuellement le réseau **192.168.10.0/24** avec la passerelle **192.168.10.1**. Retirer la passerelle ou choisir une adresse au hasard ne suit pas ce plan. Aucun paramètre IPv4 du PC réel n’est changé.

### Wi-Fi : distinguer chiffrement et administration

Le point d’accès fictif annonce un **réseau ouvert sans chiffrement**. Les appareils prennent en charge WPA2/WPA3 et la fiche propose une nouvelle phrase de connexion longue et unique, distincte du mot de passe d’administration.

Choisir **Wi-Fi sans chiffrement**, puis **Activer WPA2/WPA3 et une phrase unique**. Masquer seulement le nom du réseau ne chiffre pas les échanges ; réutiliser le mot de passe administrateur confond deux accès différents. La réussite clôt le chapitre 2 et affiche son bilan pédagogique.

## Progression, points et anciens profils

Les six missions rapportent chacune **50 points à leur première réussite**, soit **150 par chapitre** et **300 au maximum par profil**. Les identifiants de récompense empêchent de recevoir de nouveau ces points en rejouant. Les achats et l’équipement restent conservés lorsqu’une nouvelle partie remet les missions à leur état initial.

Les missions, observations, indices, salle atteinte, checkpoint et gains de la partie sont enregistrés dans le profil actif. Les deux bilans séparent les **nouveaux points gagnés dans cette partie**, cumulés entre les chapitres, du **solde total**, qui peut aussi refléter des achats ou des parties précédentes. Un profil neuf ayant terminé les six missions sans achat atteint 300 nouveaux points et un solde de 300.

Les profils créés avant 0.6.0 sont complétés avec les trois objectifs de l’étage sans perdre leurs anciennes réussites, observations, points, achats ou récompenses. Le schéma de sauvegarde reste en version 1. Si le chapitre 1 est déjà terminé, l’ascenseur est disponible à la reprise ; les nouvelles récompenses du chapitre 2 restent à gagner. Chaque profil conserve sa progression propre.

## Parcours manuel de validation

1. Créer un profil neuf et commencer. Déplier et replier le panneau par son bouton, **T**, puis le bouton de face haut. Vérifier sa lisibilité et les trois objectifs du chapitre 1.
2. Avant chaque réussite, essayer l’objet suivant. L’indice explique le prérequis ; la porte du bureau et l’ascenseur restent bloqués jusqu’aux réussites requises.
3. Soumettre un circuit incomplet, constater l’explication, puis fermer la boucle correcte. Quitter au menu et reprendre : lumière et premier objectif doivent être conservés.
4. Consulter la serrure, essayer une hypothèse erronée, puis réparer la liaison de commande. Dans le bureau, observer l’ordinateur, vérifier alimentation et câble, puis corriger la liaison vidéo.
5. Lire le bilan du chapitre 1 : trois objectifs terminés et **150 nouveaux points** pour ce profil neuf. Reprendre l’exploration et monter par l’ascenseur en bas du bureau.
6. À l’étage, vérifier que le panneau montre les missions réseau. Essayer l’adressage ou le Wi-Fi trop tôt : leur prérequis bloque la mission. Consulter les trois observations réseau, essayer un diagnostic erroné, puis reconnecter le câble RJ45 virtuel.
7. Corriger l’adresse du poste selon le plan **192.168.10.42/24**, puis activer le chiffrement Wi-Fi et la phrase unique. Lire le second bilan : **300 nouveaux points cumulés** sans achat et six missions terminées.
8. Fermer et relancer entre les missions et après la montée. **Continuer** doit restaurer le bon étage, les observations, les objectifs et les points. Un ancien profil ayant terminé le chapitre 1 doit accéder à l’ascenseur tout en conservant ses achats.
9. Rejouer les six missions : nouveaux gains à zéro, récompenses et solde conservés. Comparer avec un second profil neuf et acheter un emplacement Test avec les points du premier pour vérifier la séparation des profils.
10. Essayer Échap et P avant, pendant et après les défis. Un dialogue ne doit pas permettre d’interagir derrière lui ; le déplacement reprend après fermeture et reste arrêté en pause. Vérifier le panneau en **1280 × 720, 1024 × 600 et 800 × 480**, texte normal et grand, puis les commandes sans souris.

Les tests automatisés utilisent des dossiers temporaires pour les erreurs d’écriture et la migration. Ne pas corrompre les vrais profils pour reproduire ces cas. L’exécution native, le son et une manette USB physique sous Windows restent à essayer sur le PC destinataire.

## Captures et recette 0.6.0

![Arrivée dans la salle réseau avec les trois missions du chapitre 2](screenshots/chapitre_2_0.6.0/chapter_2_arrival_missions.png)

[Ascenseur déverrouillé au bureau](screenshots/chapitre_2_0.6.0/chapter_1_elevator_unlocked.png), [panneau déplié](screenshots/chapitre_2_0.6.0/chapter_2_1280x720_normal_expanded.png), [panneau replié en grand texte](screenshots/chapitre_2_0.6.0/chapter_2_1280x720_large_folded.png) et [les 12 captures](screenshots/chapitre_2_0.6.0/).

La recette sous Godot Linux du **14 octobre 2026** a passé **9 568 assertions source**, **65 de persistance** entre trois processus et **694 contrôles avec rendu X11**, sans échec. Les contrôles ciblés couvrent les prérequis, les six missions, les récompenses uniques, la migration des anciens profils, les erreurs de sauvegarde, les transitions d’ascenseur et les commandes du panneau. [Résumé de la recette](../tests/chapitre_2_0.6.0_results/summary.json). Les périphériques manette sont virtuels et le son des captures utilise le pilote Dummy ; le PC Windows et la console physique restent à vérifier séparément.
