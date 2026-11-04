# Liste noire des pseudos

La création et le renommage vérifient la liste locale `pseudo_blacklist.json`. Dans les versions Windows et Raspberry Pi, ce fichier se trouve à côté de l’exécutable : ouvrir le JSON dans un éditeur de texte, compléter les listes puis enregistrer. Les modifications s’appliquent à la prochaine validation, sans redémarrage. Dans le projet Godot, le fichier par défaut est `data/pseudo_blacklist.json`.

```json
{
  "version": 1,
  "blocked_names": ["admin", "nom réservé"],
  "blocked_terms": ["mot interdit"]
}
```

`blocked_names` bloque un nom complet normalisé. `blocked_terms` bloque un mot entier dans un pseudo, ainsi que sa forme séparée par des points ou espaces. Casse, accents latins, caractères pleine chasse et caractères invisibles courants sont normalisés ; les chiffres en début et fin sont ignorés. Par exemple, `Ad.min42` est refusé. Les simples sous-chaînes ne sont pas interdites : une règle `terme` ne bloque pas `Monterme`.

La liste initiale contient des insultes courantes et des noms réservés. Elle est modifiable et ne prétend pas détecter toutes les orthographes ou tous les alphabets. Limites : 256 entrées par liste, 64 caractères par entrée et 32 Kio pour le fichier. Une erreur de JSON est signalée et bloque seulement les nouvelles créations ou modifications du nom jusqu’à correction. En l’absence du fichier externe, la version intégrée est utilisée.

Les anciennes sauvegardes restent valides et sélectionnables. Un ancien pseudo interdit peut être conservé lors d’un changement d’avatar ou remplacé par un pseudo autorisé. Aucun profil n’est effacé. La liste ne donne aucun droit d’administration ; le profil interne Dev et les règles de rôles existantes restent distincts des pseudos.

Pour une nouvelle installation, conserver ou recopier sa liste personnalisée à côté du nouvel exécutable. Les archives livrent la liste initiale.
