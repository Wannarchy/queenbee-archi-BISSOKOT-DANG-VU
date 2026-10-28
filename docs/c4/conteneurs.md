# docs/c4/conteneurs.md

Pourquoi chaque conteneur est séparé.

L'application mobile terrain est séparée parce qu'elle tourne sur les téléphones des apicultrices, hors réseau, et qu'elle a son propre cycle de vie (mises à jour par les stores). C'est un autre lieu d'exécution et un autre public. Elle héberge la saisie des inspections hors ligne et les jetons hors ligne.

L'API centrale est séparée parce que c'est le point d'entrée de tous les utilisateurs, avec un rythme de charge différent et un déploiement continu au central. Elle héberge les modules métier : Référentiel ruchers, Suivi terrain, Santé des colonies, Production, Impact et reporting, Identité et accès. Elle ne stocke rien durablement, elle est sans état.

La passerelle de site est séparée parce qu'il y en a une par site, qu'elle fonctionne hors ligne et sur panneaux solaires, et qu'elle subit des rafales de mesures puis des resynchronisations après coupure. Elle garde les lots de mesures en cache local jusqu'à l'accusé de réception du central.

L'ingestion télémétrie au central est séparée parce qu'elle absorbe un flux continu d'environ 38 400 mesures par jour, avec des pics quand les sites se reconnectent, et qu'elle est écrite en Python pour rester proche des pipelines Data. Elle valide, déduplique et publie les mesures, sans stocker.

Le moteur de prédiction et scoring est séparé parce que les modèles sont réentraînés et versionnés, et que les calculs lourds tournent de façon planifiée, indépendamment de l'API. Il garde le registre de modèles et les scores calculés.

La base de données centrale est séparée pour le stockage : historique des mesures, référentiel, inspections, récoltes, alertes, avec PostGIS pour la géolocalisation.

L'entrepôt et le reporting sont séparés parce qu'ils servent un autre public (gestionnaires et bailleurs) et tournent la nuit, hors du chemin transactionnel. Ils gardent les faits, les dimensions et les rapports figés.

La supervision et la sécurité sont séparées parce qu'elles servent l'équipe technique et les administrateurs, avec des règles et des playbooks versionnés à part des services métier. Elles gardent les journaux, les battements de passerelles et les incidents.

Le broker et les files de synchronisation sont séparés parce qu'ils sont au central, entre les sites et les services, et qu'ils servent de tampon pendant les rafales de reconnexion.


### A3.3

Les bounded contexts métier du TP5 sont principalement regroupés sous forme de modules distincts dans le conteneur API Backend, selon une architecture de monolithe modulaire. Chaque module possède ses propres responsabilités métier. Les modules identifiés sont le Référentiel ruchers, le Suivi terrain, la Santé des colonies, la Production, l’Impact et reporting, ainsi que l’Identité et accès. Certains traitements techniques, comme l’ingestion de télémétrie et le moteur de prédiction et scoring, sont isolés dans des conteneurs distincts pour répondre à leurs contraintes spécifiques.

