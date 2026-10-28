
workspace "QueenBee" "Plateforme apicole de BeeAfrica" {

    model {
        // ==========================================
        // 1. PERSONNES
        // ==========================================

        apicultrice = person "Apicultrice" "Enregistre les inspections, suit ses ruches et déclare les récoltes."
        coordinateur = person "Coordinateur" "Planifie les visites, assigne les interventions et valide les récoltes."
        gestionnaire = person "Gestionnaire BeeAfrica" "Consulte les indicateurs multi-sites et génère les rapports d'impact."
        administrateur = person "Administrateur" "Gère les comptes, les rôles et les accès à la plateforme."

        // ==========================================
        // 2. SYSTEMES EXTERNES
        // ==========================================

        capteurs = softwareSystem "Capteurs et passerelles" "Collectent les mesures des ruches et les transmettent au système central." {
            tags "Externe"
        }

        meteo = softwareSystem "OpenWeatherMap" "Fournit les données météorologiques utiles à l'analyse des colonies." {
            tags "Externe"
        }

        notification = softwareSystem "Service de notification" "Envoie des alertes par notification push, SMS ou e-mail." {
            tags "Externe"
        }

        fournisseurIdentite = softwareSystem "Fournisseur d'identité" "Gère l'authentification et fournit des jetons OIDC." {
            tags "Externe"
        }

        cartographie = softwareSystem "Service cartographique" "Fournit les données géographiques pour localiser les ruchers." {
            tags "Externe"
        }

        // ==========================================
        // 3. SYSTEME PRINCIPAL QUEENBEE
        // ==========================================

        queenbee = softwareSystem "QueenBee" "Plateforme apicole de BeeAfrica" {

            // ---- Conteneurs applicatifs ----

            applicationMobile = container "Application mobile" "Permet aux apicultrices de consulter leurs ruches et de saisir des inspections hors ligne." "Flutter"

            portailWeb = container "Portail web" "Permet aux coordinateurs, gestionnaires et administrateurs d'utiliser la plateforme." "React / TypeScript"

            api = container "API centrale" "Expose les fonctionnalités de QueenBee et orchestre les échanges entre les services." "Node.js / REST / JSON"

            identite = container "Service identité et accès" "Gère les comptes, les rôles par site et les autorisations." "Node.js / OIDC"

            referentiel = container "Service référentiel ruchers" "Gère les sites, les coopératives, les ruches, les capteurs et les positions de référence." "Node.js / REST"

            telemetrie = container "Service télémétrie" "Reçoit les trames, valide les mesures et synchronise les données des passerelles." "Node.js / MQTT"

            sante = container "Service santé des colonies" "Calcule les scores de santé, détecte les risques et gère les alertes." "Python / API REST" {
                prediction = component "Prédiction" "Exécute les modèles validés pour estimer les risques et les rendements." "Python / scikit-learn"
            }

            terrain = container "Service suivi terrain" "Planifie les visites, enregistre les inspections et gère leur synchronisation." "Node.js / REST"

            production = container "Service production" "Enregistre les récoltes, calcule les écarts de rendement et gère leur validation." "Node.js / REST"

            reporting = container "Service impact et reporting" "Consolide les indicateurs multi-sites et génère les rapports destinés aux bailleurs." "Python / ETL"

            supervision = container "Service supervision et sécurité" "Surveille les passerelles, détecte les incidents et contrôle l'intégrité des données." "Node.js / Monitoring"

            // ---- Bases de données ----

            baseMetier = container "Base de données métier" "Stocke les comptes, les sites, les ruches, les inspections, les visites et les récoltes." "PostgreSQL" {
                tags "Database"
            }

            baseMesures = container "Base de données des mesures" "Archive les mesures horodatées et les données de télémétrie." "TimescaleDB" {
                tags "Database"
            }

            baseCache = container "Cache et file de messages" "Conserve les messages en attente et facilite les échanges asynchrones entre services." "Redis / RabbitMQ" {
                tags "Database"
            }

            plateformeDonnees = container "Plateforme de données" "Prépare les données, entraîne et publie les modèles, et fournit les analyses." "Python / Airflow / PostgreSQL" {
                staging = component "Staging" "Reçoit les données brutes avant leur validation et leur transformation." "Object Storage / Parquet"
                etl = component "ETL" "Valide, nettoie et transforme les données d'entrée." "Apache Airflow / Python"
                entrepot = component "Entrepôt analytique" "Conserve les données consolidées pour les analyses." "PostgreSQL / SQL"
                jeuxEntrainement = component "Jeux d'entraînement" "Prépare les données versionnées destinées à l'entraînement." "Parquet / Object Storage"
                entrainement = component "Entraînement" "Entraîne et évalue les modèles prédictifs." "Python / scikit-learn"
                registreModeles = component "Registre de modèles" "Versionne et référence les modèles validés." "MLflow"
                tableauxAnalytiques = component "Tableaux analytiques" "Expose les indicateurs et les analyses aux gestionnaires." "Metabase / SQL"
            }
        }

        // ==========================================
        // 4. RELATIONS PERSONNES -> QUEENBEE
        // ==========================================

        apicultrice -> applicationMobile "Saisit les inspections et les récoltes" "HTTPS, mode hors ligne"
        coordinateur -> portailWeb "Planifie les visites et valide les récoltes" "HTTPS"
        gestionnaire -> portailWeb "Consulte les indicateurs et génère les rapports" "HTTPS"
        administrateur -> portailWeb "Administre les comptes et les rôles" "HTTPS"

        // ==========================================
        // 5. RELATIONS AVEC LES SYSTEMES EXTERNES
        // ==========================================

        capteurs -> telemetrie "Transmet les trames des capteurs" "LoRaWAN, MQTT"
        sante -> meteo "Récupère les conditions météorologiques" "HTTPS, API JSON"
        terrain -> notification "Demande l'envoi des notifications" "HTTPS, API REST"
        applicationMobile -> fournisseurIdentite "Authentifie l'apicultrice" "OIDC, OAuth 2.0"
        terrain -> cartographie "Récupère les données géographiques" "HTTPS, API JSON"

        // ==========================================
        // 6. RELATIONS ENTRE CONTENEURS
        // ==========================================

        applicationMobile -> api "Synchronise les inspections et consulte les ruches" "HTTPS, JSON"
        portailWeb -> api "Envoie les demandes métier" "HTTPS, JSON"

        api -> identite "Vérifie les droits et les rôles" "HTTPS, JSON"
        api -> referentiel "Consulte les sites et les ruches" "HTTPS, JSON"
        api -> telemetrie "Consulte les mesures" "HTTPS, JSON"
        api -> sante "Consulte les scores et les alertes" "HTTPS, JSON"
        api -> terrain "Gère les visites et les inspections" "HTTPS, JSON"
        api -> production "Gère les déclarations de récolte" "HTTPS, JSON"
        api -> reporting "Demande les indicateurs et les rapports" "HTTPS, JSON"

        identite -> baseMetier "Lit et enregistre les comptes et les rôles" "SQL"
        referentiel -> baseMetier "Enregistre les ruches et les sites" "SQL"
        telemetrie -> baseMesures "Archive les mesures validées" "SQL"
        telemetrie -> baseCache "Met en cache les lots en attente" "AMQP"
        sante -> baseMesures "Lit les mesures validées" "SQL"
        sante -> baseCache "Publie les événements de santé" "AMQP"
        terrain -> baseMetier "Enregistre les visites et les inspections" "SQL"
        terrain -> baseCache "Publie les événements terrain" "AMQP"
        production -> baseMetier "Enregistre et valide les récoltes" "SQL"
        reporting -> plateformeDonnees "Consulte les données consolidées et publie les rapports" "SQL / HTTPS"
        supervision -> baseMetier "Enregistre les incidents techniques" "SQL"

        telemetrie -> supervision "Transmet les trames rejetées et les capteurs silencieux" "AMQP"
        sante -> terrain "Signale les alertes nécessitant une visite" "AMQP"
        terrain -> sante "Transmet les inspections enregistrées" "AMQP"
        sante -> production "Transmet les prédictions de rendement" "AMQP"
        supervision -> terrain "Signale les déplacements non déclarés" "AMQP"

        referentiel -> baseCache "Publie les événements du référentiel" "AMQP"
        telemetrie -> baseCache "Publie les mesures validées" "AMQP"
        production -> baseCache "Publie les récoltes validées" "AMQP"
        baseCache -> reporting "Transmet les événements à consolider" "AMQP"

        // ==========================================
        // 7. RELATIONS DE LA PLATEFORME DE DONNEES
        // ==========================================

        telemetrie -> staging "Transmet les mesures validées" "AMQP"
        terrain -> staging "Transmet les inspections" "AMQP"
        production -> staging "Transmet les récoltes validées" "AMQP"
        meteo -> staging "Fournit les données météorologiques" "HTTPS, API JSON"

        staging -> etl "Fournit les données brutes à transformer" "Parquet"
        etl -> entrepot "Charge les données nettoyées et consolidées" "SQL"
        entrepot -> jeuxEntrainement "Fournit les données pour constituer les jeux" "SQL"
        jeuxEntrainement -> entrainement "Fournit les données d'entraînement et de validation" "Parquet"
        entrainement -> registreModeles "Enregistre les modèles évalués" "MLflow"
        entrepot -> tableauxAnalytiques "Fournit les indicateurs consolidés" "SQL"
        registreModeles -> prediction "Publie les modèles validés pour l'inférence" "MLflow / HTTPS"
    }

    // ==========================================
    // 7. VUES D'ARCHITECTURE
    // ==========================================

    views {
        systemContext queenbee "N1-Contexte" {
            include *
            autolayout tb
        }

        container queenbee "N2-Conteneurs" {
            include *
            autolayout tb
        }

        component plateformeDonnees "N3-PlateformeDonnees" {
            include *
            autolayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }

            element "Software System" {
                background #1168bd
                color #ffffff
            }

            element "Container" {
                background #438dd5
                color #ffffff
            }

            element "Component" {
                background #85bbf0
                color #000000
            }

            element "Database" {
                shape Cylinder
                background #f5da81
                color #000000
            }

            element "Externe" {
                background #999999
                color #ffffff
            }
        }
    }
}
