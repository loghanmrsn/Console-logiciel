# Dev — super administrateur

Dans **Profil**, choisir **Dev · Super administrateur**. Le même bouton est disponible sous le clavier de création au premier lancement. Il crée le compte local dédié au premier usage, puis retrouve ce même compte lors des usages suivants. Son nom est **Dev** et son rôle **Super administrateur**, visible sur sa carte et dans sa présentation.

## Progression disponible

Les **treize défis éducatifs** sont terminés avec leurs observations, vérifications et indices : éclairage, porte, ordinateur, RJ45, IPv4, Wi-Fi, Python, HTML, Markdown, pare-feu, conflit IP, masque réseau et défi mystère. Les cinq chapitres sont accessibles par l’ascenseur.

Le séjour est également prêt : chambre réservée, panne informatique réparée avec ses quatre observations, affaires déposées, nuit passée, café réparé et pris, puis sac récupéré. Le profil commence dans la première salle, avec **1 000 points pour une nouvelle création** correspondant aux récompenses uniques déjà comptabilisées. Le bus vers le CTF reste disponible depuis la cour. Les cinq postes du CTF Sudo Hack sont également validés. Un Dev créé avant la version 0.18.0 conserve sa sauvegarde et son solde : utilisez **Paramètres → Réinitialiser la progression** pour lui ajouter les validations du CTF sans nouveau crédit.

Les achats utilisent le solde enregistré. Sélectionner Dev à nouveau retrouve ses achats, points, apparence et progression sans créer de doublon ou crédit supplémentaire. Une réinitialisation remet Dev au début du bâtiment en conservant tous les défis validés, les achats, le solde et les pénalités. Les avatars et photos peuvent être personnalisés ; le nom dédié reste Dev.

## Profils et sauvegardes

L’ouverture de Dev est explicite : aucun profil de joueur n’est remplacé ou promu automatiquement. Un profil ordinaire appelé Dev garde ses règles de joueur ; le bouton dédié sélectionne le compte super administrateur. Les autres profils commencent et rejouent normalement. Le rôle est un champ facultatif du schéma existant ; les anciens profils sans rôle restent compatibles.

Le compte Dev utilise un identifiant dédié. Ses données sont construites depuis les règles livrées puis passent le même validateur et les mêmes écritures atomiques que les autres profils. Un fichier Dev endommagé ou sa sauvegarde précédente n’est jamais remplacé par un compte neuf ; l’écran de récupération reste disponible. Un refus d’écriture conserve le profil actif.

[Bilan de livraison](DELIVERY.md) · [Résumé de recette](../tests/ctf_0.18.0_results/summary.json) · [Profils et clavier](PROFILS_ET_CLAVIER.md).

## Terminal Dev — 0.19.0

Depuis Profil ou Pause, ouvrir **Terminal Dev**. `add coins 500` ajoute le montant choisi ; `skip missions` passe un seul objectif sans points. `reset missions` prépare un parcours rejouable, distinct de la remise en place habituelle de Dev. Solde, achats et reçus sont conservés. [Liste complète des commandes](https://github.com/loghanmrsn/Console-logiciel/blob/main/solution/commandes%20triches.md).
