# Guide Des Dashboards Kibana - Analyse 4SICS

## Données Source

| Propriété | Valeur |
|---|---|
| Fichier PCAP | `4SICS-GeekLounge-151020.pcap` |
| Date de capture | 20 octobre 2015 |
| Documents indexés | **40 000** |
| Index Elasticsearch | `.ds-packetbeat-8.13.4-2015.10.20-*` |
| Data view Kibana | `packetbeat-*` |

### Répartition du trafic capturé

| Type (event.dataset) | Documents | Description |
|---|---|---|
| `flow` | 23 833 | Flux TCP/UDP (NetFlow-like) |
| `dns` | 13 427 | Requêtes et réponses DNS |
| `icmp` | 2 740 | Pings et messages ICMP |

### Principaux acteurs réseau identifiés

| IP | Rôle | Équipement |
|---|---|---|
| `10.10.10.10` | Destination principale (port 102) | Siemens SIMATIC S7 PLC |
| `10.10.10.30` | Émetteur principal vers le PLC | Poste SCADA / Engineering |
| `192.168.88.61` | Émetteur DNS | Moxa EDS-508A (switch) |
| `192.168.88.1` | Serveur DNS local | Routeur/DNS local |
| `8.8.8.8` | Destination DNS externe | Google DNS |
| `192.168.89.1/2` | Trafic ICMP | Segments réseau interne |

### Ports observés

| Port | Protocole | Trafic observé |
|---|---|---|
| **102** | S7comm / ISO-TSAP (Siemens) | **18 021 événements** — trafic ICS dominant |
| **53** | DNS | 18 926 événements |
| **123** | NTP | 3 événements |

> **Note** : Aucun trafic Modbus (502), DNP3 (20000), FTP (21), Telnet (23) ou HTTP (80) n'est présent dans ce PCAP. Les visualisations correspondantes affichent "no results" — ce qui est en soi une information : ces protocoles ne sont pas exposés dans ce segment.

---

## Dashboard 1 — Vue Globale Du Trafic ICS

**Objectif** : Donner une vue d'ensemble statistique du trafic réseau capturé.

**Plage temporelle configurée** : 20 octobre 2015 (ajusté sur la date réelle de la capture).

### Widgets

| # | Nom | Type Lens | Champ(s) | Mesure |
|---|---|---|---|---|
| 1 | Total Événements PacketBeat | `lnsMetric` | `___records___` | count |
| 2 | Protocoles Détectés | `lnsPie` (donut) | `event.dataset` | count |
| 3 | Evolution Temporelle Du Trafic | `lnsXY` (area) | `@timestamp` | count |
| 4 | Top IP Sources | `lnsXY` (bar horizontal) | `source.ip` | count |
| 5 | Top IP Destinations | `lnsXY` (bar horizontal) | `destination.ip` | count |
| 6 | Top Ports Destination | `lnsXY` (bar horizontal) | `destination.port` | count |
| 7 | Table Des Conversations | `lnsDatatable` | `source.ip`, `destination.ip`, `destination.port`, `network.transport` | count |

### Résultats attendus

- **Total** : 40 000 événements
- **Donut protocoles** : flow (60%), dns (34%), icmp (7%)
- **Top source** : `10.10.10.30` largement dominant (18 018 événements)
- **Top destination** : `10.10.10.10` (PLC Siemens) — 18 021 événements
- **Top port** : 102 (S7comm) et 53 (DNS) dominent

---

## Dashboard 2 — Analyse Des Equipements ICS

**Objectif** : Identifier et analyser les équipements industriels, leurs communications et les protocoles ICS présents.

### Widgets

| # | Nom | Type Lens | Champ(s) | Filtre | Mesure |
|---|---|---|---|---|---|
| 1 | Top Équipements Contactés | `lnsXY` (bar h) | `destination.ip` | — | count |
| 2 | Top Équipements Émetteurs | `lnsXY` (bar h) | `source.ip` | — | count |
| 3 | Services Et Ports Observés | `lnsXY` (bar h) | `destination.port` | — | count |
| 4 | Matrice Des Communications | `lnsDatatable` | `source.ip`, `destination.ip`, `destination.port` | — | count |
| 5 | Ports Industriels | `lnsDatatable` | `source.ip`, `destination.ip`, `destination.port`, `network.transport` | port IN (102, 502, 20000) | count |
| 6 | Services Non Chiffrés | `lnsDatatable` | `source.ip`, `destination.ip`, `destination.port` | port IN (21, 23, 80) | count |

### Filtres appliqués

**Widget 5 — Ports industriels** :
```
destination.port: 102 OR destination.port: 502 OR destination.port: 20000
```
→ Seul le port 102 (S7comm Siemens) a du trafic dans ce PCAP.

**Widget 6 — Services non chiffrés** :
```
destination.port: 21 OR destination.port: 23 OR destination.port: 80
```
→ Aucun résultat dans ce PCAP (bonne pratique observée dans ce segment).

### Résultats attendus

- **Équipement le plus contacté** : `10.10.10.10` = Siemens S7 PLC
- **Émetteur principal** : `10.10.10.30` = poste SCADA/engineering
- **Communication S7comm** : trafic exclusif entre `10.10.10.30` → `10.10.10.10:102`
- **DNS** : `192.168.88.61` → `192.168.88.1` (DNS local) + vers `8.8.8.8`

### Tableau des équipements ICS du réseau 4SICS

| IP | Équipement | Rôle |
|---|---|---|
| `10.10.10.10` | Siemens SIMATIC S7 PLC | Automate industriel — port 102 (S7comm) |
| `10.10.10.30` | Poste SCADA/Engineering | Émetteur de commandes S7 |
| `192.168.88.15` | DirectLogic 205 PLC | Automate (trafic non visible dans ce PCAP) |
| `192.168.88.20` | Phoenix Contact FL IL 24 BK-PAC | Coupleur de bus |
| `192.168.88.25` | Advantech ADAM-5500 | Module d'acquisition |
| `192.168.88.30` | Siemens SIMATIC S7-1200 | Automate |
| `192.168.88.49` | AXIS 206 Network Camera | Caméra IP |
| `192.168.88.50` | Red Lion DSP | Interface homme-machine |
| `192.168.88.60` | Moxa EDS-508A | Switch industriel |
| `192.168.88.61` | Moxa EDS-508A | Switch industriel (actif DNS) |
| `192.168.88.75` | Hirschmann EAGLE 20 Tofino | Firewall industriel |
| `192.168.88.80` | Moxa UC-7112 | Gateway Linux embarquée |
| `192.168.88.91–95` | RUGGEDCOM RS910 | Switch industriel redondant |
| `192.168.88.100` | HOST Engineering Modbus gateway | Passerelle Modbus |
| `192.168.88.115` | Westermo Digi | Routeur industriel |

---

## Importer les dashboards dans Kibana

### Depuis l'interface Kibana

1. Aller dans **Stack Management** → **Saved Objects**.
2. Cliquer sur **Import**.
3. Glisser-déposer `exports/4sics-dashboards.ndjson` ou cliquer pour sélectionner le fichier.
4. Cocher **Automatically overwrite conflicts** si nécessaire.
5. Cliquer sur **Import**.
6. Aller dans **Dashboard** → les deux dashboards apparaissent.

### Via l'API Kibana (ligne de commande)

```bash
curl -s -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  -F file=@exports/4sics-dashboards.ndjson | python3 -m json.tool
```

> **Important** : Après import, si les visualisations affichent "No results", vérifiez la plage temporelle dans Kibana. Elle doit couvrir le **20 octobre 2015**. Les dashboards sont pré-configurés avec cette plage.

---

## Présentation Dans Le Rapport PDF

### Dashboard 1 — captures recommandées

1. **Vue d'ensemble** : capture plein écran du dashboard avec tous les widgets visibles.
2. **Donut protocoles** : zoom sur le widget Protocoles Détectés — illustre la dominance du trafic S7comm.
3. **Timeline** : zoom sur l'évolution temporelle — montre la densité du trafic ICS.
4. **Top IPs** : zoom sur la table des conversations — montre la communication PLC → SCADA.

### Dashboard 2 — captures recommandées

1. **Vue d'ensemble** du dashboard 2.
2. **Widget "Ports industriels"** : zoom sur la table — 18 021 événements vers port 102 = preuve concrète de communication S7comm.
3. **Widget "Services non chiffrés"** : tableau vide = absence de FTP/Telnet/HTTP dans ce segment (point positif de sécurité à mentionner).
4. **Matrice de communications** : zoom sur la table pour montrer les paires IP les plus actives.

### Messages clés à formuler dans le rapport

- Le trafic dominant est **S7comm (port 102)** entre un poste engineering (`10.10.10.30`) et un PLC Siemens (`10.10.10.10`).
- Le DNS est actif sur plusieurs équipements (Moxa EDS-508A — `192.168.88.61`), ce qui est normal pour la synchronisation d'horloge et la résolution de noms.
- **Aucun service non chiffré** (FTP, Telnet, HTTP) n'est visible dans ce segment — bonne pratique.
- Le protocole S7comm est **non chiffré** par défaut (Siemens S7 < S7-1500 v2), ce qui représente un risque résiduel.

---

## Fichier Exporté

| Fichier | Contenu | Taille |
|---|---|---|
| `exports/4sics-dashboards.ndjson` | 2 dashboards + 13 visualisations + 1 data view | ~370 Ko |

Le fichier est **réimportable** dans n'importe quelle instance Kibana 8.x connectée à des données PacketBeat avec les mêmes champs.
