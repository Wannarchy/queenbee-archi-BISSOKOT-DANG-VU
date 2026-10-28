# Analyse de menaces STRIDE — QueenBee

## Zones de confiance

| Conteneurs | Zone | Confiance |
|---|---|---|
| Application mobile | Internet mobile | Faible |
| Portail web, Service télémétrie | DMZ locale / IoT (VLAN 10 / 40) | Faible |
| API, référentiel, santé, terrain, production, reporting, cache | LAN applicatif (VLAN 20) | Moyenne |
| Identité, bases de données | LAN applicatif / données (VLAN 20) | Élevée |
| Supervision et sécurité | Management (VLAN 30) | Élevée |
| Plateforme de données | Central — données (sous-zone logique du VLAN 20) | Élevée |

Les services externes (météo, identité, notification, cartographie) sont sur
Internet, de confiance faible. La séparation « central — données » doit être
appliquée par des ACL et des identités de service dédiées.

## Flux analysés

| Flux | De → vers | Protocole | Frontière |
|---|---|---|---|
| F1 | Service télémétrie → Staging | AMQP | LAN applicatif → Central — données |
| F2 | Registre de modèles → Prédiction (service santé) | MLflow / HTTPS | Central — données → LAN applicatif |

## Menaces et mesures

| Flux | STRIDE | Menace | Mesure | Référence |
|---|---|---|---|---|
| F1 | S — Usurpation | Un faux producteur injecte des mesures. | Identité de service et ACL par file/topic. | CDC §6.3 |
| F1 | T — Falsification | Une mesure rejouée ou altérée fausse les données d'entraînement. | Vérifier intégrité, horodatage, identifiant unique et plage de valeurs ; isoler les lots invalides. | UC-T02 |
| F1 | D — Déni de service | Une reconnexion envoie une rafale qui bloque l'ETL. | Borner files et lots ; traiter les arrivées en micro-lots de 5 minutes. | UC-CY01 ; ADR 0003 |
| F2 | T — Falsification | Un modèle non validé est chargé pour les prédictions. | Vérifier la signature et la version approuvée avant publication et chargement. | ADR 0003 |
| F2 | I — Fuite d'information | Un service non autorisé accède aux modèles ou aux données d'un site. | ACL par identité de service et site ; chiffrement au repos et en transit. | CDC §6.3 |
| F2 | E — Élévation de privilèges | Le processus d'entraînement publie directement en production. | Séparer les droits d'entraînement et d'inférence ; limiter la publication aux modèles validés. | ADR 0003 |

## Risques résiduels

- Après une coupure, les mesures en retard sont recalculées sans déclencher seules
  une alerte. L'équipe Data suit leur proportion par site et l'écart des scores.
- Réexaminer l'ADR 0003 si le délai médian mesure–alerte dépasse 15 minutes pendant
  deux semaines, ou si les mesures en retard dépassent 10 % sur un mois.
