# Console CIEL 0.4.0 — Windows x86_64

Le paquet `Console_CIEL_Windows_x86_64_refonte_0.4.0.zip` contient le véritable exécutable **Console_CIEL.exe**, l'aide en français et les licences. Godot n'a pas besoin d'être installé pour jouer.

## Lancer

1. Télécharger le ZIP Windows.
2. Cliquer sur **Extraire tout** dans l'Explorateur Windows.
3. Ouvrir le dossier extrait et double-cliquer sur **Console_CIEL.exe**.

Le fichier EXE se trouve à la racine du dossier extrait, à côté de `LIRE_MOI.txt` et du dossier `assets/`. Ne pas lancer depuis l'aperçu du ZIP.

Si vous avez téléchargé tout le dépôt GitHub, ce paquet est dans `console-ciel/builds/` ; il faut aussi extraire ce ZIP Windows avant de jouer. Le fichier EXE de 105 134 208 octets dépasse la limite GitHub de 100 Mio pour un fichier Git ordinaire : le ZIP contient le binaire complet, sans pointeur Git LFS.

## Vérification de cette livraison

- Moteur officiel : `4.6.3.stable.official.7d41c59c4`, édition standard.
- Modèles officiels 4.6.3 vérifiés avec le SHA-512 de leur publication.
- Export release réussi ; fichier Windows PE32+ x86_64 avec pack intégré.
- CRC ZIP et empreintes des 173 ressources du pack vérifiés, dont 36 SVG importés.
- Contrat Windows : 16 assertions, zéro échec.
- Missions, profils, achats et sauvegardes du pack compilé : 47 assertions, zéro échec.
- Ressources graphiques et interface compilée : 50 assertions, zéro échec.

Les tests exécutent le pack avec le moteur Godot Linux en headless et des données isolées. Le double-clic, l'affichage, le son et les manettes sur Windows restent à vérifier sur le PC Windows. L'application n'est pas signée.

SHA-256 du ZIP : `9de8826f47362a44001f258702f9dda3c9059a125fbc64f45d4dfb3842e941d6`.

Le fichier `Console_CIEL_Windows_x86_64_refonte_0.4.0.verification.json` contient l'inventaire, les empreintes et les résultats de cette livraison. Les sources et anciens rapports reçus sont conservés ; les anciens exécutables Windows 0.3.0 et 0.3.1 ne figuraient pas dans l'archive de sources fournie.
