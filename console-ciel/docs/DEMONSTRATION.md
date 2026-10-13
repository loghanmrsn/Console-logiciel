# Démonstration de la console CIEL 0.3.0

La démonstration utilise l'application native et ses transactions normales. Prévoir un PC avec affichage et Godot **4.6.3 stable**, puis essayer le même parcours sur le Raspberry Pi après export. Les essais matériels et visuels doivent précéder la soutenance ; les tests headless ne remplacent pas cette répétition.

## Préparer un profil dédié sans toucher aux joueurs

Depuis la racine du projet, l'outil de développement prépare un environnement séparé et lance l'application :

```sh
./tools/run_demo.sh
```

Par défaut, les données sont dans `builds/demo-runtime/data/console-ciel/`, avec configuration et cache séparés. Le profil **CIEL Démo** est neuf, avec **0 point**. Relancer cette commande conserve son état. Un verrou `flock` (util-linux) interdit deux préparations ou sessions utilisant simultanément cette même racine ; des racines distinctes restent indépendantes. Les profils habituels de `~/.local/share/console-ciel/` ne sont pas utilisés.

```sh
# Préparer sans ouvrir de fenêtre :
./tools/run_demo.sh --prepare-only
# Racine de démonstration explicite, indépendante des données habituelles :
./tools/run_demo.sh --output /tmp/ciel-soutenance --prepare-only
# Variante explicite pour une présentation courte : éclairage réellement validé,
# récompense normale de 50 points, aucune autre mission donnée :
./tools/run_demo.sh --prefilled --prepare-only
```

`--prefilled` passe par la validation de l'enquête ; ce n'est pas un crédit automatique de test. L'outil est réservé au développement, exclu des exports et absent de l'interface de livraison. La racine possède un manifeste `.demo_manifest.json` avec l'identifiant du profil préparé. L'outil refuse une racine normale ou des données existantes sans manifeste valide.

La vérification automatisée de cette préparation est disponible avec `python3 tools/check_demo.py`. Elle utilise ses propres dossiers temporaires et ne lance pas de fenêtre ; elle vérifie aussi que la remise à zéro conserve un second profil de cette racine.

Pour recommencer seulement ce profil de démonstration :

```sh
./tools/run_demo.sh --reset --prepare-only
# Pour une racine choisie précédemment, redonner exactement son chemin :
./tools/run_demo.sh --output /tmp/ciel-soutenance --reset --prepare-only
```

La remise à zéro cible l'identifiant du manifeste puis crée un nouveau **CIEL Démo**. Elle conserve les autres profils de cette racine. Ne pas effacer tout le dossier utilisateur pour préparer une soutenance. Un manifeste endommagé demande une intervention explicite et ne donne pas l'autorisation de supprimer les fichiers voisins.

## Parcours de huit étapes

Compter environ cinq à huit minutes pour montrer une mission, un achat et une relance. Les trois missions complètes demandent davantage de temps. Utiliser un profil de démonstration neuf pour montrer le gain initial ; une récompense déjà obtenue ne sera pas attribuée à nouveau.

| Étape | Action à montrer | Résultat attendu |
|---|---|---|
| 1. Profil | Sélectionner **CIEL Démo**, ou créer un autre profil avec le clavier virtuel | Identifiant interne propre au joueur ; solde initial 0 |
| 2. Menu | Parcourir Nouvelle partie, Boutique, Profils, Paramètres et Aide sans souris | Focus visible ; Continuer indisponible sans partie commencée |
| 3. Paramètre | Ouvrir Accessibilité, activer grand texte, choisir Appliquer ; revenir | Changement lisible et conservé ; montrer Annuler sur un autre aperçu |
| 4. Enquête | Choisir Commencer ; marcher dans la salle et interagir avec le tableau | Murs et mobilier bloquent le personnage ; objectifs affichés |
| 5. Mission | Soumettre une boucle incomplète, lire l'explication, compléter les trois bonnes connexions | Éclairage rétabli, premier objectif Terminé, 50 points enregistrés |
| 6. Sauvegarde | Pause → Retour au menu ; montrer solde puis Continuer | Pièce éclairée et progression reprise ; aucun deuxième gain |
| 7. Cosmétique | Revenir au menu, Boutique ; acheter **Orbite** à 20 points, confirmer puis Équiper | Solde 30 ; avatar possédé et équipé ; changement visible dans le profil |
| 8. Relance | Quitter et confirmer ; relancer avec la même commande et sélectionner le profil | Grand texte, solde 30, avatar équipé et mission terminée conservés |

L'avatar **Orbite** correspond à `avatar_orbit` dans le catalogue livré. Si le catalogue a été modifié, choisir un cosmétique dont le prix est inférieur au solde réel et annoncer le nouveau solde attendu.

## Réponses utiles au présentateur

- **Éclairage** : sélectionner Source → interrupteur, Interrupteur → lampe, Lampe → retour source, sans autre liaison. Expliquer qu'une boucle fermée est nécessaire et que le circuit est une simulation fictive en très basse tension.
- **Serrure** : consulter les quatre observations. Le badge est reconnu, l'alimentation est correcte, la commande n'arrive pas et sa liaison est déconnectée. Choisir **Liaison de commande déconnectée**, puis **Reconnecter la commande**.
- **Ordinateur** : consulter les symptômes et les vérifications demandées, notamment alimentation et liaison vidéo. Choisir le câble vidéo débranché comme cause, puis sa reconnexion virtuelle. Lire le message et le bilan.

Après les trois missions d'un profil neuf, le bilan indique **150 nouveaux points** ; le solde peut être différent si des achats ont été effectués. Rejouer annonce que les récompenses déjà attribuées ne seront pas gagnées à nouveau.

## Répétition avant la soutenance

1. Jouer le parcours complet avec la manette réellement utilisée, sans souris. Vérifier zone morte et valeurs brutes dans le test des commandes.
2. Pendant l'enquête, retirer la manette active : la pause doit apparaître. Rebrancher et choisir explicitement Reprendre ; le clavier doit rester utilisable.
3. Ouvrir les paramètres depuis la pause puis revenir : le jeu doit rester en pause.
4. Essayer les trois résolutions, en texte normal et grand texte, écouter les sons et vérifier les informations affichées après relance.
5. Sur le Pi, essayer le binaire ARM64 dans la session labwc avec `--fullscreen`, puis mesurer les FPS. Ne pas annoncer une valeur non mesurée.

En cas d'écriture refusée, lire l'erreur et réessayer après résolution ; ne pas contourner le problème en fermant brutalement. Les essais de corruption et d'écriture impossible sont automatisés dans des copies isolées, jamais dans le profil destiné à la présentation.
