
sequenceDiagram
    participant P as Capteurs et passerelles
    participant T as Service télémétrie
    participant M as Base des mesures
    participant C as Cache et file de messages
    participant S as Service santé des colonies
    participant N as Service de notification

    P->>T: Transmet la trame (hive_id, mesures, timestamp)
    T->>T: Valide la trame (plages, unicité, capteur connu)
    T->>M: Archive la mesure validée
    T->>C: Publie MesureValidee
    C-->>S: MesureValidee (hive_id, mesures, timestamp)
    S->>M: Lit l'historique récent de la ruche
    M-->>S: Mesures validées
    S->>S: Recalcule le score et le risque

    alt Confiance ≥ seuil
        S->>C: Publie AlerteLevée (type, confiance)
        S->>N: Demande l'envoi de l'alerte à l'apicultrice
        N-->>S: Notification acceptée
    else Confiance sous le seuil
        S->>S: Conserve le score, aucun risque signalé
        Note over S: La mesure reste archivée pour l'analyse
    end