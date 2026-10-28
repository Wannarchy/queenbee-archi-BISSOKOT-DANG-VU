

- S1 Délai d'alerte : une mesure validée arrive au central → l'alerte de colonie est levée en moins de 15 minutes (cible : ≥ 48 h avant essaimage, CDC section 1.3) — poids : 40 %
- S2 Coût de calcul : 400 ruches, 8 sites, 38 400 mesures/jour → le calcul reste dans le budget d'exploitation du service `sante, sans recalcul par mesure — poids : 30 %
- S3 Justesse en mode dégradé : un site coupé resynchronise ses mesures en retard → aucune alerte levée sur ces seules mesures, et le score est recalculé sans fausser l'historique (UC-CY01) — poids : 30 %

## Matrice (notes de 1 à 5)

| Scénario (poids) | Option 1 · Tout en lot | Option 2 · Tout en flux | Option 3 · Micro-lots + recalcul différé |
|---|---|---|---|
| S1 Délai d'alerte (40 %) | 1 | 5 | 4 |
| S2 Coût de calcul (30 %) | 5 | 1 | 4 |
| S3 Justesse en mode dégradé (30 %) | 3 | 2 | 5 |
| Score pondéré /5 | 2,8 | 2,9 | 4,3 |

## Justification des notes (une phrase par note)

- S1, option 1 (1) : un ETL nocturne ne peut pas tenir l'objectif « ≥ 48 h avant essaimage », l'alerte arrive au mieux le lendemain.
- S1, option 2 (5) : chaque mesure déclenche le recalcul, donc l'alerte part immédiatement, c'est le délai minimal possible.
- S1, option 3 (4) : la fenêtre de 5 minutes ajoute un délai court mais borné, compatible avec l'objectif d'alerte précoce.
- S2, option 1 (5) : un seul passage nocturne, coût de calcul minimal et prévisible.
- S2, option 2 (1) : 38 400 recalculs par jour, avec des rafales à la reconnexion des sites, coût disproportionné.
- S2, option 3 (4) : un recalcul par ruche et par fenêtre (400 × 288/jour), coût maîtrisé mais supérieur au lot.
- S3, option 1 (3) : le lot traite les mesures en retard au passage suivant, mais le score de la veille reste faux jusque-là.
- S3, option 2 (2) : injecter les mesures en retard dans le flux fausse le score et peut lever une alerte sur des données incomplètes.
- S3, option 3 (5) : le recalcul différé traite explicitement les mesures en_retard sans lever d'alerte sur ces seules mesures.

## Sensibilité

Avec S1 à 40 %, l'option 3 gagne (4,3 contre 2,9 pour l'option 2). Si on montait S1 à 70 % (poids S2 à 10 %, S3 à 20 %), l'option 3 resterait gagnante (4,4) car elle note 4 sur S1 ; l'option 2 ne passerait devant que si S1 pesait plus de 85 % et S2 moins de 5 %, ce qui n'est pas plausible pour BeeAfrica : le CDC vise l'alerte précoce, mais il fixe aussi un budget d'exploitation et une contrainte de connectivité intermittente (8 sites, passerelles solaires). Un basculement vers l'option 2 supposerait un budget de calcul illimité et une connectivité permanente, deux hypothèses fausses dans le contexte.

## Conclusion → ADR 0003

L'option 3 (micro-lots au fil de l'eau, recalcul différé des mesures en retard) obtient le meilleur score pondéré (4,3/5) et reste gagnante sur toute plage de poids plausible pour BeeAfrica. Elle est reportée dans la section « Décision » de l'ADR 0003.