# Version portable Windows x86_64 — 0.6.0

**[Télécharger Windows 0.6.0 — chapitre 2](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.zip)**. Décompresser **tout** le ZIP, puis lancer **Console_CIEL.exe** dans le dossier extrait. Godot ne doit pas être installé sur le PC destinataire.

La version **0.6.0** ajoute le chapitre 2 de l’enquête : l’ascenseur du bureau, accessible après les trois premières missions, mène à la salle réseau. Trois nouveaux défis couvrent RJ45, IPv4 et protection Wi-Fi ; le tableau de missions à droite se déplie ou se replie avec **T** ou le **bouton de face haut**. [Parcours des deux chapitres](ENQUETE.md). La bibliothèque, les achats Test, les profils, les styles et couleurs de 0.5.0 sont conservés. [Guide de la bibliothèque et de l’apparence](BIBLIOTHEQUE_ET_THEMES.md). [Rapport du paquet Windows](../builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.verification.json).

Le [projet complet 0.6.0](https://github.com/loghanmrsn/Console-logiciel/raw/refs/heads/main/console-ciel/builds/Console_CIEL_Projet_Complet_0.6.0.zip) contient aussi les sources. Dans ce ZIP, le logiciel se trouve dans **console-ciel/builds/windows-x86_64-chapitre-2-0.6.0/Console_CIEL.exe**. [Contenu du projet complet](ARCHIVE_COMPLETE.md).

## Lancer sur votre PC

1. Télécharger le ZIP Windows ci-dessus. Avec **Code → Download ZIP**, ouvrir d’abord le ZIP Windows dans `console-ciel/builds/`.
2. Choisir **Extraire tout**. Ne pas lancer le programme depuis l’aperçu du ZIP.
3. Double-cliquer sur **Console_CIEL.exe** dans le dossier extrait.

Garder l’aide, les licences et **images_profil/** à côté de l’EXE. Les ressources du jeu sont intégrées (`embed_pck=true`) ; le ZIP reste la livraison à copier dans son ensemble. L’EXE dépasse la limite de taille d’un fichier GitHub ordinaire et est donc distribué dans l’archive portable.

Le moteur est fixé à **4.6.3.stable.official.7d41c59c4**, édition standard, rendu **Compatibility**, x86_64. Windows 10/11 avec un pilote OpenGL 3.3 est conseillé. Le programme ne demande pas de droits administrateur. Le préréglage Linux ARM64 Raspberry Pi reste distinct.

## Profils, bibliothèque et achats

Au premier lancement, créer un profil avec le clavier virtuel ou physique. L’éditeur conserve les minuscules, **⇧**, **123**, **#+=** et **ABC**. Pour les photos, déposer des PNG, JPEG ou WebP dans **images_profil/** voisin de l’EXE, puis **Profil → Modifier → Mes images → Actualiser les images**. Le [guide des profils](PROFILS_ET_CLAVIER.md) précise les limites et le remplacement d’une image absente par l’avatar classique.

L’enquête pédagogique est gratuite : **50 points par première réussite**, six missions réparties en deux chapitres, **300 points au maximum par profil**. **Test 1 / 2 / 3 / 4** coûtent **20 / 30 / 40 / 50 points**. Les vrais jeux n’étant pas prêts, ces achats ouvrent seulement une page **jeu en préparation** ; leur ouverture ne rapporte aucun point. Un achat payant est refusé à solde nul ou insuffisant. Un article possédé n’est pas acheté deux fois. Solde et inventaire sont sauvegardés ensemble, séparément pour chaque profil.

**Boutique → Jeux** présente ces emplacements ; **Mes achats** retrouve les acquisitions du joueur. Les cosmétiques existants restent disponibles. Les cartes de profil affichent les points, objectifs et jeux acquis.

## Affichage, apparence et crédits

La fenêtre est redimensionnable, **1280 × 720** par défaut, minimum **800 × 480**. **Paramètres → Affichage** règle le plein écran et la disposition de l’accueil : enquête à gauche avec quatre jeux à droite, ou cinq couvertures de même taille avec défilement horizontal. Sur petit écran, la disposition s’adapte et défile. **Précédent / Suivant** et le focus clavier/manette parcourent les couvertures.

**Paramètres → Apparence** propose gratuitement **Thème du profil, Brume, Sable, Sauge, Nuit, Aurore**. Choisir séparément la couleur du fond et des boutons, ou **Personnaliser** pour une couleur RGB. L’aperçu est immédiat ; **Appliquer** enregistre, **Annuler** restaure. Les anciens fichiers de réglages sont compatibles. Grand texte, animations et transparence réduites restent dans Accessibilité.

**Crédits** est la dernière catégorie des paramètres ; un bloc de crédits figure aussi au bas de chaque catégorie. **À propos** conserve l’aide, la version et les chemins des données.

## Commandes et fermeture

| Action | Clavier | Manette compatible Godot |
|---|---|---|
| Naviguer | Flèches ; Tab / Maj+Tab | Croix / joystick gauche |
| Valider | Entrée / Entrée numérique | Bouton de face bas |
| Retour | Échap | Bouton de face droit |
| Déplacer le personnage | Flèches ou ZQSD | Croix / joystick gauche |
| Interagir | Espace | Bouton de face bas |
| Afficher / masquer le tableau de missions | T | Bouton de face haut (Triangle / Y / X selon la manette) |
| Pause | P | Start / Menu |
| Catégorie précédente / suivante | Q / E, hors saisie de texte | Épaules gauche / droite |

La souris est facultative. **Paramètres → Commandes → Test des commandes** montre les entrées effectivement reçues et la zone morte. Une déconnexion suspend l’enquête ; reconnecter ne la reprend pas automatiquement. Le mapping du contrôleur fabriqué doit être mesuré sur le matériel réel.

**Paramètres → Quitter l’application** et la croix de la fenêtre demandent confirmation et sauvegardent. Un échec laisse l’application ouverte avec possibilité de réessai. Un brouillon de paramètres propose appliquer, annuler ou revenir aux réglages. Quitter n’arrête ni ne redémarre Windows.

## Sauvegardes et mises à jour

Les données sont dans le dossier utilisateur **console-ciel**, généralement **`%APPDATA%\console-ciel`** sous Windows. **Win+R** puis ce chemin permet de l’ouvrir ; **Paramètres → À propos** affiche le chemin effectif calculé par Godot, y compris si Windows redirige ce dossier.

| Fichier | Contenu |
|---|---|
| `profiles/<identifiant>.json` | Profil, progression, points, inventaire, jeux acquis et équipement |
| `settings.cfg` | Réglages de la console, disposition, style et couleurs |
| `session.json` | Dernier profil choisi |
| `logs/godot.log` | Journal Godot |

Le ZIP ne contient aucun profil prérempli ni sauvegarde personnelle. Une mise à jour dans un nouveau dossier conserve ces données ; ne pas effacer le dossier utilisateur. Copier également **images_profil/** pour conserver les photos locales et garder leurs noms stables. Fermer normalement le logiciel avant de copier les sauvegardes. Les achats et points changent en mémoire seulement après une sauvegarde réussie. Les anciens profils reçoivent les nouvelles missions du chapitre 2 sans perdre leurs réussites du chapitre 1, leurs observations, points, récompenses ou achats ; le schéma reste en version 1. Continuer restaure aussi la salle et le chapitre atteints.

## Refaire l’export

Installer Godot standard **4.6.3 stable** et les [modèles d’export officiels correspondants](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable). Depuis `console-ciel/`, dans PowerShell :

```powershell
.\tools\export_windows.ps1 -GodotPath 'C:\Outils\Godot_v4.6.3-stable_win64_console.exe' -ArchiveName Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.zip -OutputDirectory windows-x86_64-chapitre-2-0.6.0
```

Adapter le chemin du moteur. Le script cible PowerShell **5.1 ou supérieur**, vérifie la version exacte, importe les ressources et exporte avec **Windows Desktop x86_64** dans un dossier provisoire. Il vérifie le PE x86_64, ajoute aide, licences et images_profil, puis assemble l’archive. Un échec conserve la livraison précédente. Le preset Pi n’est pas modifié.

Le script PowerShell a été analysé et testé historiquement avec PowerShell 7.4.13 sous Linux ; cela ne constitue pas un essai de Windows PowerShell 5.1. Les [résultats historiques](../tests/windows_results/) sont conservés. Depuis l’éditeur, le preset **Windows Desktop x86_64**, sans débogage et avec pack intégré, permet également d’exporter le binaire ; le script assemble le ZIP portable complet.

## Vérifications et recette Windows

Le [rapport Windows 0.6.0](../builds/Console_CIEL_Windows_x86_64_chapitre_2_0.6.0.verification.json) décrit les fichiers et empreintes du paquet ; le [rapport du projet complet](../builds/Console_CIEL_Projet_Complet_0.6.0.verification.json) décrit l’archive des sources et du binaire. Les rapports de recette distinguent logique source, captures sous Linux, configuration Windows et pack compilé. Les résultats historiques des versions précédentes sont conservés séparément.

La recette **0.6.0** a passé **9 568 assertions source** (14 suites), **65 assertions de persistance** sur trois processus, **694 contrôles de rendu X11** avec 12 captures, **4 351 assertions du pack compilé**, **18 contrats Windows** et **27 contrôles de packaging**, tous avec zéro échec. Le pack contient **203 ressources contrôlées**, dont **43 SVG**. [Résumé de recette](../tests/chapitre_2_0.6.0_results/summary.json), [captures](screenshots/chapitre_2_0.6.0/) et [taille/empreinte du téléchargement](../builds/README_WINDOWS.md).

Tester un pack embarqué avec le moteur Linux vérifie ses ressources et sa logique ; cela ne lance pas l’EXE Windows. Le double-clic, le rendu, le son et les périphériques USB sous Windows restent à essayer sur votre PC :

1. Extraire, lancer, créer deux profils, ajouter une photo et saisir minuscules, majuscules et chiffres.
2. Avec zéro point, vérifier qu’un jeu payant ne peut pas être acheté. Afficher et masquer le tableau de missions par son bouton, T et le bouton de face haut ; en pause ou pendant un défi, vérifier que les actions ne traversent pas les dialogues.
3. Terminer les trois missions du chapitre 1 : l’ascenseur en bas du bureau reste bloqué avant et devient accessible après. Lire le bilan de 150 points, monter, puis terminer RJ45, IPv4 et Wi-Fi. Le second bilan doit afficher 300 nouveaux points cumulés pour un profil neuf sans achat.
4. Fermer et reprendre entre les missions et à l’étage. Vérifier le chapitre restauré et un ancien profil déjà terminé au chapitre 1 ; rejouer les six missions sans gain supplémentaire.
5. Acheter un emplacement Test, retrouver sa carte à l’accueil, ouvrir la page de préparation et vérifier l’absence de récompense. Changer de profil pour contrôler la séparation des achats.
6. Choisir les deux dispositions d’accueil, parcourir le carrousel au clavier ou à la manette.
7. Tester les styles, une couleur du fond et une couleur des boutons ; Annuler, puis Appliquer. Retrouver les réglages après relance et consulter Crédits.
8. Vérifier fenêtre et plein écran, texte normal et grand texte à **1920 × 1080, 1280 × 720, 1024 × 600 et 800 × 480**.
9. Fermer, relancer, reprendre l’enquête et vérifier points et achats ; essayer déconnexion et reconnexion de la manette USB.

## Livraisons conservées

- [Windows 0.5.0 — bibliothèque et thèmes](../builds/Console_CIEL_Windows_x86_64_bibliotheque_0.5.0.zip), [guide](BIBLIOTHEQUE_ET_THEMES.md).
- [Windows 0.4.2 — profils et clavier](../builds/Console_CIEL_Windows_x86_64_profils_0.4.2.zip), [guide](PROFILS_ET_CLAVIER.md).
- [Windows 0.4.1 — navigation translucide](../builds/Console_CIEL_Windows_x86_64_navigation_0.4.1.zip), [captures et recette](NAVIGATION_TRANSLUCIDE.md).
- [Windows 0.4.0 — refonte graphique](../builds/Console_CIEL_Windows_x86_64_refonte_0.4.0.zip), [captures et recette](REFONTE_GRAPHIQUE.md).

Les anciens exécutables 0.3.0/0.3.1 n’étaient pas inclus dans les sources reçues. Les rapports historiques sont conservés sans les présenter comme des essais du binaire courant. Les performances Pi et le contrôleur fabriqué restent dans les [limites connues](KNOWN_ISSUES.md).
