# Outils de revue de l’assistant

Ces intégrations servent au développement de Console CIEL. Elles ne sont pas des modules Godot et ne sont pas nécessaires pour jouer hors ligne. Aucun service d’IA ni secret de fournisseur n’est intégré aux logiciels Windows ou Raspberry Pi.

## Versions utilisées le 2 novembre 2026

| Outil | Version Git épinglée | Installation locale |
|---|---|---|
| [Council of High Intelligence](https://github.com/0xNyk/council-of-high-intelligence) | `14d398f44771be1fc49488ab1b8a348ed76ca172` | `~/.codex/skills/council/` : skill Codex et 18 profils |
| [Agency Agents](https://github.com/msitarzewski/agency-agents) | `b37b5bb33b78f2c1d6567d98e25ca818e3259219` | `~/.codex/agents/` : quatre profils TOML |

Profils Agency sélectionnés : **Godot Gameplay Scripter**, **Level Designer**, **UI Designer**, **Code Reviewer**. Les fichiers TOML installés ont été relus par un parseur TOML. Les installateurs ont été inspectés avant exécution ; aucune configuration existante n’a été remplacée. Les deux dépôts sont sous [licence MIT pour Council](https://github.com/0xNyk/council-of-high-intelligence/blob/14d398f44771be1fc49488ab1b8a348ed76ca172/LICENSE) et [licence MIT pour Agency](https://github.com/msitarzewski/agency-agents/blob/b37b5bb33b78f2c1d6567d98e25ca818e3259219/LICENSE).

Dans cette session, les instructions ont été lues directement et appliquées avec les sous-agents natifs disponibles. L’installation sur disque est vérifiée ; la détection automatique des commandes ou profils par un client redémarré n’a pas été testée. Les instructions amont de Council prévoient un redémarrage du client après installation. Cette installation locale n’active pas un connecteur supplémentaire dans l’interface de chat et ne garantit pas sa conservation dans un autre environnement cloud.

## Reproduire l’installation Codex

Lire les scripts et vérifier les destinations avant de les lancer, notamment si des fichiers de même nom existent déjà.

```bash
git clone https://github.com/0xNyk/council-of-high-intelligence.git council
cd council
git checkout 14d398f44771be1fc49488ab1b8a348ed76ca172
bash install.sh --codex-only
cd ..
git clone https://github.com/msitarzewski/agency-agents.git agency-agents
cd agency-agents
git checkout b37b5bb33b78f2c1d6567d98e25ca818e3259219
bash scripts/convert.sh --tool codex
bash scripts/install.sh --tool codex --agent godot-gameplay-scripter,level-designer,ui-designer,code-reviewer --no-interactive --no-convert
```

## Revue de la livraison 0.25.0

Question : les points d’entrée permanents et le campus Louise Michel isolé répondent-ils à la demande, avec une implantation, une façade et des interactions cohérentes ? Le périmètre reste la navigation et la reconnaissance du lieu dans la direction artistique existante, sans prétendre produire un relevé architectural.

**Panel Council, mode quick** : Rams, Torvalds, Watts. Rams reçoit le poids de domaine **1,5** fixé avant la première analyse ; les deux autres sièges ont chacun un poids de 1,0. Trois agents natifs ont analysé la proposition indépendamment, puis reçu des avis anonymisés sous les noms Member A, B et C. Le second tour a inclus la directive anti-conformité du skill et une demande de condition susceptible d’invalider l’accord initial.

Les cadres Agency appliqués portent sur la lisibilité des destinations, les affordances d’entrée, les types et la composition Godot, le contrat entre position, interaction et collision, et la revue de changements ciblés. Ils restent des aides de revue ; les faits du moteur, les tests et les instructions du projet priment sur les généralités de ces profils.

### Synthèse du président

Président : agent de synthèse distinct des trois délibérants, modèle hérité non exposé. Un seul fournisseur natif était utilisé ; aucune diversité de modèles ou de fournisseurs n’est revendiquée.

- **Compromis acceptable** : façade stylisée fidèle aux éléments reconnaissables ; une entrée signalée par bâtiment, sans ajouter d’interface permanente encombrante.
- **Critère d’invalidation** : si, avant publication le 2 novembre 2026, un export final masque le point hors portée d’interaction, l’aligne sur une porte inutilisable ou bloque le parvis, corriger puis refaire les contrôles concernés.
- **Prochaine action concrète** : produire le rapport de validation des exports finaux avec accès, collisions, fenêtre compacte et vue d’arrivée du lycée.
- **Questions ouvertes** : découverte spontanée par des joueurs débutants, lisibilité sur un écran Raspberry Pi physique et exécution native Windows/Pi.
- **Accords** : les points permanents, la façade partagée et le composant de repérage répondent au besoin ; aucune refonte générale supplémentaire ne se justifie.
- **Désaccords** : aucun sur la décision conditionnelle. Rams privilégie la clarté ; Torvalds la cohérence des contrats ; Watts la reconnaissance du lieu. Un accord entre agents ne remplace pas une observation utilisateur.
- **Votes finaux** : chaque membre déclare `STANCE: ship_after_checks | CONFIDENCE: med | DEALBREAKER: no`.
- **Tally pondéré** : Rams 1,125 ; Torvalds 0,75 ; Watts 0,75 ; total 2,625 pour `ship_after_checks`. Seuil des deux tiers du poids de base 3,5 : 2,333. Seuil franchi, avec confiance moyenne.
- **Options** : livrer après réussite des contrôles finaux ; ou différer pour des essais utilisateurs et matériels supplémentaires. Le panel recommande la première, sous condition de validation.
- **Fiabilité** : trois sièges actifs, aucun dégradé, aucune réponse simulée ; président distinct, sans appel à un fournisseur externe.

Cette décision a été consignée avant les contrôles des paquets finaux. La publication reste conditionnée à leur réussite ; [le rapport de livraison](DELIVERY.md) et les résultats de tests donnent l’état final.

```yaml
schema_version: 1
mode: quick
panel_size: 3
rounds_run: 2
enforcement_calls: 3
enforcement_breakdown:
  dissent_quota: 0
  novelty_gate: 0
  agreement_check: 3
  anti_recursion: 0
  missing_stance: 0
tools_used: [native_host_subagents, local_file_read]
provider_count: 1
fallbacks_triggered: [single_provider_chairman]
input_tokens_estimate: "~unknown"
output_tokens_estimate: "~unknown"
duration_seconds: "~unknown"
```
