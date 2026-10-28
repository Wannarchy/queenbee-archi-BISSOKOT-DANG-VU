# ADR 0003 · Calculer les scores de santé en micro-lots au fil de l'eau, avec recalcul différé des mesures en retard

- Statut : proposé
- Date : 2026-10-30
- Auteurs : binôme Data
- Spécialité : Data
- Élément du C4 : flèche telemetrie -> sante (publication de MesureValidee) et conteneur `sante` (Service santé des colonies), dans le N2.

## Contexte

Le CDC fixe 400 ruches sur 8 sites, soit environ 38 400 mesures poids/température/humidité par jour (section 6.4), auxquelles s'ajoutent environ 19 200 estimations acoustiques. La fréquence normale est d'une mesure toutes les 15 minutes, resserrée à une mesure toutes les 5 minutes pendant 6 heures en surveillance renforcée après une anomalie suspectée.

Deux contraintes pèsent sur le calcul des scores :

- Les alertes de colonie doivent partir vite : le CDC vise +80 % de détection ≥ 48 h avant un essaimage (section 1.3) et une alerte levée à partir d'un niveau de confiance (UC-A02, glossaire « Niveau de confiance »).
- Les sites sont isolés et la liaison est intermittente : en mode dégradé, la passerelle met les mesures en cache et les resynchronise au retour (UC-CY01), ce qui produit des rafales de mesures en retard.

Point chaud d'origine (mur du TP 5) : « Mesures en retard (mode dégradé) : recalcul des scores ? ». Risque si on se trompe : lever des alertes sur des données incomplètes, ou laisser une colonie sans alerte parce que la mesure est arrivée trop tard.

## Options

1. Tout en lot (batch nocturne) : un ETL calcule les scores une fois par nuit sur les mesures de la veille.
   - Avantages : simple à opérer, peu coûteux, un seul chemin de calcul, facile à rejouer.
   - Inconvénients : une alerte arrive au mieux le lendemain, ce qui rend l'objectif « ≥ 48 h avant essaimage » difficile à tenir ; inadapté à la surveillance renforcée à 5 minutes.

2. Tout en flux (calcul à chaque mesure reçue) : chaque MesureValidee déclenche immédiatement le recalcul du score de la ruche.
   - Avantages : alerte la plus rapide possible, cohérente avec UC-A02.
   - Inconvénients : coût de calcul élevé (38 400 recalculs par jour, parfois en rafale à la reconnexion d'un site), et les mesures en retard faussent le score si on les injecte dans le désordre ; le CDC ne demande pas une réactivité à la seconde.

3. Micro-lots au fil de l'eau, avec recalcul différé des mesures en retard (option retenue) : les mesures validées sont regroupées par fenêtre courte (5 minutes), le score est recalculé par ruche à chaque fenêtre, et les mesures marquées en_retard (plus de 72 h, ou arrivées après une coupure de site) déclenchent un recalcul d'historique sur la fenêtre concernée, sans lever d'alerte sur ces seules mesures.
   - Avantages : délai d'alerte de l'ordre de quelques minutes, coût de calcul maîtrisé (un recalcul par ruche et par fenêtre, pas par mesure), et traitement explicite du cas « mesures en retard » sans fausser les alertes.
   - Inconvénients : deux chemins de calcul à maintenir (temps réel et recalcul), nécessite un indicateur de cohérence entre les deux, et une horloge de fenêtre à calibrer.

## Décision

Option 3. Le calcul en micro-lots au fil de l'eau permet de tenir l'objectif d'alerte précoce du CDC sans payer le coût d'un recalcul par mesure, et le recalcul différé traite le point chaud des mesures en retard sans jamais lever d'alerte sur des données incomplètes. Le choix est justifié par la matrice d'évaluation (`docs/evaluation/matrice.md`) : sur les scénarios « délai d'alerte », « coût de calcul » et « justesse en mode dégradé », l'option 3 obtient le meilleur score pondéré.

## Conséquences

Positives :
- Les alertes partent en quelques minutes après la mesure, ce qui rend l'objectif « ≥ 48 h avant essaimage » atteignable.
- Le coût de calcul reste proportionnel au nombre de ruches et de fenêtres, pas au nombre de mesures.
- Les mesures en retard sont traitées explicitement, ce qui évite les alertes sur données incomplètes.

Négatives :
- Deux chemins de calcul à maintenir (fenêtre courante et recalcul d'historique), donc un risque de divergence entre les deux.
- Une horloge de fenêtre à calibrer : trop courte, le calcul devient coûteux ; trop longue, l'alerte est retardée.

À surveiller : le délai médian entre MesureValidee et AlerteLevée, la part de mesures en_retard par site, et l'écart quotidien entre le score calculé en flux et le score recalculé en différé (test de cohérence).

## Révision

Rouvrir la décision si le délai médian d'alerte dépasse 15 minutes sur deux semaines consécutives, ou si la part de mesures en retard dépasse 10 % des mesures d'un site sur un mois, ou si le coût de calcul dépasse le budget d'exploitation fixé pour le service sante.