# Limites connues et vérifications avant démonstration

La version 0.4.0 est un projet natif intégré. La recette automatique utilise des données isolées et le moteur Godot installé. Les vérifications ci-dessous nécessitent un affichage ou le matériel final ; aucune capture ni valeur matérielle fictive n'est fournie.

| Point | État et conséquence | Vérification à effectuer |
|---|---|---|
| Export autonome | Windows x86_64 exporté et ZIP vérifié ; modèles Linux absents | Tester le ZIP sur Windows ; installer les modèles Linux, produire x86_64 et ARM64 puis lancer sur leurs cibles |
| Rendu réel | Rendu Godot X11/Mesa logiciel inspecté à 1920 × 1080, 1280 × 720, 1024 × 600 et 800 × 480, normal/grand ; captures dans `screenshots/refonte/` | Refaire l'inspection sur Windows et sur l'écran du Pi ; le rendu logiciel ne mesure pas ses performances |
| Windows et DPI | Export réussi ; aucun Windows natif dans cet environnement | Double-clic, audio, plein écran et échelles Windows 100 %, 125 %, 150 %, 200 % à essayer |
| Manette physique | Événements et cycle de connexion simulables, aucun périphérique USB réel utilisé ici | Essayer navigation complète, axes au repos, répétition, retrait/reconnexion, plusieurs manettes |
| Contrôleur fabriqué | Mapping USB HID encore inconnu | Mesurer boutons/axes avec le diagnostic, configurer le mapping et refaire la recette |
| Avertissement audio de fermeture | Certaines fixtures X11 avec sortie Dummy signalent un WAV/playback résiduel à la fermeture ; essais fonctionnels réussis | Contrôler la fermeture et le journal avec un vrai pilote audio Windows/Pi |
| Son et plein écran | Logique de volume testable ; son perçu et fenêtre graphique non vérifiés ici | Écouter tous les bus, volume zéro, tester `--fullscreen` dans la session labwc |
| Performance Pi | Aucune mesure sur Raspberry Pi | Mesurer FPS et temps de réponse du menu et de l'enquête ; ne pas présenter 60 FPS comme acquis |
| Lanceur automatique | Livrable distinct absent du dépôt | Vérifier son chemin vers `current/console-ciel.arm64`, l'argument `--fullscreen` et l'ordre après ouverture du bureau |
| Arrêt système | Non configuré et indisponible dans PlatformService | Intégration future limitée aux droits de session, refus/échecs testés ; Quitter ferme seulement l'application |
| Coupure électrique | Écriture prudente avec copies, sans garantie contre toutes les coupures | Valider alimentation et arrêt propre du montage ; ne pas tester les coupures sur les vrais profils |
| Écran et coque | Dimensions et écran définitifs non fixés | Contrôler lisibilité à distance normale, format physique et accès aux contacts/joysticks |
| Crédits | Nom du binôme à compléter | Compléter les crédits avant redistribution finale |

## Répétition minimale sur PC avec affichage

1. Créer deux profils sans souris et vérifier l'absence de données communes.
2. Avec le premier, modifier puis annuler un paramètre ; l'appliquer et vérifier après relance.
3. Jouer les trois défis, soumettre une mauvaise réponse avant chaque correction, revenir au menu et reprendre après chaque mission.
4. Débrancher la manette active en jeu : pause et message, clavier disponible, reconnexion sans déplacement automatique, reprise explicite.
5. Acheter et équiper un cosmétique ; fermer normalement et retrouver mission, solde, équipement et paramètres.
6. Rejouer : aucune récompense supplémentaire. Tester plusieurs validations rapides et vérifier que les dialogues ne se superposent pas.
7. Vérifier 1920 × 1080, 1280 × 720, 1024 × 600 et 800 × 480, en texte normal et grand texte ; suivre le focus jusqu'au dernier bouton des écrans défilants.

Les corruptions et échecs d'écriture sont vérifiés automatiquement dans des copies de test. Une démonstration manuelle de ces cas doit également utiliser une racine isolée. Ne pas endommager les données normales pour montrer la récupération.

## Conditions pour annoncer la démonstration prête

La source peut être présentée avec Godot sur un PC disposant d'un affichage après cette répétition. Une démonstration sur le Pi nécessite en plus un export ARM64 réussi, un lancement dans labwc et la recette réelle avec son écran et son contrôleur. L'absence d'arrêt système intégré n'empêche pas le parcours applicatif ; elle doit être annoncée, et l'arrêt de Raspberry Pi OS doit rester distinct de Quitter.

[Résultats automatiques réellement exécutés](TESTS.md) · [Interface](UI_TESTS.md) · [Installation Pi](RASPBERRY_PI.md) · [Parcours de soutenance](DEMONSTRATION.md).
