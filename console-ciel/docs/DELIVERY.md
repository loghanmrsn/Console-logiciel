# Livraison 0.19.1 — façades et retour du labyrinthe

L’hôtel CIEL reçoit une façade en pierre claire, une toiture à lucarnes, des balcons, un portique à colonnes et une entrée vitrée. Le bâtiment d’enseignement conserve une identité distincte. Les volumes dessinés restent dans les emprises solides existantes ; portes, PNJ, passage piéton et circulation restent accessibles.

Après le message de réussite du terminal, un panneau propose **Retourner au début du labyrinthe** ou **Continuer à explorer**. Échap ferme le panneau. Le retour ne change que le checkpoint, après une écriture réussie : aucune mission annulée, aucun point perdu ou ajouté. Une erreur de sauvegarde garde le joueur sur place et permet de réessayer.

Validation du 29 octobre 2026 :

- 36 suites sources : 11938 assertions, aucun échec.
- 14 suites sur les deux packs exportés : 5714 assertions, aucun échec.
- Rendu natif X11 / Mesa llvmpipe / Compatibility : 1693 contrôles, deux parcours complets avec captures ; clavier et manette simulée, petit écran 800 × 480 avec texte agrandi.
- Vérifications des ressources intégrées, format EXE/ARM64, CRC et empreintes des archives. Sauvegardes personnelles et anciennes livraisons conservées.

[Résultats détaillés](../tests/facades_0.19.1_results/summary.json). Les packs Windows et ARM64 sont exécutés avec Godot Linux x86_64 pour la recette ; ce n’est pas un essai natif Windows ou Raspberry Pi. Matériel cible, manette physique et audio restent à tester.

---

# Livraison 0.19.0 — fluidité, rendu et terminal Dev

Le personnage et la caméra utilisent une interpolation physique commune. La caméra s’actualise après le joueur ; la marche accélère sur une courte durée et s’arrête immédiatement au relâchement, sans glissement. L’axe d’animation garde sa direction près des diagonales, et le regard des PNJ évolue progressivement. Les téléportations, reprises et retours des voitures réinitialisent leur interpolation.

Les douze images SVG du personnage sont importées à échelle 2 puis dessinées à leur taille initiale. Les 48 textures utilisent des mipmaps et un filtrage linéaire adapté. La direction artistique et les collisions sont conservées. Le HUD reste au-dessus du décor : les murs ne recouvrent plus le texte du bouton Interagir. Échap ferme les fenêtres du CTF, les contrôles restent visibles après un redimensionnement compact, et les rappels de focus différés sont protégés quand la scène quitte l’arbre.

Dans **Profil → Ouvrir le terminal Dev** ou **Pause → Terminal Dev**, le compte dédié accepte `add coins 500` avec le montant choisi, `skip missions` pour un seul objectif sans points, `reset missions` pour rejouer et `help`, `status`, `clear`. Le clavier virtuel et la manette sont disponibles. Le rôle est contrôlé à chaque commande ; aucun texte n’est transmis à un shell. Toute mutation est validée et enregistrée avant le changement du jeu. Un joueur ordinaire appelé Dev reste un joueur. [Toutes les commandes](https://github.com/loghanmrsn/Console-logiciel/blob/main/solution/commandes%20triches.md).

Le fichier **solution/commandes triches.md** et les anciennes solutions illustrées sont inclus dans les archives complètes. `add coins` ne modifie ni missions ni reçus et laisse la dette inchangée. Passer un objectif complète ses preuves et son reçu sans crédit ; rejouer ne donne donc pas une seconde récompense. `reset missions` conserve solde, achats, équipement, images, pénalités et reçus. La remise en place habituelle de Dev reste distincte et conserve les défis validés.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_dev_tools_0.19.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.19.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.19.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.19.0.zip).

Recette du **28 octobre 2026** : **11 922 assertions dans 36 suites source**, puis **9 307 assertions dans 28 suites sur chaque pack exporté**, zéro échec. Accès au terminal, montants invalides et limites, lecture sans écriture, refus disque, persistance, saut de tous les objectifs et séparation des profils sont couverts. Le déplacement, les 15 lieux, les PNJ, les anciens chapitres, l’hôtel et la circulation restent testés. Les parcours de marche observent les distances réelles, y compris dans le labyrinthe. Le contrôle physique vérifie **746 points**, **397 corps solides** et **35 617 segments**. [Résumé détaillé](../tests/polish_0.19.0_results/summary.json).

Le rendu réel du pack exporté ajoute **126 contrôles et 18 captures** : [terminal depuis Profil](screenshots/polish_0.19.0/dev_terminal_profile_challenge.png), [terminal en 800 × 480](screenshots/polish_0.19.0/dev_terminal_compact_challenge.png), [terminal en partie](screenshots/polish_0.19.0/dev_terminal_game_challenge.png), puis une capture pour chacun des quinze lieux : cinq étages, labyrinthe, ville et huit zones de l’hôtel / CTF. Le local informatique montre notamment le HUD devant le mur, avec son interaction entièrement lisible.

L’audit statique vérifie **1285 fichiers**, **125 UID**, **302 références** et **385 liens Markdown locaux**, sans erreur. Le chargement des ressources dans le contexte Godot ajoute **317 contrôles réussis**.

Les deux exports contiennent **269 ressources intégrées, dont 48 SVG**, vérifiées par MD5. Les modèles officiels sont contrôlés par SHA-512 ; CRC et SHA-256 des quatre archives sont vérifiés. Les **66 anciennes archives** et la présentation des README sont conservées. Après un redémarrage de l’environnement, les six cas compilés déjà clos ont été revérifiés par leurs hashes et les cinquante autres cas ont été exécutés jusqu’à leur résultat final ; aucune exécution interrompue n’est comptée comme une réussite.

Les ressources exportées et le rendu utilisent **Linux x86_64, OpenGL ES 3.2 Mesa llvmpipe et audio Dummy**. Ce contrôle n’est ni un lancement natif Windows / ARM64 ni un benchmark matériel de fluidité. Les essais sur les appareils destinataires, leur GPU, le son et une manette physique restent à réaliser. Les captures utilisent directement Godot ; le projet ne dispose pas d’un adaptateur ou CLI game-dev configuré.

# Historique — livraison 0.18.0 — Sudo Hack, retour en ville et solutions

Le hall **Sudo Hack** propose cinq épreuves : reconnaître un message de phishing, lire un journal de connexion, décoder du Base64, corriger les droits d’un fichier et retrouver un flag final. Les postes se débloquent dans l’ordre et restent consultables après réussite. Chacun présente ses indices et le clavier virtuel AZERTY avec Maj, chiffres et symboles ; le clavier physique et la manette restent disponibles.

Les cinq réussites ajoutent **250 points**, pour **1 000 points possibles** sur le parcours complet avant achats et pénalités. Les récompenses remboursent d’abord une dette éventuelle. Réponse, progression et reçu sont enregistrés avec les points dans une seule transaction ; rejouer ne crédite pas les mêmes épreuves. Les commandes des postes ne s’exécutent jamais sur l’ordinateur réel.

Après le flag final, sortez et prenez le **bus de retour en ville** devant Sudo Hack. Il vous ramène sur le trottoir près de l’arrêt desservant l’hôtel. L’hôtel, le premier bâtiment et le CTF restent visitables ; les réussites sont sauvegardées. Les anciennes sauvegardes déjà arrivées au CTF reprennent les nouveaux postes sans migration ni crédit à la lecture. Un nouveau Dev possède aussi les cinq validations ; pour un ancien Dev, réinitialiser explicitement son parcours ajoute ces validations en gardant son solde et ses achats.

La **[fiche de solutions illustrée](../../solution/README.md)** donne toutes les bonnes réponses et les étapes du parcours, des cinq chapitres aux fils de la machine à café puis au CTF. Elle est disponible dans le dossier `solution` du dépôt et incluse à côté de `console-ciel/` dans les archives complètes.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_ctf_0.18.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.18.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.18.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.18.0.zip).

Recette du **26 octobre 2026** : **11 629 assertions dans 33 suites source**, puis **9 014 assertions dans 25 suites sur chacun des deux packs exportés**, zéro échec. Les tests couvrent erreurs de saisie, ordre des postes, refus d’écriture, reprise, répétition sans double gain, dette, ancien Dev et retour en ville. Les anciens chapitres, l’hôtel, la circulation et les PNJ restent couverts. Le parcours physique vérifie les **quinze lieux** : **746 contrôles**, **397 corps solides** et **35 617 segments**. [Résumé détaillé](../tests/ctf_0.18.0_results/summary.json).

Le rendu réel X11 / OpenGL ES 3.2 du pack exporté ajoute **269 contrôles et neuf captures** : [hall](screenshots/ctf_0.18.0/ctf_hall_challenge.png), [phishing](screenshots/ctf_0.18.0/ctf_phishing_challenge.png), [journaux](screenshots/ctf_0.18.0/ctf_logs_challenge.png), [Base64](screenshots/ctf_0.18.0/ctf_base64_challenge.png), [permissions](screenshots/ctf_0.18.0/ctf_permissions_challenge.png), [flag](screenshots/ctf_0.18.0/ctf_flag_challenge.png), [800 × 480](screenshots/ctf_0.18.0/ctf_compact_challenge.png), [bus](screenshots/ctf_0.18.0/ctf_bus_retour_challenge.png) et [retour en ville](screenshots/ctf_0.18.0/ctf_retour_ville_challenge.png).

L’audit statique vérifie **1238 fichiers**, **120 UID**, **292 références** et **377 liens Markdown locaux**, sans erreur. Le chargement des ressources dans le contexte Godot ajoute **305 contrôles réussis**.

Les deux exports contiennent **265 ressources intégrées, dont 48 SVG**, vérifiées par MD5. Les modèles officiels sont contrôlés par SHA-512 ; CRC et SHA-256 des quatre archives sont vérifiés. Les **62 anciennes archives** et la présentation des README sont conservées.

Les ressources exportées et le rendu sont exécutés par Godot sur **Linux x86_64 avec Mesa llvmpipe et audio Dummy**. Les exécutables Windows et ARM64 Raspberry Pi ne sont pas lancés nativement : les essais sur leurs appareils, le GPU, le son et une manette physique restent à réaliser.

# Historique — livraison 0.17.0 — Dev super administrateur

Le bouton **Dev · Super administrateur**, présent dans **Profil** et au premier écran de création, ouvre un compte local séparé au nom de **Dev**. Il possède les **treize défis éducatifs validés**, leurs observations, vérifications et indices, ainsi que le séjour réparé, le café terminé et le sac récupéré. Les cinq chapitres sont accessibles ; le bus vers le CTF reste proposé. Les **750 points initiaux** correspondent aux quinze récompenses uniques déjà comptabilisées. [Utiliser Dev](DEV.md).

Le rôle est visible sur la carte du profil et dans sa présentation. Le compte est créé explicitement une seule fois ; le sélectionner à nouveau retrouve sa sauvegarde sans le recréer ou le créditer. Les remises en place conservent les défis validés, les points, les achats, les images et les pénalités. Les autres profils gardent leurs règles normales, y compris un joueur appelé Dev. Un fichier Dev endommagé ou sa sauvegarde précédente n’est jamais remplacé par le preset. Le rôle est un champ facultatif du schéma existant ; les anciens profils restent compatibles.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_dev_0.17.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.17.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.17.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.17.0.zip).

Recette du **25 octobre 2026** : **10 913 assertions dans 31 suites source**, puis **8 298 assertions dans 23 suites sur chacun des deux packs exportés**, zéro échec. Création, rôle, validation complète, treize défis, cinq étages, achats, sélection répétée, remise en place, isolation des joueurs, rôles invalides, refus d’écriture et fichier endommagé sont vérifiés. Les anciens chapitres, l’hôtel, la circulation et les PNJ restent couverts. Le contrôle physique parcourt les **quinze lieux** : **724 contrôles**, **392 corps solides** et **35 833 segments**. [Résumé détaillé](../tests/dev_0.17.0_results/summary.json).

Le rendu réel X11 / OpenGL ES 3.2 du pack exporté ajoute **46 contrôles et quatre captures** : [accueil Dev](screenshots/dev_0.17.0/dev_accueil_challenge.png), [rôle et progression](screenshots/dev_0.17.0/dev_profils_challenge.png), [première salle rétablie](screenshots/dev_0.17.0/dev_premiere_salle_challenge.png) et [accès compact](screenshots/dev_0.17.0/dev_compact_challenge.png).

L’audit statique vérifie **1209 fichiers**, **115 UID**, **278 références** et **357 liens Markdown locaux**, sans erreur. Le chargement des ressources dans le contexte Godot ajoute **293 contrôles réussis**.

Les deux exports contiennent **259 ressources intégrées, dont 48 SVG**, vérifiées par MD5. Les modèles officiels sont contrôlés par SHA-512 ; CRC et SHA-256 des quatre archives sont vérifiés. Les **58 anciennes archives** et la présentation des README sont conservées.

Les ressources exportées et le rendu sont exécutés par Godot sur **Linux x86_64 avec Mesa llvmpipe et audio Dummy**. Les exécutables Windows et ARM64 Raspberry Pi ne sont pas lancés nativement : les essais sur leurs appareils, le GPU, le son et une manette physique restent à réaliser. Les cinq futurs défis du CTF attendent leurs consignes.

# Historique — livraison 0.16.0 — PNJ et discussions plus fluides

Les six PNJ gagnent des **visages, coiffures et tenues plus détaillés**, dans la palette douce du jeu. Leurs accessoires différencient les rôles ; les portraits montrent le même modèle en vue rapprochée. Un regard accompagne l’approche et un bref geste accueille le joueur. Les bulles discrètes s’ouvrent sur le nom à portée. Les six corps solides, leurs emplacements et le tri de profondeur sont conservés. [Personnages et commandes](PNJ.md).

La discussion se déclenche **depuis les côtés libres du PNJ** ; son propre corps ne gêne plus la visibilité, tandis que les murs et le mobilier restent bloquants. Une **bulle arrondie** présente le texte, avec un portrait et des actions qui restent fixes, même sur petit écran. Seul le texte défile. **Espace** avance les pages ; **Suite / Précédent**, **×**, **Échap / face droite** restent disponibles. Les fondus sont courts et les changements immédiats si les animations sont réduites. Un appui maintenu ne rouvre pas la fenêtre. Une déconnexion pendant une fermeture annule la transition et conserve la discussion, la page et les commandes à la reprise.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_pnj_fluide_0.16.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.16.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.16.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.16.0.zip).

Recette finalisée le **19 octobre 2026** : **10 835 assertions dans 29 suites source**, puis **8 220 assertions dans 21 suites sur chacun des deux packs exportés**, zéro échec. Les six discussions, les quatre côtés d’approche, les obstacles intermédiaires, les boutons, les pages stables, la lecture défilante, Espace, les touches maintenues, la réduction des animations, les sauvegardes intactes et la déconnexion pendant une fermeture sont vérifiés. Le contrôle physique parcourt les **quinze lieux**, avec **724 contrôles**, **392 corps solides** et **35 833 segments de déplacement**. [Résumé détaillé](../tests/npc_polish_0.16.0_results/summary.json).

Le rendu réel X11 / OpenGL ES 3.2 du pack exporté ajoute **490 contrôles et 16 captures**, dont la lecture en **800 × 480 avec grand texte et thème nuit**. Exemples : [portrait et discussion](screenshots/npc_polish_0.16.0/npc_workshop_dialogue_challenge.png), [bulle dans le monde](screenshots/npc_polish_0.16.0/npc_workshop_scene_challenge.png), [agent de circulation](screenshots/npc_polish_0.16.0/npc_crossing_dialogue_challenge.png) et [lecture compacte](screenshots/npc_polish_0.16.0/npc_lecture_compacte_challenge.png).

L’audit statique vérifie **1193 fichiers**, **112 UID**, **275 références** et **339 liens Markdown locaux**, sans erreur. Le chargement des ressources dans le contexte Godot ajoute **287 contrôles réussis**.

Les deux exports contiennent **257 ressources intégrées, dont 48 SVG**, vérifiées par MD5. Les modèles d’export officiels sont contrôlés par SHA-512 ; les CRC et SHA-256 des quatre archives sont vérifiés. Les **54 anciennes archives** et la présentation des README sont conservées. Les dessins nouveaux sont originaux ; aucun fournisseur d’images ou de modèles externe n’est utilisé.

Le rendu et les packs sont exécutés par Godot sur **Linux x86_64 avec Mesa llvmpipe et audio Dummy**. Cela ne constitue pas un lancement natif des exécutables Windows ou ARM64 : PC Windows, Pi 4, GPU matériel, son et manette physique restent à essayer sur leurs appareils. La cadence de 60 images/s imposée au pilote des tests animés sert à comparer des temporisations réelles ; elle ne mesure pas les performances du jeu.

# Historique — livraison 0.15.0 — personnages et dialogues

Six **PNJ interactifs** accompagnent le parcours : **Nora** dans la première salle du premier bâtiment, **Idris** au dernier étage, **Lucie** au buffet du matin, **Camille** devant l’hôtel, **Sam** près du passage piéton et **Alex** au palier fermé du premier étage de l’hôtel. Leurs vêtements et accessoires conservent les tons doux et les formes arrondies du projet. Les corps solides et les modèles partagent le tri de profondeur du joueur ; la carte de l’hôtel indique ses personnages. [Emplacements et commandes](PNJ.md).

Chaque discussion présente un portrait, le nom, le rôle, deux pages et les boutons **Suite / Précédent**. **Espace ou face bas** ouvre la rencontre ; **Échap ou face droite** la ferme. Les explications suivent la progression, sans modifier les points, les missions ou les sauvegardes. Idris préserve le secret du chapitre 5. Les déplacements, les voitures et le feu sont suspendus pendant la discussion ; la reprise après déconnexion de la manette conserve la page courante. Le premier étage fermé est celui de l’hôtel : le chapitre réseau du premier bâtiment reste accessible.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_pnj_0.15.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.15.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.15.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.15.0.zip).

Recette finalisée le **19 octobre 2026** : **10 393 assertions dans 28 suites source**, puis **7 778 assertions dans 20 suites sur chacun des deux packs exportés**, zéro échec. Le contrôle physique parcourt les **quinze lieux**, avec **724 contrôles**, **392 corps solides** et **35 833 segments de déplacement**. Les approches des six personnages, les portes, les escaliers et les équipements voisins restent accessibles. Les essais couvrent les six discussions, la relecture, les retours clavier/manette, le clic réel, le stockage indisponible, la suspension de circulation, la déconnexion manette, les récompenses intactes et les anciennes épreuves. [Résumé détaillé](../tests/npc_0.15.0_results/summary.json).

Le rendu réel X11 / OpenGL ES 3.2 du pack exporté ajoute **347 contrôles et 13 captures**, dont une vue en **800 × 480 avec grand texte et thème nuit**. Exemples : [Nora dans l’atelier](screenshots/npc_0.15.0/npc_workshop_scene_challenge.png), [discussion avec Nora](screenshots/npc_0.15.0/npc_workshop_dialogue_challenge.png), [buffet](screenshots/npc_0.15.0/npc_buffet_scene_challenge.png), [passage piéton](screenshots/npc_0.15.0/npc_crossing_scene_challenge.png) et [palier fermé](screenshots/npc_0.15.0/npc_closed_floor_scene_challenge.png).

L’audit statique vérifie **1156 fichiers**, **110 UID**, **272 références** et **324 liens Markdown locaux**, sans erreur. Le chargement des ressources dans le contexte Godot ajoute **283 contrôles réussis**.

Les deux exports contiennent **255 ressources intégrées, dont 48 SVG**, vérifiées par MD5. Les modèles d’export officiels sont contrôlés par SHA-512 ; les CRC et SHA-256 des quatre archives sont vérifiés. Les **50 anciennes archives** et la présentation des README sont conservées.

Le rendu et les packs sont exécutés par Godot sur **Linux x86_64 avec Mesa llvmpipe et audio Dummy**. Cela ne constitue pas un lancement natif des exécutables Windows ou ARM64 : PC Windows, Pi 4, GPU matériel, son et manette physique restent à essayer sur leurs appareils.

# Historique — livraison 0.14.0 — épreuves de l’hôtel enrichies

Les **deux épreuves actuelles du deuxième bâtiment** gardent leur direction artistique : ivoire, bois, vert doux, doré et formes arrondies. Le local informatique présente des baies détaillées, des grilles, des rails, un poste de contrôle et des voyants liés à l’état sauvegardé. Un onduleur et un chariot de maintenance complètent la pièce. Le petit déjeuner gagne des rideaux, du linge de table, des verres, des couverts et des plateaux plus détaillés. Un meuble à tasses complète la machine à café ; les **trois nouveaux meubles sont solides**, triés avec le personnage et représentés sur la carte.

Le diagnostic possède un **composant de présentation dédié**, avec une illustration du serveur, le suivi des quatre observations, leurs cartes et les parties diagnostic/intervention. Réexaminer une carte affiche son propre détail. Le câblage garde les six boutons, les noms des couleurs et les mêmes paires ; il présente un cadre doré, des vis, des embouts et des câbles aux courbes distinctes. La tasse quitte la machine après la prise du café et apparaît à la table. Les repères restent masqués après réussite. [Présentation détaillée](HOTEL_VISUAL.md).

Les règles du séjour, les conditions de réussite, les points, les achats et les pénalités sont conservés. Les services possèdent toujours la validation et les écritures ; les nouveaux composants présentent leurs résultats. Les sauvegardes antérieures restent compatibles et les cinq futures épreuves du CTF attendent les consignes de l’utilisateur.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_hotel_visuel_0.14.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.14.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.14.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.14.0.zip).

Recette finalisée le **19 octobre 2026** : **10 080 assertions dans 27 suites source**, puis **7 465 assertions dans 19 suites sur chacun des deux packs exportés**, zéro échec. Le contrôle physique parcourt les **quinze lieux**, avec **706 contrôles**, **386 corps solides** et **35 841 segments de déplacement**. La collision des trois nouveaux meubles est aussi vérifiée avec la forme physique du personnage dans la scène. Les essais couvrent le séjour jusqu’au café, les cartes consultées à nouveau, les choix erronés, l’écriture refusée, la reprise des fils, les contrôles natifs et les anciens chapitres. [Résumé détaillé](../tests/hotel_visual_0.14.0_results/summary.json).

Le rendu réel X11 / OpenGL ES 3.2 du pack exporté ajoute **299 contrôles et 13 captures**, dont les vues en **800 × 480 avec grand texte** et en **thème nuit**. Exemples : [local informatique](screenshots/hotel_visual_0.14.0/hotel_visuel_local_informatique_challenge.png), [cartes du diagnostic](screenshots/hotel_visual_0.14.0/hotel_visuel_indices_challenge.png), [machine et tasses](screenshots/hotel_visual_0.14.0/hotel_visuel_machine_et_tasses_challenge.png), [câblage terminé](screenshots/hotel_visual_0.14.0/morning_cafe_machine_reparee_challenge.png) et [câblage compact](screenshots/hotel_visual_0.14.0/morning_cafe_compact_challenge.png).

L’audit statique vérifie **1120 fichiers**, **106 UID**, **262 références** et **305 liens Markdown locaux**, sans erreur. Le chargement des ressources dans le contexte Godot ajoute **275 contrôles réussis**.

Les deux exports contiennent **249 ressources intégrées, dont 48 SVG**, vérifiées par MD5. Les modèles d’export officiels sont contrôlés par SHA-512 ; les CRC et SHA-256 des quatre archives sont vérifiés. Les **46 anciennes archives** et la présentation des README sont conservées.

Le rendu et les packs sont exécutés par Godot sur **Linux x86_64 avec Mesa llvmpipe et audio Dummy**. Cela ne constitue pas un lancement natif des exécutables Windows ou ARM64 : PC Windows, Pi 4, GPU matériel, son et manette physique restent à essayer sur leurs appareils.

# Historique — livraison 0.13.0 — objets, collisions et passage piéton

Les objets ont été revus dans les **quinze lieux existants** : cinq étages, labyrinthe, cour et huit zones de l’hôtel et du CTF. Les modèles conservent le style du projet, avec des matériaux et des détails affinés. Les meubles de l’hôtel, les chaises, les bancs et le panneau du bus se placent devant ou derrière le personnage selon sa position. Les colonnes et la fontaine utilisent des formes rondes ; les plantes bloquent au niveau du pot. La commande de porte et le battant ouvert du premier étage sont solides. Les écrans du laboratoire et le portable suivent leur bureau.

La cour dispose d’un **passage piéton avec feux et quatre voitures lentes**. Les véhicules s’arrêtent avant le passage au vert et attendent la fin d’une traversée déjà engagée. Un départ au rouge suivi d’une traversée complète sans choc coûte **200 points**. Un demi-tour reste gratuit. Une collision renvoie au **départ de cette traversée**, sans perte de progression ni pénalité supplémentaire. Les voitures et le feu s’arrêtent en pause ou pendant un dialogue.

Les points disponibles paient la pénalité ; le reste devient une **dette enregistrée dans le profil**, visible dans l’en-tête et le détail du profil. Les gains suivants remboursent cette dette en priorité, dans la même écriture que leur récompense. Nouvelle partie conserve pénalités, dette, achats et reçus. Une erreur d’écriture ne produit aucun débit partiel et permet de retenter la traversée. Les anciens profils restent compatibles. [Règles complètes](TRAFFIC.md).

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_trafic_0.13.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.13.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.13.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.13.0.zip).

Recette finalisée le **19 octobre 2026** : **9 827 assertions dans 26 suites source**, puis **7 212 assertions dans 18 suites sur chacun des deux packs exportés**, zéro échec. Le parcours physique vérifie **700 contrôles**, **383 objets solides** et **35 895 segments de déplacement** dans les quinze lieux. Les essais couvrent les anciennes missions, les contrôles et sauvegardes, la traversée réelle au clavier, le vert protégé, le rouge sans choc, les collisions depuis les deux trottoirs, la pause, les erreurs d’écriture, la dette et son remboursement. [Résumé détaillé](../tests/traffic_0.13.0_results/summary.json).

Le rendu réel X11 / OpenGL ES 3.2 du pack exporté ajoute **213 contrôles** et **21 captures**. Exemples : [passage au vert](screenshots/traffic_0.13.0/traffic_passage_vert_challenge.png), [dette affichée](screenshots/traffic_0.13.0/traffic_dette_150_challenge.png), [format compact](screenshots/traffic_0.13.0/traffic_compact_challenge.png), [chambre 206](screenshots/traffic_0.13.0/objects_hotel_room_206_challenge.png) et [salle du petit déjeuner](screenshots/traffic_0.13.0/objects_hotel_breakfast_challenge.png).

L’audit statique vérifie **1088 fichiers**, **104 UID**, **258 références** et **286 liens Markdown locaux**, sans erreur. Le chargement des ressources dans le contexte Godot ajoute **271 contrôles réussis**.

Les deux exports contiennent **247 ressources intégrées, dont 48 SVG**, vérifiées par MD5. Les modèles d’export officiels sont contrôlés par SHA-512 ; les CRC et SHA-256 des quatre archives sont vérifiés. Les **42 anciennes archives** sont préservées. Les README gardent leur présentation : Windows, Linux/Raspberry Pi, puis descriptif.

Le rendu et les packs sont exécutés par Godot sur **Linux x86_64 avec Mesa llvmpipe et audio Dummy**. Cela ne constitue pas un lancement natif des exécutables Windows ou ARM64 : le Pi 4, le PC Windows, le GPU matériel, le son et la manette physique restent à essayer sur leurs appareils. La suite du CTF et le prochain travail graphique du bâtiment 2 restent à définir avec l’utilisateur.

# Historique — livraison 0.12.0 — petit déjeuner et départ vers Sudo Hack

Après la nuit dans la chambre 206, le panneau demande de **descendre au rez-de-chaussée** par les deux volées d’escalier. L’arrivée rapporte **50 points**, une seule fois par profil. Une porte du hall mène à la **salle du petit déjeuner**. En s’installant à table, le joueur découvre qu’il a oublié son café et que la machine nécessite une réparation.

L’interaction avec la machine ouvre un **panneau de connexion agrandi**, avec les bornes **A, B, C en haut et 1, 2, 3 en bas**. Choisir une borne illumine son fil ; appuyer à nouveau annule la sélection. Les paires de même couleur sont **A–3 rouge, B–2 vert, C–1 marron**. Les mauvaises paires sont expliquées sans effacer les raccords corrects. Trois connexions réussies remettent la machine en service ; le joueur peut alors prendre son café. Les lettres, chiffres et noms de couleurs permettent de jouer sans se fier uniquement aux couleurs.

La mission suivante demande de **récupérer le sac à dos et l’ordinateur dans la chambre 206**. Elle rapporte **50 points** uniques. Il faut ensuite redescendre, sortir de l’hôtel et interagir avec **l’arrêt de bus dans la cour**. Le trajet mène à un autre arrêt devant le bâtiment du **CTF Sudo Hack**. Son accueil est accessible ; les cinq prochaines missions attendent les consignes de l’utilisateur et ne sont pas inventées dans cette livraison. [Guide du séjour](HOTEL.md).

Les deux récompenses et leur étape sont enregistrées dans la même écriture que la progression. Une panne d’écriture conserve l’état précédent. Recharger, refaire le trajet ou recommencer une partie ne redonne pas les points déjà reçus. Le maximum passe à **750 points uniques par profil** : les treize défis éducatifs conservent leurs 650 points et les deux étapes matinales ajoutent 100 points. Le café ne donne pas de récompense supplémentaire. Les sauvegardes 0.11.0 migrent sans perdre leur position ni leurs achats, y compris après une nuit déjà passée hors de l’hôtel.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_matin_ctf_0.12.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.12.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.12.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.12.0.zip).

Recette finalisée le **18 octobre 2026** : **8 845 assertions dans 23 suites source**, puis **6 230 assertions sur chacun des deux packs compilés**, sans échec. La capture réelle X11 / OpenGL ES 3.2 ajoute **348 contrôles** et **11 captures**. Le parcours physique vérifie **235 cas et 4 120 segments de déplacement avec collisions**, dans les zones du séjour, du petit déjeuner et du CTF. Clavier, clics souris et événements de manette, erreurs de sauvegarde, reprises du câblage partiel et anciens chapitres sont couverts. [Résumé détaillé](../tests/morning_0.12.0_results/summary.json).

Audit statique : **1 030 fichiers**, **97 UID uniques**, **247 références de ressources** et **268 liens Markdown locaux**, sans erreur. Le chargement des ressources dans le contexte Godot ajoute **255 assertions réussies**. Les scripts shell passent `bash -n` ; ShellCheck n’est pas installé.

Chaque export contient **239 ressources intégrées**, dont **48 SVG**, vérifiées par MD5 ; les CRC des quatre ZIP sont contrôlés. Le rendu réel permet d’examiner le [fil sélectionné](screenshots/morning_0.12.0/morning_cafe_fil_selectionne_challenge.png), le [panneau compact](screenshots/morning_0.12.0/morning_cafe_compact_challenge.png), les [trois liaisons terminées](screenshots/morning_0.12.0/morning_cafe_machine_reparee_challenge.png) et l’[arrivée au CTF](screenshots/morning_0.12.0/morning_hall_sudo_hack_challenge.png).

Le rendu et les packs sont exécutés par Godot sur Linux x86_64 avec Mesa llvmpipe et audio Dummy. Les tests du pack ARM64 ne constituent pas un lancement de l’exécutable sur un Raspberry Pi ; les essais natifs Windows, Pi 4, GPU matériel, son et manette physique restent à réaliser. Les **38 anciennes archives** sont préservées sans modification. Les README gardent leurs rubriques et leur ordre : Windows, Linux/Raspberry Pi, puis descriptif.

# Historique — livraison 0.11.0 — hôtel et chambre 206

Après le chapitre 5, le joueur retrouve l’hôtel d’en face : **grand hall de 6 400 × 4 200**, réception cinq étoiles, marbre, dorures, salons et escaliers arrondis. La réservation attribue la **chambre 206**, puis une panne du système de réservation survient. Le local informatique voisin reste au même niveau que le hall.

Le diagnostic demande quatre observations : serveur alimenté, réseau actif, disque plein et service arrêté. La solution simulée consiste à **archiver les anciens journaux puis relancer le service**. Les choix erronés et les échecs de sauvegarde permettent de réessayer sans progresser partiellement. Aucune commande système ni réservation réelle n’est effectuée.

Après réparation, les escaliers mènent au **palier du premier étage**, dont l’accès aux pièces est physiquement fermé, puis au **deuxième étage**. Le panneau affiche automatiquement **Rendez-vous chambre 206**. Dans la chambre, le joueur pose ses bagages et choisit **Dormir** ou **Se poser sur le lit**. Assis, il reste bloqué sur le lit ; toutes les dix secondes actives, **Dormir / Continuer à attendre** sont proposés à nouveau, jusqu’au sommeil. Le passage de la nuit mène au matin, où s’arrête cette partie du récit.

La carte suit la zone actuelle et affiche les passages et le joueur. **→** l’affiche ou la masque ; **ZQSD, joystick et croix directionnelle** permettent de marcher. Les reprises conservent les étapes du séjour, y compris la position assise. La pause, les paramètres, l’aide et la déconnexion de manette suspendent l’attente. Les anciens profils, points et achats restent conservés ; le plafond de l’enquête reste à **treize récompenses et 650 points**. Le parcours de l’hôtel ne coûte ni ne rapporte de points. [Guide détaillé](HOTEL.md).

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_hotel_0.11.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.11.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.11.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.11.0.zip).

Recette du **16 octobre 2026** : **6 805 assertions source dans dix-sept suites**, **5 143 assertions par pack compilé** chargé par Godot Linux x86_64 et **407 contrôles de rendu réel X11 / OpenGL ES 3.2**, sans échec. Les attentes utilisent de vraies périodes de dix secondes ; les choix sont testés au clavier, par événements de manette et par clics souris natifs. Le parcours physique, la fermeture du premier étage, les erreurs d’écriture, trois choix d’attente, les deux branches du lit et les reprises sont vérifiés. Une revue indépendante ajoute 169 assertions sur les interruptions nocturnes. [Résumé détaillé](../tests/hotel_0.11.0_results/summary.json).

Audit statique complémentaire : **1 001 fichiers**, **94 UID uniques**, **241 références de ressources** et **255 liens Markdown locaux**, sans erreur. Le chargement des ressources dans le contexte Godot ajoute **249 assertions réussies**. Les scripts shell passent `bash -n` ; ShellCheck n’est pas installé.

Chaque export contient **237 ressources intégrées**, dont **48 SVG**, contrôlées par MD5 ; les CRC des ZIP sont vérifiés. Les 13 captures réelles montrent notamment le [hall](screenshots/hotel_0.11.0/hotel_hall_cinq_etoiles_challenge.png), le [diagnostic](screenshots/hotel_0.11.0/hotel_diagnostic_challenge.png), le [palier fermé](screenshots/hotel_0.11.0/hotel_palier_etage_1_challenge.png), l’[objectif de l’étage 2](screenshots/hotel_0.11.0/hotel_etage_2_objectif_challenge.png), les [choix du lit](screenshots/hotel_0.11.0/hotel_lit_premiers_choix_challenge.png) et le [matin](screenshots/hotel_0.11.0/hotel_matin_challenge.png).

Le rendu utilise Mesa llvmpipe sur Linux x86_64, une sortie audio Dummy et une manette simulée par événements. Les pilotes de test externes exercent les ressources des exports ; ils ne lancent pas les exécutables Windows ou ARM64 sur leur matériel cible. Le lancement natif Windows / Pi 4, leur GPU, le son perçu et une manette physique restent à vérifier sur ces appareils. Les trente-quatre archives précédentes sont conservées sans modification. La présentation des README reste identique, avec Windows puis Linux/Raspberry Pi puis le descriptif.

# Historique — livraison 0.10.0 — cour et nouveau bâtiment

Après la réussite du chapitre 5, le joueur revient au palier et **descend un étage à la fois jusqu’au premier niveau**, le rez-de-chaussée. Une **porte en bas à gauche** de la première pièce permet de sortir dans une cour. Le chemin au sol mène à la porte de l’immeuble d’en face. Les portes permettent aussi de revenir au bâtiment initial.

Ce nouveau bâtiment de **6 400 × 4 200** représente environ 52 fois la surface de la première pièce. Il comprend un grand atrium, des galeries et **seize salles accessibles**. Une **carte en haut à gauche** utilise le même plan que les collisions ; elle affiche votre position et la sortie. **Un appui sur → affiche ou masque la carte** sans répétition lors d’un maintien ; **D, ZQSD, joystick et croix directionnelle** permettent de marcher. Dans les menus et anciens étages, les flèches conservent leurs rôles.

Les prochains niveaux seront créés plus tard. Aucune nouvelle mission ni récompense n’est ajoutée : **treize missions, jusqu’à 650 points par profil**. Les anciens profils, achats et observations restent conservés. Les passages sont enregistrés avant chaque changement de décor ; en cas d’échec, la zone précédente reste active. Continuer reprend au seuil de la zone sauvegardée.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_batiment_0.10.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.10.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.10.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.10.0.zip).

Recette du **16 octobre 2026** : **5 950 assertions source dans quinze suites**, **4 288 assertions par pack compilé** chargé par Godot Linux x86_64 et **200 contrôles de rendu réel X11 / OpenGL ES 3.2**, sans échec. Le parcours est effectué à pied jusqu’à une salle éloignée ; le graphe physique vérifie la connexion des seize salles. Les accès anticipés, échecs d’écriture sur les quatre portes, reprises, retours, touches maintenues et manette inactive sont vérifiés. [Résumé détaillé](../tests/campus_0.10.0_results/summary.json).

L’audit statique vérifie **961 fichiers, 88 UID et 229 références de ressources**, sans erreur.

Chaque export contient **229 ressources intégrées**, dont **48 SVG**, contrôlées par MD5 ; les CRC des ZIP sont vérifiés. Onze captures montrent notamment la [sortie](screenshots/campus_0.10.0/premier_niveau_sortie_challenge.png), la [cour](screenshots/campus_0.10.0/cour_immeuble_face_challenge.png), le [grand atrium avec carte](screenshots/campus_0.10.0/grand_atrium_challenge.png) et la [carte en 800 × 480](screenshots/campus_0.10.0/carte_compacte_challenge.png).

Le rendu utilise Mesa llvmpipe sur Linux x86_64, une sortie audio Dummy et une manette simulée par événements. Les pilotes de test externes exercent les ressources des exports ; ils ne lancent pas les exécutables Windows ou ARM64 sur leur matériel cible. Le lancement natif Windows / Pi 4, leur GPU, le son perçu et une manette physique restent à vérifier sur ces appareils. Les trente archives précédentes sont conservées sans modification.

# Historique — livraison 0.9.0 — chapitre 5, défi mystère

Après les douze premières réussites, l’ascenseur ouvre le **chapitre 5**. Son palier contient un portable et le bouton **Y aller** : il mène à un labyrinthe fixe de **31 × 23 cases**, avec des impasses, une pièce centrale et huit inscriptions murales. La caméra suit le personnage. Le tableau ne révèle pas le but : **???**, avec **une seule mission** et un compteur **0 / 1**.

Le terminal central propose un clavier virtuel pour les identifiants, les mots de passe masqués et les commandes. La connexion ouvre une session utilisateur ; une authentification distincte permet d’obtenir les droits complets de la simulation. Les mémos Linux / Windows mêlent indices utiles et pistes inadaptées. Les textes sont reconnus localement, sans exécuter de commande sur le système hôte.

Les anciens profils, achats et points sont conservés. Continuer reprend le palier ou le labyrinthe, et la session enregistrée après connexion. Le portail d’entrée ramène au palier. Une réussite donne 50 points une seule fois : **treize missions et 650 points au maximum par profil**. Le clavier, les livres des étages précédents et la présentation des README restent conservés.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_labyrinthe_0.9.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.9.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.9.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.9.0.zip).

Recette du **16 octobre 2026** : **5 640 assertions source dans treize suites**, **3 978 assertions par pack compilé** chargé par Godot Linux x86_64 et **1 483 contrôles de rendu réel X11 / OpenGL ES 3.2**, sans échec. Les 335 cases de circulation sont accessibles et sans collision invisible ; le parcours de l’entrée au terminal est effectué avec les vrais déplacements. Les échecs d’écriture, la migration à treize observations, les mots de passe erronés, le rejeu et la séparation des profils sont testés. [Résumé détaillé](../tests/labyrinthe_0.9.0_results/summary.json).

Les **223 ressources intégrées** de chaque export, dont 48 SVG, sont contrôlées par MD5, ainsi que les CRC des ZIP. Dix captures réelles montrent notamment le [palier](screenshots/labyrinthe_0.9.0/chapitre_5_palier_challenge.png), le [labyrinthe](screenshots/labyrinthe_0.9.0/entree_labyrinthe_challenge.png), les [inscriptions](screenshots/labyrinthe_0.9.0/inscription_0_challenge.png), la [connexion](screenshots/labyrinthe_0.9.0/connexion_challenge.png) et le [clavier en 800 × 480 avec texte agrandi](screenshots/labyrinthe_0.9.0/elevation_challenge.png).

Le rendu utilise Mesa llvmpipe sur Linux x86_64, une sortie audio Dummy et une manette simulée par événements. Les pilotes de test externes exercent les ressources des exports ; ils ne lancent pas les binaires Windows ou ARM64 sur leur matériel cible. Le lancement natif Windows / Pi 4, leur GPU, le son perçu et la manette physique restent à vérifier sur ces appareils.

# Historique — livraison 0.8.0 — livres et laboratoire réseau

Le coin ressources du chapitre 3 ouvre trois livres : **Python, HTML et Markdown**. Chaque livre contient trois leçons et un exemple qui permet de répondre au défi. Les couvertures et l’ouverture sont animées ; la réduction des animations est respectée. La lecture fonctionne à la souris, au clavier et à la manette, reste disponible après les missions et ne change aucun point.

Le **chapitre 4**, accessible après les neuf premières réussites, présente trois diagnostics : **pare-feu HTTPS ciblé, conflit d’adresses IPv4 et masque /26**. L’enquête comporte maintenant **douze missions, jusqu’à 600 points par profil**. L’ascenseur présente exactement **Descendre d’étage, Monter d’étage et Retour au menu**. Échap / face droit permet de rester dans la pièce. Les anciennes sauvegardes, achats et récompenses sont conservés.

[Télécharger Windows](../builds/Console_CIEL_Windows_x86_64_livres_reseau_0.8.0.zip) · [Télécharger Raspberry Pi](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.8.0.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.8.0.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.8.0.zip).

Recette du 15 octobre 2026 : **3 983 assertions source dans onze suites**, **2 321 assertions par pack compilé** chargé par Godot Linux x86_64 et **293 contrôles de rendu réel X11 / OpenGL ES 3.2**, sans échec. Les **217 ressources intégrées** de chaque paquet, dont 48 SVG, leurs empreintes MD5 et les CRC des ZIP sont vérifiés. [Résumé détaillé](../tests/livres_reseau_0.8.0_results/summary.json).

Onze captures réelles montrent notamment la [bibliothèque](screenshots/livres_reseau_0.8.0/bibliotheque_challenge.png), le [livre HTML](screenshots/livres_reseau_0.8.0/livre_html_challenge.png), la [bibliothèque compacte](screenshots/livres_reseau_0.8.0/bibliotheque_compacte_challenge.png), le [laboratoire](screenshots/livres_reseau_0.8.0/laboratoire_challenge.png) et les [trois boutons de l’ascenseur](screenshots/livres_reseau_0.8.0/ascenseur_challenge.png).

Le rendu utilise Mesa llvmpipe sur Linux x86_64, des événements de manette simulés et une sortie audio Dummy. Les pilotes de test externes exercent le contenu compilé des exports ; ce contrôle ne lance pas les binaires Windows ou ARM64 sur leur matériel cible. Le lancement natif Windows / Pi 4, leur rendu matériel, le son perçu et la manette physique restent à vérifier sur les appareils.

# Historique — livraison 0.7.1 — clavier des défis de code

Le clavier à l’écran apparaît directement dans les exercices Python, HTML et Markdown. Il propose les minuscules, **⇧**, **123**, **#+=**, Espace, Effacer, Valider et Annuler. Le joueur tape le mot ou symbole manquant (`print`, `h1`, `#`) ou l’exemple complet. Le champ accepte 64 caractères ; le pseudo reste limité à 16. Le clavier physique et la navigation à la manette sont conservés, avec passage entre les touches et le champ de saisie. Une déconnexion conserve le texte et demande une reprise explicite.

[Télécharger Windows 0.7.1](../builds/Console_CIEL_Windows_x86_64_clavier_0.7.1.zip) · [Télécharger Raspberry Pi 0.7.1](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.7.1.zip). [Projet complet Windows](../builds/Console_CIEL_Projet_Complet_Windows_0.7.1.zip) · [Projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.7.1.zip).

Les neuf missions et les récompenses restent à 50 points chacune, 450 au maximum par profil. Les réponses sont comparées à des exemples pédagogiques ; aucun code saisi n’est exécuté. Les sauvegardes et achats existants sont conservés. La présentation des README reste identique, avec les nouveaux liens.

Recette du 15 octobre 2026 : **3 272 assertions source** dans huit suites, **1 882 assertions par pack** Windows et ARM64 chargé par Godot Linux x86_64, et **610 contrôles de rendu X11 / OpenGL ES 3.2 Mesa llvmpipe**, sans échec. Les ressources et CRC des deux paquets sont vérifiés. [Résumé 0.7.1](../tests/clavier_code_0.7.1_results/summary.json).

Les captures réelles montrent le clavier dans [Python](screenshots/clavier_code_0.7.1/chapter_3_python_challenge.png), [HTML](screenshots/clavier_code_0.7.1/chapter_3_html_challenge.png) et [Markdown](screenshots/clavier_code_0.7.1/chapter_3_markdown_challenge.png), dont les deux derniers en 800 × 480 avec texte agrandi. Les exports Windows et ARM64, leurs ressources chargées par Godot Linux x86_64 et le rendu X11 sont des contrôles distincts. Le lancement natif sur Windows et sur le Raspberry Pi, le son perçu et la manette physique restent à vérifier sur les appareils cibles.

# Historique — livraison 0.7.0 — chapitre 3, atelier du code

| Plateforme | Logiciel prêt à lancer | Projet complet avec sources |
|---|---|---|
| Windows x86_64 | [ZIP Windows](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_code_0.7.0.zip) | [Projet Windows](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Windows_0.7.0.zip) |
| Raspberry Pi 4 ARM64 | [ZIP Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Raspberry_Pi_ARM64_0.7.0.zip) | [Projet Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.7.0.zip) |

Sous Windows, **Extraire tout**, puis ouvrir **Console_CIEL.exe**. Sur Raspberry Pi OS **64 bits avec bureau**, extraire tout le ZIP, ouvrir un terminal dans son dossier et lancer `bash ./Lancer_Console_CIEL.sh`. Godot n’est pas nécessaire pour jouer. Dans les projets complets, les dossiers jouables sont respectivement `console-ciel/builds/windows-x86_64-code-0.7.0/` et `console-ciel/builds/linux-arm64-raspberry-pi-0.7.0/`. [Installation Windows](WINDOWS.md) · [Installation Raspberry Pi](RASPBERRY_PI.md) · [Contenu des archives complètes](ARCHIVE_COMPLETE.md).

Après les trois missions réseau du chapitre 2, l’ascenseur ouvre le **chapitre 3**, consacré à trois notions simples : **`print()` en Python**, **la balise de titre HTML `<h1>`**, et **`# ` pour un titre Markdown**. Les postes présentent une consigne, des réponses au choix et des erreurs expliquées. Aucun interpréteur ni code utilisateur n’est exécuté. L’ascenseur permet de revenir aux étages débloqués ; les trois chapitres ont leur tableau de missions et leur bilan. [Parcours et réponses](ENQUETE.md).

Les neuf missions rapportent **50 points une seule fois chacune**, soit **450 au maximum par profil**. Sans autre dépense, deux jeux Test à 200 points laissent 50 points. Les Test restent des jeux en préparation. Rejouer ne redonne pas de points ; les anciens profils conservent leurs réussites, points, achats et équipement, puis reçoivent les missions manquantes. Les profils et photos personnelles ne sont pas distribués. La présentation des README est conservée pour les prochaines mises à jour, avec les liens Windows, Linux, puis le descriptif.

## Vérifications 0.7.0

Recette exécutée le **15 octobre 2026**, avec des données isolées :

| Périmètre | Résultat |
|---|---|
| Sources, 23 suites | **13 512 assertions, zéro échec** |
| Persistance entre trois processus Godot | **65 assertions, zéro échec** |
| Migration comparée au validateur réel 0.6.1 | **259 anciens profils valides migrés sans perte** |
| Rendu réel X11 / OpenGL ES 3.2, Mesa 25.0.7 llvmpipe | **395 contrôles, zéro échec**, 9 captures |
| Pack Windows exécuté avec Godot Linux x86_64, 8 suites | **1 409 assertions, zéro échec** |
| Pack ARM64 exécuté avec Godot Linux x86_64, 8 suites | **1 409 assertions, zéro échec** |
| Ressources intégrées, par paquet | **213 empreintes MD5 intactes**, dont **48 SVG** |
| Outils de packaging Windows / Linux | **27 / 47 contrôles, zéro échec** |

[Résumé détaillé de la recette 0.7.0](../tests/chapitre_3_0.7.0_results/summary.json). Les 259 profils de migration sont des cas comparés entre les validateurs ; ce nombre est distinct des assertions des suites.

Captures réelles : [arrivée dans l’atelier du code](screenshots/chapitre_3_0.7.0/chapter_3_arrival.png), [exercice Python](screenshots/chapitre_3_0.7.0/chapter_3_python_challenge.png), [bilan du chapitre 3](screenshots/chapitre_3_0.7.0/chapter_3_conclusion.png) et [800 × 480 avec grand texte](screenshots/chapitre_3_0.7.0/chapter_3_800x480_large.png).

| Paquet portable | Taille | SHA-256 |
|---|---:|---|
| [Windows x86_64](../builds/Console_CIEL_Windows_x86_64_code_0.7.0.verification.json) | 36 640 581 octets | `af33ad5f04e19b933d8dcd637e485c2de426c001fbf063f8b6bd6091b71e0034` |
| [Raspberry Pi ARM64](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.7.0.verification.json) | 27 046 296 octets | `397473a3bac24c742911c833935fdd8321dc90bff7a63f76a43b120ec966bd21` |

Les rapports liés décrivent le contenu et les empreintes des paquets. Les résultats historiques ci-dessous restent propres à leurs versions.

Les ressources compilées peuvent être exécutées avec le moteur Linux x86_64 pour contrôler leur logique ; cela ne constitue pas un lancement natif de l’EXE Windows ni du binaire ARM64. Le lancement sur Windows et Raspberry Pi 4, le GPU du Pi, le son et une manette physique restent à essayer sur les appareils destinataires. Le lanceur Raspberry Pi conserve Compatibility / OpenGL ES 3 ; aucun autostart, service ou arrêt système n’est ajouté.

# Livraison historique 0.6.1 — Raspberry Pi 4 ARM64

[Logiciel Raspberry Pi prêt à lancer](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Raspberry_Pi_ARM64_0.6.1.zip) et [projet complet Raspberry Pi](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.6.1.zip). La cible confirmée est **Raspberry Pi 4, système 64 bits** ; utiliser Raspberry Pi OS avec bureau, architecture **aarch64**, de préférence Bookworm ou Trixie à jour.

Extraire entièrement le paquet Raspberry Pi et lancer `bash ./Lancer_Console_CIEL.sh` dans son dossier. Dans le projet complet, le lanceur et **console-ciel.arm64** se trouvent dans `console-ciel/builds/linux-arm64-raspberry-pi-0.6.1/`. Godot n’est pas nécessaire pour jouer ; les ressources sont intégrées dans le binaire. `Installer_raccourci.sh` ajoute facultativement l’application au menu du bureau. [Notice Linux](../builds/README_LINUX.md), [guide Raspberry Pi](RASPBERRY_PI.md) et [contenu du projet complet](ARCHIVE_COMPLETE.md).

Le jeu conserve les fonctionnalités de la livraison Windows **0.6.1** : profil, avatar et points en haut à gauche ; deux chapitres et six missions ; ascenseur ; panneau de missions ; repères masqués après réussite sauvegardée ; jeux Test à **200 points chacun** ; profils et photos locales, clavier, thèmes, couleurs et crédits. Aucun profil personnel, achat ou solde de test n’est ajouté. La livraison Windows et ses anciennes archives sont conservées.

## Vérifications de la livraison Raspberry Pi

Le [rapport ARM64](../builds/Console_CIEL_Raspberry_Pi_ARM64_0.6.1.verification.json) décrit l’exécutable **ELF / AArch64**, les exigences de bibliothèques, son pack intégré, les CRC et les empreintes des fichiers. Le modèle officiel requiert des symboles jusqu’à **GLIBC 2.28**. Le lanceur sélectionne **gl_compatibility / opengl3_es** et utilise la session graphique X11 ou Wayland de l’utilisateur. Le [rapport du projet complet Raspberry Pi](../builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.6.1.verification.json) inventorie les sources et la livraison courante.

Vérifications exécutées le **14 octobre 2026**, avec données isolées :

| Périmètre | Résultat |
|---|---|
| Pack ARM64 compilé, exécuté avec Godot Linux x86_64 | **6 218 assertions, zéro échec**, 11 suites dont 8 contrats de plateforme |
| Rendu réel X11 / OpenGL ES 3.2, Mesa 25.0.7 llvmpipe | **58 contrôles, zéro échec**, 8 captures temporaires |
| Lanceur et raccourci utilisateur | **17 tests, zéro échec** |
| Vérification et assemblage des paquets Linux | **47 assertions, zéro échec** |
| Contrats des presets, en lecture seule | **13 contrôles, zéro échec** |
| Régression des outils de packaging Windows | **27 contrôles, zéro échec** |
| Ressources intégrées et archive portable | **203 empreintes MD5 contrôlées**, dont 43 SVG ; CRC du ZIP vérifiés |

[Résumé Raspberry Pi et portée des tests](../tests/raspberry_pi_0.6.1_results/summary.json). Le ZIP portable mesure **27 026 535 octets** ; l’exécutable ELF ARM64 mesure **65 476 296 octets**. SHA-256 du ZIP : `96ea7e0c50e5015c7eb13188ccb38f24a14865587813f045f833192a7e7eddde`.

Les contrôles de l’export ARM64 et les essais des ressources embarquées avec **Godot Linux x86_64** sont consignés séparément : un test du pack avec ce moteur ne signifie pas que le binaire ARM64 a été exécuté sur le Pi. Les résultats Windows précédents ci-dessous restent propres à leur livraison ; ils ne sont pas des tests natifs Raspberry Pi.

Aucun Pi physique n’est disponible dans l’environnement cloud. Le rendu réel décrit ci-dessus est effectué sous Linux x86_64 avec un pilote graphique logiciel et une sortie audio Dummy ; il ne valide pas le son perçu ou le GPU du Pi. Le lancement ARM64 natif, le rendu matériel, les performances, le son, le plein écran et la manette réelle restent à essayer sur le **Pi 4**. Le mapping du contrôleur de la console doit être mesuré avec le test des commandes ; aucun FPS matériel n’est annoncé comme mesuré. Le lanceur conserve les données utilisateur et ne crée ni autostart, ni service système, ni commande d’arrêt.

# Livraison Windows conservée 0.6.1 — confort visuel et tarifs

[Projet complet](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.6.1.zip) et [Windows prêt à lancer](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_confort_0.6.1.zip). Décompresser tout le ZIP Windows et ouvrir **Console_CIEL.exe**. Dans le projet complet, il se trouve sous `console-ciel/builds/windows-x86_64-confort-0.6.1/`. [Guide de l’archive](ARCHIVE_COMPLETE.md).

Le profil actif, son avatar et ses points sont en haut à gauche, y compris pendant l’enquête. La barre inférieure conserve quatre onglets centrés et ne répète plus le pseudo ni le solde. Les quatre emplacements **Test 1 à Test 4** coûtent **200 points chacun** ; les jeux déjà acquis restent possédés sans supplément.

Après une mission réussie et sauvegardée, son repère et son bouton d’interaction disparaissent. Le décor reste visible dans son état réparé ; l’ascenseur reste utilisable dans les deux chapitres. Une reprise conserve cet état et une nouvelle partie rétablit les repères des missions à refaire. **Pause → Bilan du chapitre** permet de revoir un chapitre terminé. [Parcours manuel](ENQUETE.md).

Les six missions rapportent toujours **50 points à leur première réussite**, au maximum **300 par profil**, sans nouveau gain lors d’un rejeu. Sans autre dépense, quatre premières réussites financent un jeu ; après les six missions et cet achat, il reste 100 points. Les quatre jeux coûtent 800 points au total : les autres achats attendent de futurs défis ou un solde déjà présent dans un ancien profil. Les Test restent des emplacements de préparation, sans gameplay ni récompense supplémentaires. [Bibliothèque et tarifs](BIBLIOTHEQUE_ET_THEMES.md).

## Rapports de la livraison courante

Le [rapport Windows 0.6.1](../builds/Console_CIEL_Windows_x86_64_confort_0.6.1.verification.json) et le [rapport du projet complet 0.6.1](../builds/Console_CIEL_Projet_Complet_0.6.1.verification.json) détaillent contenu et empreintes. Les recettes distinguent logique source, rendu réel sous Linux, contrats Windows et ressources embarquées exécutées avec Godot Linux. Les résultats historiques ci-dessous restent ceux de leurs versions respectives.

Recette exécutée le **14 octobre 2026**, avec données temporaires isolées :

| Périmètre | Résultat |
|---|---|
| Sources, 16 suites | **11 844 assertions, zéro échec** |
| Persistance entre trois processus Godot réels | **65 assertions, zéro échec** |
| Rendu X11 Linux, Mesa llvmpipe / Compatibility | **58 contrôles, zéro échec**, 8 captures |
| Pack réellement embarqué dans l’EXE Windows, exécuté avec Godot Linux | **6 547 assertions, zéro échec** |
| Contrats de configuration Windows | **18 contrôles, zéro échec** |
| Outils de packaging | **27 contrôles, zéro échec** |
| Ressources du pack | **203 empreintes contrôlées**, dont 43 SVG ; CRC du ZIP vérifiés |
| Audit statique du projet | **818 fichiers, 72 UID, 194 références**, zéro erreur |
| Chargement des ressources avec Godot Linux | **203 contrôles, zéro échec** |

[Résumé détaillé et empreintes des journaux](../tests/confort_0.6.1_results/summary.json). Les contrôles couvrent le profil en haut à gauche, les prix à 200 points, l’achat refusé à 199 et accepté à 200 après quatre missions réussies, les achats antérieurs, les repères des six missions, la reprise, le rejeu, l’ascenseur et le bilan en pause.

Les huit captures réelles montrent :

- [Accueil, profil à gauche et prix à 200 en 1280 × 720](screenshots/confort_0.6.1/home_profile_left_prices_200_1280x720.png).
- [Accueil en 800 × 480 avec grand texte](screenshots/confort_0.6.1/home_profile_left_800x480_large.png).
- [Accueil en 800 × 480 avec style Nuit](screenshots/confort_0.6.1/home_profile_left_800x480_nuit.png).
- [Boutique, quatre jeux à 200 points](screenshots/confort_0.6.1/shop_prices_200_1280x720.png).
- [Commande de porte avant réussite, avec repère](screenshots/confort_0.6.1/door_before_success_marker.png).
- [Commande de porte après réussite, sans repère ni bouton d’interaction](screenshots/confort_0.6.1/door_after_success_no_marker.png).
- [Chapitre terminé, sans repères de missions](screenshots/confort_0.6.1/chapter_completed_no_mission_marker.png).
- [Ascenseur toujours disponible après les missions](screenshots/confort_0.6.1/elevator_available_after_missions.png).

Le rendu Linux utilise le pilote audio Dummy et ne valide pas le son perçu. Le pilote graphique ne prend pas en charge le changement de VSync. La fermeture verbose signale un unique StringName `process_frame` non libéré, sans fuite d’instance ObjectDB. Les contrôles de manette utilisent des périphériques virtuels ; la corruption ConfigFile est provoquée uniquement dans des données de test.

Le [guide Windows](WINDOWS.md) décrit les contrôles manuels : profil en haut à gauche, quatre prix à 200, refus sous 200 points, achats antérieurs conservés, repères masqués après réussite et relance, repères rétablis en nouvelle partie, absence de récompense répétée, bilan en pause et ascenseur dans les deux sens. Le lancement natif, le son et une manette USB physique sous Windows restent à essayer sur le PC destinataire. Le contrôleur de la console et les performances Pi restent à mesurer sur le matériel réel.

# Historique — livraison 0.6.0 : enquête, chapitre 2

[Projet complet](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.6.0.zip) et [Windows prêt à lancer](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.zip). Décompresser tout le ZIP Windows et ouvrir **Console_CIEL.exe**. Dans le projet complet, il se trouve sous `console-ciel/builds/windows-x86_64-chapitre-2-0.6.0/`. [Guide de l’archive](ARCHIVE_COMPLETE.md).

Le chapitre 1 est conservé. Après ses trois missions, l’ascenseur en bas du bureau conduit à la salle réseau : liaison RJ45, adressage IPv4 et protection Wi-Fi. Le tableau de missions compact à droite s’ouvre et se ferme par son bouton, **T** ou le **bouton de face haut**. Chaque chapitre possède son bilan ; les nouveaux gains de la partie restent cumulés entre les étages. [Explications et parcours manuel](ENQUETE.md).

Les six premières réussites rapportent **50 points chacune**, au maximum **300 par profil**. Rejouer conserve les identifiants de récompense et ne rapporte pas ces points une seconde fois. Les anciens profils reçoivent les missions du chapitre 2 sans perdre réussites, observations, portefeuille, achats ni équipement. La progression de salle et de chapitre est persistée. Toutes les manipulations restent fictives et hors ligne ; aucun réglage réseau réel n’est changé.

La bibliothèque, les emplacements **Test 1 à Test 4**, les styles/couleurs, les crédits, les images locales et le clavier de la version 0.5.0 restent disponibles. Les Test sont toujours des emplacements provisoires, et leur ouverture ne rapporte aucun point. Les anciennes livraisons sont conservées dans le dépôt.

## Vérifications de la livraison historique 0.6.0

Le [rapport Windows](../builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.verification.json) et le [rapport du projet complet](../builds/Console_CIEL_Projet_Complet_0.6.0.verification.json) décrivent les empreintes et le contenu des deux archives. La recette distingue tests de logique avec données isolées, affichage réel sous Linux, configuration Windows et exécution du pack compilé avec Godot Linux.

Recette exécutée le **14 octobre 2026**, avec données temporaires isolées :

| Périmètre | Résultat |
|---|---|
| Sources, 14 suites | **9 568 assertions, zéro échec** |
| Persistance entre trois processus Godot réels | **65 assertions, zéro échec** |
| Rendu X11 Linux, Mesa llvmpipe / Compatibility | **694 contrôles, zéro échec**, 12 captures |
| Pack réellement embarqué dans l’EXE Windows, exécuté avec Godot Linux | **4 351 assertions, zéro échec** |
| Contrats de configuration Windows | **18 contrôles, zéro échec** |
| Outils de packaging | **27 contrôles, zéro échec** |
| Ressources du pack | **203 empreintes contrôlées**, dont 43 SVG ; CRC du ZIP vérifiés |
| Audit statique du projet | **797 fichiers, 70 UID, 191 références**, zéro erreur |
| Chargement des ressources avec Godot Linux | **199 contrôles, zéro échec** |

[Résumé détaillé et empreintes des journaux](../tests/chapitre_2_0.6.0_results/summary.json). Les captures montrent l’[ascenseur déverrouillé](screenshots/chapitre_2_0.6.0/chapter_1_elevator_unlocked.png), l’[arrivée à l’étage](screenshots/chapitre_2_0.6.0/chapter_2_arrival_missions.png), les trois défis et le panneau ouvert ou replié à 1280 × 720, 1024 × 600 et 800 × 480, en texte normal ou grand. [Les 12 captures](screenshots/chapitre_2_0.6.0/).

L’affichage Linux utilise un rendu logiciel et un pilote audio Dummy ; ces essais ne valident pas le son perçu. Le pilote signale que le réglage VSync n’est pas pris en charge. Les tests de manette emploient des événements et périphériques virtuels. La suite générale provoque volontairement la corruption de son propre fichier de paramètres pour vérifier la récupération.

Ces contrôles ne remplacent pas le lancement natif, le son ou une manette USB physique sur Windows. Le contrôleur de la console reste à mesurer sur le matériel réel ; les tests virtuels ne prouvent pas son mapping. Les limites Raspberry Pi et d’alimentation sont conservées dans [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

# Historique — livraison 0.3.0 intégrée

Les noms d’archives et résultats ci-dessous décrivent la livraison historique reçue. Les anciens exécutables 0.3.0/0.3.1 n’étaient pas inclus dans les sources fournies. La phrase « Tests visuels exécutés : aucun » dans cet historique concerne cette recette ancienne ; elle ne décrit pas les captures des versions ultérieures.

Projet natif Godot **4.6.3.stable.official.7d41c59c4**, édition standard, GDScript, rendu **Compatibility**. Cette version stabilise le menu et l'enquête existants ; elle n'ajoute pas de nouvelle enquête et conserve les profils, le portefeuille, les cosmétiques et le format d'enquête 0.2.0.

## Corrections et compléments

- Démarrage par étapes réelles : réglages, catalogue et règles, profils, thème et accessibilité ; création proposée sans profil. Les erreurs essentielles offrent un réessai qui relit les données livrées.
- Récupération explicite des profils, réglages et session, y compris lorsqu'il ne reste qu'une copie précédente. Les documents défectueux sont conservés et ne sont pas écrasés silencieusement.
- Transitions, focus et confirmations protégés contre la validation traversant plusieurs écrans et les dialogues superposés. Les paramètres ouverts depuis la pause reviennent à cette pause.
- Manette active unique, mapping configurable, pause à sa déconnexion et reprise explicite. Le clavier reste disponible ; le test des commandes présente noms, GUID, boutons, axes, zone morte et état de repos réellement reçus.
- Fermeture avec brouillon de réglages et erreur de sauvegarde traitée explicitement. Les transactions conservent le dernier état cohérent et les erreurs importantes restent visibles jusqu'à une action.
- Diagnostic debug F3 : versions, résolution, renderer, FPS observés, profil interne, contrôleur et dernière erreur de stockage. Aucun état fictif de batterie, température ou réseau.
- Outil de démonstration réservé au développement : données isolées, profil identifié par manifeste, remise à zéro ciblée et préremplissage facultatif utilisant la validation métier.
- Guides de soutenance et d'installation Pi avec conservation des données, copie de versions et retour arrière. Aucun deuxième autostart ni arrêt système inventé.

Le parcours est conservé : sélection du profil → menu → enquête et trois défis → sauvegarde → menu → boutique/inventaire → équipement → fermeture → relance. Les missions sont de vraies activités jouables dans une simulation pédagogique fictive. Réussite, points et récompense sont enregistrés ensemble ; un rejeu ne donne pas une seconde récompense.

## Vérifications exécutées et preuves

Les résultats de recette intégrée sont dans [TESTS.md](TESTS.md), [UI_TESTS.md](UI_TESTS.md) et [tests/release_results/summary.json](../tests/release_results/summary.json). Exécution réelle le **11 octobre 2026 à 15:58 UTC** : **2 500 assertions, zéro échec**, huit jobs complets et sorties 0. Les fermetures réelles ajoutent **105 assertions, zéro échec**, et la préparation démo **36 vérifications, zéro échec**. Godot est lancé en mode **headless**, avec des données temporaires isolées. Les événements clavier/manette et la physique du moteur sont réellement utilisés ; les périphériques déclarés pour la connexion sont explicitement virtuels.

| Vérification | Résultat ou portée | Preuve |
|---|---|---|
| Services, profils, boutique, réglages et récupération | 190 assertions, zéro échec | [business.log](../tests/release_results/business.log) |
| Trois défis, progression, migration et transactions | 189 assertions, zéro échec | [investigation.log](../tests/release_results/investigation.log) |
| Persistance après deux fermetures/relances | 65 assertions, zéro échec, dans trois processus Godot indépendants | `tests/release_results/persistence_*.log` |
| Politique de manette active et action F3 | 22 assertions, zéro échec sur périphériques virtuels de test | [controllers.log](../tests/release_results/controllers.log) |
| Interface, collisions, focus et géométrie | 1 937 assertions, zéro échec | [native_ui.log](../tests/release_results/native_ui.log) |
| Démarrage, réessais et récupération | 97 assertions, zéro échec | [stability.log](../tests/release_results/stability.log) |
| Quatre fermetures avec brouillon et erreurs d'écriture | 105 assertions, zéro échec ; lecture des documents après sortie | [close_summary.json](../tests/stability_results/close_summary.json) |
| Préparation et remise à zéro de démonstration | 36 vérifications, zéro échec ; second profil conservé | [demo-preparation-results.log](../tests/demo-preparation-results.log) |
| Pack de ressources ARM64 0.3.0 | CRC contrôlés ; démarrage headless 30 frames sans erreur | `tests/pack-launch-results.log` |
| Export autonome ARM64 0.3.0 | Échec explicite, sortie 1 : modèles `linux_debug.arm64` et `linux_release.arm64` absents | `tests/arm64-export-results.log` |

Les résultats précédents **0.2.0** — 190 services, 189 enquête et 1743 interface — restent historiques. Ils ne servent pas seuls à prouver les nouveaux comportements de connexion et de fermeture. La corruption volontaire d'un ConfigFile temporaire peut produire son message de parse attendu ; elle est suivie du contrôle de récupération. Une sortie 0 sans lecture du journal ne suffit pas.

Une relance rapide de l'interface a également réussi **309 assertions, zéro échec** dans [stability-ui-quick-results.log](../tests/stability-ui-quick-results.log). Elle recoupe les scénarios complets et n'est pas ajoutée au total de référence.

**Tests visuels exécutés : aucun.** Aucun affichage graphique utilisable n'est disponible ici et aucune capture censée prouver un rendu n'est fabriquée. La géométrie des contrôles à 1280 × 720, 1024 × 600 et 800 × 480, en texte normal/grand et transparence réduite, est testable en headless ; elle ne remplace pas l'inspection du contraste et de la lisibilité à l'écran.

**Tests manuels restants sur PC :** parcours complet sans souris avec affichage, qualité visuelle, sons perçus, plein écran et déconnexion/reconnexion USB physique. **Tests matériels restants sur Pi :** binaire ARM64, labwc, écran final, contrôleur fabriqué, mapping, son, performances et comportement de l'alimentation. Aucune température ni performance Pi n'est annoncée comme mesurée par ce projet.

## Lancer et présenter

```sh
godot --headless --path . --import
godot --path .
# Profil de soutenance et données séparées, conservés à la relance :
./tools/run_demo.sh
```

Sélectionner un profil puis **Commencer / Nouvelle partie**, ou **Continuer**. Flèches/ZQSD pour marcher, Espace pour interagir, flèches/Entrée pour les défis, Échap pour revenir et P pour la pause. [README](../README.md), [parcours de soutenance](DEMONSTRATION.md) et [explications pédagogiques](ENQUETE.md).

L'archive source `console-ciel-source.zip` (ancien nom d’archive) se régénère avec `python3 tools/package_source.py`, sans caches ni profils personnels. L’archive a également été extraite dans un dossier temporaire neuf : import avec Godot puis lancement 30 frames réussis, sans erreur de script ; journaux `tests/source-import-results.log` et `tests/source-launch-results.log`. Le pack `console-ciel-arm64.zip` (ancien nom d’archive) **0.3.0** inclut contrôleur, mapping JSON, démarrage, diagnostic et ressources de l'enquête ; outils, tests et docs de développement en sont exclus. Il a été chargé par le moteur Godot installé, mais **ce n'est pas un exécutable autonome ARM64**.

L'export du pack retourne 0. Son journal d'éditeur comporte des refus de socket TCP liés au sandbox de cet environnement ; le lancement de ce pack est propre. L'export du binaire autonome retourne 1 pour absence des modèles 4.6.3. Ces résultats ne sont ni un lancement Raspberry Pi ni un contrôle du rendu graphique.

## Fichiers intégrés

| Fichiers | Changement de cette version |
|---|---|
| `project.godot`, `export_presets.cfg` | Version logiciel, service contrôleur et export ARM64 conservé |
| `scenes/startup.tscn`, `scripts/ui/startup_panel.gd` | Chargement par étapes réelles sans durée artificielle |
| `scripts/ui/main.gd`, `confirmation_dialog.gd` | Démarrage, transitions, erreurs, fermeture et diagnostic |
| `scripts/services/controller_service.gd`, `scripts/input_setup.gd`, `data/controller_mapping.json` | Manette active et associations d'actions configurables |
| `scripts/ui/joy_navigation.gd`, `input_monitor.gd` | Filtrage et diagnostic des entrées |
| `scripts/ui/diagnostics_panel.gd` | Diagnostic de développement avec valeurs disponibles réelles |
| `scripts/game/demo_game.gd` | Pause lors d'une perte de manette, préservation de la session et reprises |
| `scripts/services/save_service.gd`, `profile_service.gd`, `settings_service.gd`, `shop_service.gd`, `reward_service.gd` | Récupération, réessai et suivi de dernière erreur réelle |
| `tests/stability_tests.gd`, `controller_tests.gd`, `process_persistence.gd`, `ui_smoke.gd` | Recette de stabilité, navigation et relances indépendantes |
| `tests/close_persistence.gd`, `tools/check_close.py` | Quatre fermetures réelles et vérification externe des documents |
| `tools/run_acceptance.py`, `run_demo.sh`, `prepare_demo.gd`, `check_demo.py` | Recette groupée et préparation de démonstration isolée |
| `README.md`, `docs/` | Lancement, soutenance, installation Pi, limites et résultats |

Le thème, les données pédagogiques, les trois missions et les ressources locales originales sont réutilisés. Les crédits/licences restent sous `assets/` ; le nom du binôme est encore à compléter.

## Ce qui reste bloquant avant une démonstration sur Pi

Les modèles d'export **Linux ARM64 4.6.3 stable** restent absents : les presets sont configurés, mais aucun binaire ARM64 autonome n'est livré ou testé ici. Installer ces modèles, exporter puis jouer sur le Pi est nécessaire. Le pack de ressources chargeable par Godot ne remplace pas cette étape.

La source peut être présentée sur PC avec Godot après répétition visuelle et manette. Pour la soutenance sur Pi, vérifier le rendu réel, la lisibilité, le plein écran labwc, le son et le contrôleur. [Liste de recette matérielle et problèmes connus](KNOWN_ISSUES.md).

**Quitter** ferme seulement l'application après sauvegarde. **Arrêt système non configuré** reste indisponible dans PlatformService. Le lanceur automatique distinct doit lancer `current/console-ciel.arm64 --fullscreen` dans la session utilisateur ; ses fichiers ne sont pas présents dans ce dépôt. L'arrêt de Raspberry Pi OS et la coupure électrique restent distincts et ne sont pas prétendus fonctionnels dans l'application.

## Complément Windows — 12 octobre 2026

La version portable Windows x86_64 (`Console_CIEL_Windows_x86_64.zip`, nom historique ; utiliser la livraison 0.6.1) a été réellement exportée avec Godot officiel 4.6.3 et ses modèles Windows correspondants. Décompresser puis lancer **Console_CIEL.exe** sans installer Godot. Le [guide Windows](WINDOWS.md) indique les commandes, données utilisateur, script PowerShell de réexport et résultats détaillés.

Le preset Windows, le nom de l'exécutable, la fenêtre initiale redimensionnable et l'affichage du chemin utilisateur dans À propos ont été complétés. La fermeture par la croix réutilise la confirmation et la sauvegarde existantes. Les fichiers associés, aide et licences sont inclus ; aucune sauvegarde personnelle n'est distribuée. Le script PowerShell conserve la livraison précédente si l'export échoue ; le remplacement d'un ZIP existant a été corrigé et testé.

La nouvelle recette source passe **3 694 assertions**, les fermetures **105**, le pack réellement embarqué **47**, les contrats Windows **16** et l'exporteur PowerShell **22**, tous sans échec. L'exécutable PE x86_64 non signé et les **95 fichiers intégrés** ont été contrôlés, ainsi que les CRC de l'archive. Les tests de logique et du pack sont exécutés avec le moteur Linux headless ; **aucun lancement Windows ni rendu visuel n'est annoncé comme testé**. Essayer le parcours de recette Windows sur le PC destinataire avant la démonstration.
