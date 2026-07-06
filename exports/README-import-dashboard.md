# Import Des Dashboards Kibana — 4SICS ELK Project

## Contenu du dossier `exports/`

| Fichier | Description |
|---|---|
| `4sics-dashboards.ndjson` | Export officiel Kibana (16 objets : 1 data view + 13 visualisations + 2 dashboards) |
| `import-4sics-dashboards.js` | Script Node.js d'import automatique via l'API Kibana |
| `README-import-dashboard.md` | Ce fichier |

---

## Pourquoi un `.ndjson` ET un `.js` ?

### Le fichier `.ndjson` — le livrable principal

Les versions modernes de Kibana (8.x) exportent les dashboards au format **NDJSON** (*Newline-Delimited JSON*) via l'API Saved Objects. C'est le format officiel et réimportable dans n'importe quelle instance Kibana 8.x.

Le fichier `4sics-dashboards.ndjson` contient :
- 1 data view `packetbeat-*`
- 13 visualisations Kibana Lens
- 2 dashboards

### Le fichier `.js` — le script d'import

Le script `import-4sics-dashboards.js` est un script **Node.js** qui automatise l'import en appelant l'API Kibana (`POST /api/saved_objects/_import`). Il est fourni pour satisfaire la demande d'un livrable JavaScript, et comme alternative à l'import manuel via l'interface Kibana.

---

## Prérequis

### Stack ELK démarrée

```bash
cd ~/projects/DATA707/elk-packetbeat-project
./scripts/start.sh
./scripts/check-health.sh
```

Kibana doit répondre sur `http://localhost:5601`.

### Node.js (pour le script d'import)

```bash
# Vérifier si Node.js est installé
node --version
```

Si Node.js n'est pas installé dans WSL :

```bash
# Installation via nvm (recommandé)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
node --version
```

Le script est compatible **Node.js 12+** et n'utilise aucune dépendance externe.

---

## Méthode 1 — Import automatique via le script Node.js

```bash
cd ~/projects/DATA707/elk-packetbeat-project/exports
node import-4sics-dashboards.js
```

### Variables d'environnement disponibles

| Variable | Description | Défaut |
|---|---|---|
| `KIBANA_URL` | URL de l'instance Kibana | `http://localhost:5601` |
| `KIBANA_USERNAME` | Utilisateur (si sécurité activée) | *(vide)* |
| `KIBANA_PASSWORD` | Mot de passe (si sécurité activée) | *(vide)* |

Exemples :

```bash
# URL personnalisée
KIBANA_URL=http://192.168.1.10:5601 node import-4sics-dashboards.js

# Avec authentification (si xpack.security est activé)
KIBANA_USERNAME=elastic KIBANA_PASSWORD=motdepasse node import-4sics-dashboards.js
```

> Dans ce projet, la sécurité Elastic est désactivée (`xpack.security.enabled=false`). Aucune authentification n'est nécessaire.

### Exemple de sortie attendue

```
════════════════════════════════════════════════════════
  Import Dashboards Kibana — 4SICS ELK Project
════════════════════════════════════════════════════════

[INFO]  Node.js v20.11.0
[INFO]  Kibana cible : http://localhost:5601

[OK]    Fichier trouvé : 4sics-dashboards.ndjson (370 Ko, 16 objets)
[OK]    Kibana disponible (status=available)
[INFO]  Import vers http://localhost:5601/api/saved_objects/_import?overwrite=true ...

════════════════════════════════════════════════════════
  Résultat de l'import Kibana
════════════════════════════════════════════════════════
  Objets importés avec succès : 16
  Data views     : 1
  Visualisations : 13
  Dashboards     : 2

  URL Kibana : http://localhost:5601
  Aller dans : Kibana > Dashboard

  Dashboards disponibles :
    - Dashboard 1 - Vue Globale Du Trafic ICS
    - Dashboard 2 - Analyse Des Equipements ICS

  IMPORTANT : réglez la plage temporelle sur
    2015-10-20 → aujourd'hui
  pour voir l'intégralité des données.
════════════════════════════════════════════════════════
```

---

## Méthode 2 — Import manuel via l'interface Kibana

1. Ouvrir Kibana : `http://localhost:5601`
2. Aller dans **Stack Management** (menu hamburger en haut à gauche)
3. Aller dans **Saved Objects**
4. Cliquer sur **Import**
5. Sélectionner le fichier `4sics-dashboards.ndjson`
6. Cocher **Automatically overwrite conflicts** si des objets existent déjà
7. Cliquer sur **Import**
8. Aller dans **Dashboard** — les deux dashboards apparaissent

---

## Méthode 3 — Import via curl (sans Node.js)

```bash
curl -s -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  -F file=@4sics-dashboards.ndjson | python3 -m json.tool
```

---

## Après l'import — Réglage de la plage temporelle

Les données du PCAP 4SICS couvrent deux plages de dates :

| Type d'événement | Timestamp |
|---|---|
| DNS, ICMP | 20 octobre 2015 (date de capture originale) |
| Flows (S7comm, TCP/UDP) | Date d'analyse avec PacketBeat |

**Dans Kibana**, régler la plage temporelle sur :
- **De** : `2015-10-20`
- **À** : `now` (ou la date d'analyse)

Les dashboards sont pré-configurés avec cette plage.

---

## Contenu détaillé du fichier NDJSON

| Objet | ID Kibana | Description |
|---|---|---|
| Data view | `packetbeat-*` | Index pattern PacketBeat |
| Visualisation | `4sics-v01-total-events` | Métrique : total événements |
| Visualisation | `4sics-v02-timeline` | Évolution temporelle du trafic |
| Visualisation | `4sics-v03-top-src-ip` | Top IP sources |
| Visualisation | `4sics-v04-top-dst-ip` | Top IP destinations |
| Visualisation | `4sics-v05-top-dst-port` | Top ports destination |
| Visualisation | `4sics-v06-protocols` | Protocoles détectés |
| Visualisation | `4sics-v07-conversations` | Table des conversations |
| Visualisation | `4sics-v08-equip-dest` | Top équipements contactés |
| Visualisation | `4sics-v09-equip-src` | Top équipements émetteurs |
| Visualisation | `4sics-v10-services` | Services et ports observés |
| Visualisation | `4sics-v11-industrial-ports` | Ports industriels (102, 502, 20000) |
| Visualisation | `4sics-v12-unencrypted` | Services non chiffrés (21, 23, 80) |
| Visualisation | `4sics-v13-comm-matrix` | Matrice des communications |
| Dashboard | `4sics-d01-global` | Dashboard 1 - Vue Globale Du Trafic ICS |
| Dashboard | `4sics-d02-ics` | Dashboard 2 - Analyse Des Equipements ICS |
