# Commandes triches — Console CIEL

**Version 0.19.0 · profil Dev uniquement**

Dans **Profil**, sélectionner **Dev · Super administrateur**, puis **Ouvrir le terminal Dev**. Pendant une partie, ouvrir **Pause → Terminal Dev**. Un joueur ordinaire nommé « Dev » ne dispose pas du terminal.

Saisir une commande et choisir **Valider**, ou appuyer sur Entrée. Le clavier virtuel propose les minuscules, **Maj**, **123** et les symboles. **Échap**, la touche droite de la manette ou **Annuler** ferment le terminal. Pendant son ouverture dans le jeu, les déplacements et la circulation sont suspendus.

| Commande | Exemple | Résultat |
|---|---|---|
| `help` | `help` | Affiche toutes les commandes. |
| `status` | `status` | Affiche le solde, la dette, la salle et le nombre de défis réalisés. |
| `add coins <montant>` | `add coins 500` | Ajoute **500 points** au solde de Dev. Remplacer 500 par le montant voulu. |
| `skip missions` | `skip missions` | Valide **un seul objectif actuel**, sans ajouter de points. |
| `skip mission` | `skip mission` | Alias de `skip missions`. |
| `reset missions` | `reset missions` | Recommence un parcours **rejouable** dans la première salle avec les défis à résoudre. |
| `clear` | `clear` | Efface seulement l’historique affiché dans le terminal. |

## Ajouter le montant de son choix

```text
add coins 2500
```

Cette commande ajoute **2 500 points** au solde actuel. Le montant doit être un **entier positif**, sans signe ni séparateur : écrire `2500`, pas `2 500`, `2.5k` ou `-2500`. Le solde total ne peut pas dépasser **2 147 483 647**.

Les points ajoutés vont directement dans le portefeuille ; la dette de pénalités reste inchangée. Les récompenses normales du jeu continuent à rembourser cette dette en priorité. Les achats, équipements et défis ne sont pas modifiés par `add coins`.

## Passer l’objectif actuel

```text
skip missions
```

Dans le premier bâtiment, la commande valide la première mission encore inachevée de **l’étage actuel**, avec les observations, vérifications et indices nécessaires. Elle passe aussi le mystère du labyrinthe. Si l’étage est déjà terminé, elle invite à prendre l’ascenseur ou la porte ; elle ne valide pas tous les étages d’un coup.

À l’hôtel, elle passe l’étape courante : réservation, réparation, affaires déposées, sommeil, petit déjeuner, café, sac ou trajet. Elle peut déplacer Dev au point de reprise correspondant. Au CTF, chaque appel valide **un seul poste**, puis le dernier appel permet de revenir en ville après les cinq postes terminés.

Le saut **n’ajoute aucun point**. Il enregistre les reçus des objectifs passés pour que les rejouer ne donne pas une récompense en double. Les autres profils restent inchangés.

## Rejouer les missions avec Dev

Le compte Dev neuf possède déjà les défis validés. Pour tester leur déroulement :

```text
reset missions
```

Le rôle de Dev, son solde, ses achats, ses images, ses équipements, ses pénalités et ses reçus de récompenses sont conservés. Les missions du parcours deviennent à nouveau jouables. Les récompenses déjà reçues ne seront pas attribuées une seconde fois.

**Paramètres → Réinitialiser la progression** conserve son fonctionnement habituel : cette option remet Dev au début avec les défis validés. La commande `reset missions` sert à tester un parcours à résoudre.

## Sauvegarde et accès

Les modifications passent par la validation et la sauvegarde habituelles du profil avant de changer le jeu. En cas de refus d’écriture, le solde et la progression précédents sont conservés ; le terminal affiche l’erreur et permet de réessayer.

Les commandes ne s’exécutent jamais sur le système Windows ou Linux. Ce terminal modifie uniquement les données locales du profil Dev dans Console CIEL.

[Solutions de tous les défis](README.md) · [Présentation du logiciel](../console-ciel/README.md)
