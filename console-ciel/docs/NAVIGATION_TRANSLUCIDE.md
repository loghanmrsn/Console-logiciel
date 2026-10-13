# Console CIEL 0.4.1 — navigation translucide

La navigation demandée est une capsule flottante en bas de l'application, avec quatre destinations dans cet ordre : **Accueil → Boutique → Paramètres → Profil**. Les icônes sont les SVG originaux du projet. Le segment Profil contient l'avatar équipé, le pseudo et le solde réel en points. Ces informations suivent les mises à jour validées du profil, des achats et des récompenses ; elles remplacent leur répétition dans l'en-tête lorsque la barre est visible.

La surface claire est réellement translucide, avec des coins arrondis, une bordure lumineuse et une ombre sobre. Deux halos fixes très pâles accompagnent le fond. Il n'y a pas de flou obligatoire, de shader, de fond animé ni de ressource Instagram. La sélection utilise un fond doux ; le focus clavier/manette conserve un contour distinct. Réduire la transparence rend la capsule opaque. Le grand texte reste pris en charge ; un pseudo trop large est tronqué visuellement avec son texte complet conservé dans l'infobulle.

## Fonctions conservées

- Aide / Crédits reste dans **Paramètres → À propos**, avec son diagnostic des commandes.
- Quitter l'application reste dans les paramètres et la gestion habituelle de fermeture.
- La barre est masquée pendant l'enquête et dans les paramètres/aide/commandes ouverts depuis la pause.
- Les aperçus des réglages restent protégés lorsque l'on quitte leurs sous-pages. Revenir par l'onglet Paramètres conserve le brouillon ; partir vers un autre onglet demande explicitement de l'abandonner.
- Profils, inventaire, sauvegardes, règles des missions et récompenses uniques restent inchangés. Le dossier utilisateur reste `console-ciel`.

## Vérifications

Godot reste **4.6.3.stable.official.7d41c59c4**, édition standard, Compatibility. La version de l'application passe à **0.4.1**, sans migration de données.

| Suite | Résultat |
| --- | --- |
| Navigation | 1 829 assertions, zéro échec ; quatre résolutions × texte normal/grand × six écrans, profils réels, points, avatar, focus, brouillons et pause |
| Interface | 1 979 assertions, zéro échec ; navigation clavier et manette synthétique, paramètres, enquête, achats et sauvegardes |
| Services | 190 assertions, zéro échec |
| Enquête | 189 assertions, zéro échec |

Soit **4 187 assertions réussies**. L'ancien test d'interface pointait encore vers le cinquième onglet Aide supprimé : cette première tentative a expiré. Le parcours a été adapté pour ouvrir réellement Paramètres → À propos → Aide au clavier, puis la suite complète a réussi. Aucun test n'a été désactivé.

Les captures sont de vrais rendus du viewport Godot sous **X11/Mesa llvmpipe**, avec un profil temporaire, des récompenses normales et des données XDG isolées. La matrice comporte **14 captures** à 1920 × 1080, 1280 × 720, 1024 × 600 et 800 × 480, avec grand texte/opacité renforcée, focus, achats et pseudo de seize caractères. [Inventaire](screenshots/navigation_0.4.1/captures.json).

- [Accueil et barre 1280 × 720](screenshots/navigation_0.4.1/accueil_1280x720_normal.png)
- [Petit écran et grand texte](screenshots/navigation_0.4.1/accueil_800x480_grand_opaque.png)
- [Pseudo long et avatar équipé](screenshots/navigation_0.4.1/pseudo_long_800x480_grand_opaque.png)
- [Focus Boutique distinct de l'Accueil sélectionné](screenshots/navigation_0.4.1/focus_boutique_1280x720.png)

Le pilote logiciel signale qu'il ne permet pas de modifier V-Sync ; la fixture graphique peut aussi signaler des instances ObjectDB encore référencées à sa fermeture avec la sortie audio Dummy. Les captures et assertions passent, sans erreur de script. Cela ne valide pas le son réel, une manette USB, le Raspberry Pi ou les performances matérielles.

## Livraison Windows

Le nouveau paquet est `builds/Console_CIEL_Windows_x86_64_navigation_0.4.1.zip`. Après **Extraire tout**, ouvrir le dossier extrait et double-cliquer sur **Console_CIEL.exe**. Godot n'a pas besoin d'être installé pour jouer. Le paquet Windows 0.4.0 reste conservé pour revenir à l'interface précédente.

Les modèles officiels Windows correspondent exactement au moteur 4.6.3. Le ZIP contient le binaire complet, l'aide et les licences ; l'EXE est intégré au ZIP car il dépasse la limite GitHub de 100 Mio pour un fichier Git ordinaire. Les contrôles de configuration et du pack compilé sont consignés dans `builds/Console_CIEL_Windows_x86_64_navigation_0.4.1.verification.json`. Le lancement natif Windows, le son et les manettes restent à vérifier sur le PC Windows.

## Reproduire

Depuis `console-ciel/` :

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/refonte_navigation.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/investigation_tests.gd
# Affichage X11 et données XDG isolées nécessaires ; captures séquentielles :
godot --display-driver x11 --audio-driver Dummy --path . --script res://tests/glass_visual.gd
```

Exporter sans remplacer les livraisons précédentes :

```powershell
.\tools\export_windows.ps1 -GodotPath 'C:\Outils\Godot_v4.6.3-stable_win64_console.exe' -ArchiveName Console_CIEL_Windows_x86_64_navigation_0.4.1.zip -OutputDirectory windows-x86_64-navigation-0.4.1
```
