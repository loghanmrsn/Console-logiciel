# Limites connues et vérifications avant démonstration

La version 0.14.0 est livrée pour Windows x86_64 et Raspberry Pi 4 ARM64. La recette automatique utilise des données isolées et le moteur Godot installé ; ses résultats sont distingués du lancement sur le matériel cible dans [DELIVERY.md](DELIVERY.md). Les vérifications ci-dessous nécessitent le PC ou le Pi destinataire ; aucune valeur matérielle fictive n’est fournie.

| Point | État et conséquence | Vérification à effectuer |
|---|---|---|
| Export autonome | Paquets Windows x86_64 et Linux ARM64 séparés, avec pack intégré et rapports d’intégrité | Essayer le binaire de chaque paquet sur sa cible : Windows ou Raspberry Pi 4 avec Raspberry Pi OS 64 bits et bureau |
| Rendu réel | Rendu Godot X11/Mesa logiciel inspecté à 1920 × 1080, 1280 × 720, 1024 × 600 et 800 × 480, normal/grand ; captures dans `screenshots/refonte/` | Refaire l'inspection sur Windows et sur l'écran du Pi ; le rendu logiciel ne mesure pas ses performances |
| Windows et DPI | Export réussi ; aucun Windows natif dans cet environnement | Double-clic, audio, plein écran et échelles Windows 100 %, 125 %, 150 %, 200 % à essayer |
| Manette physique | Événements et cycle de connexion simulables, aucun périphérique USB réel utilisé ici | Essayer navigation complète, axes au repos, répétition, retrait/reconnexion, plusieurs manettes |
| Contrôleur fabriqué | Mapping USB HID encore inconnu | Mesurer boutons/axes avec le diagnostic, configurer le mapping et refaire la recette |
| Avertissement audio de fermeture | Certaines fixtures X11 avec sortie Dummy signalent un WAV/playback résiduel à la fermeture ; essais fonctionnels réussis | Contrôler la fermeture et le journal avec un vrai pilote audio Windows/Pi |
| Son et plein écran | Logique de volume testée ; son et plein écran non vérifiés sur les cibles physiques | Écouter tous les bus, volume zéro, tester `--fullscreen` dans la session graphique du Pi et sur Windows |
| Performance Pi | Aucune mesure sur Raspberry Pi | Mesurer FPS et temps de réponse du menu et de l'enquête ; ne pas présenter 60 FPS comme acquis |
| Lanceur et autostart | Lanceur manuel ARM64 et raccourci utilisateur fournis ; aucun autostart ajouté | Essayer `bash ./Lancer_Console_CIEL.sh` dans le bureau du Pi ; l’intégration à un futur lanceur automatique reste distincte |
| Arrêt système | Non configuré et indisponible dans PlatformService | Intégration future limitée aux droits de session, refus/échecs testés ; Quitter ferme seulement l'application |
| Coupure électrique | Écriture prudente avec copies, sans garantie contre toutes les coupures | Valider alimentation et arrêt propre du montage ; ne pas tester les coupures sur les vrais profils |
| Écran et coque | Dimensions et écran définitifs non fixés | Contrôler lisibilité à distance normale, format physique et accès aux contacts/joysticks |
| Crédits | Nom du binôme à compléter | Compléter les crédits avant redistribution finale |

## Répétition minimale sur PC avec affichage

1. Créer deux profils sans souris et vérifier l'absence de données communes.
2. Avec le premier, modifier puis annuler un paramètre ; l'appliquer et vérifier après relance.
3. Jouer les treize défis dans les cinq chapitres, soumettre une mauvaise réponse avant chaque correction, revenir au menu et reprendre après chaque mission. Vérifier l’accès au chapitre 3 seulement après les trois missions réseau, l’ascenseur entre les étages ouverts, le panneau de missions et la disparition des repères après réussite sauvegardée. Les exercices Python, HTML et Markdown doivent expliquer une mauvaise réponse sans attribuer de points.
4. Débrancher la manette active en jeu : pause et message, clavier disponible, reconnexion sans déplacement automatique, reprise explicite.
5. Acheter et équiper un cosmétique ; tester aussi le refus d’achat d’un jeu Test sous 200 points, puis un achat avec un solde suffisant. Fermer normalement et retrouver mission, solde, achat, équipement et paramètres.
6. Rejouer : aucune récompense supplémentaire. Tester plusieurs validations rapides et vérifier que les dialogues ne se superposent pas.
7. Dans la cour, vérifier le passage au vert, le rouge sans choc (200 points), un choc depuis chaque trottoir et la conservation des missions. Avec un profil de test à moins de 200 points, vérifier la dette, son affichage et son remboursement sur les prochains gains.
8. Vérifier 1920 × 1080, 1280 × 720, 1024 × 600 et 800 × 480, en texte normal et grand texte ; suivre le focus jusqu'au dernier bouton des écrans défilants.

Les corruptions et échecs d'écriture sont vérifiés automatiquement dans des copies de test. Une démonstration manuelle de ces cas doit également utiliser une racine isolée. Ne pas endommager les données normales pour montrer la récupération.

## Conditions pour annoncer la démonstration prête

La source peut être présentée avec Godot sur un PC disposant d’un affichage après cette répétition. La livraison ARM64 fournit le programme autonome ; une démonstration sur le **Pi 4 64 bits** nécessite encore un lancement dans son bureau et la recette réelle avec son écran et son contrôleur. L’absence d’arrêt système intégré n’empêche pas le parcours applicatif ; elle doit être annoncée, et l’arrêt de Raspberry Pi OS doit rester distinct de Quitter.

[Résultats automatiques réellement exécutés](TESTS.md) · [Interface](UI_TESTS.md) · [Installation Pi](RASPBERRY_PI.md) · [Parcours de soutenance](DEMONSTRATION.md).
