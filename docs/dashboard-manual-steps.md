# Étapes Manuelles — Création Des Dashboards Kibana Lens

Ce guide permet de recréer les dashboards **sans utiliser l'import NDJSON**, directement depuis l'interface Kibana Lens.

## Prérequis

- Kibana accessible sur `http://localhost:5601`
- Data view `packetbeat-*` avec `@timestamp` comme champ temporel
- Données PacketBeat présentes dans Elasticsearch
- Plage de temps réglée sur **20 octobre 2015** dans Kibana

---

## Étape 0 — Régler la plage temporelle

Dans Kibana, en haut à droite, cliquer sur le sélecteur de date :
- **Absolute** → From : `2015-10-20 00:00:00` → To : `2015-10-21 00:00:00`
- Appliquer.

---

## Créer les visualisations Kibana Lens

Aller dans **Visualize Library** → **Create visualization** → choisir **Lens**.

---

### VIZ 1 — Total Événements (Metric)

1. Type de visualisation : **Metric**
2. Panneau central : glisser `Count of records` dans la zone Metric
3. Label : "Total événements"
4. Sauvegarder sous : `Total Événements PacketBeat`

---

### VIZ 2 — Evolution Temporelle Du Trafic (Area)

1. Type : **Area** (ou Line)
2. Axe X : glisser `@timestamp` → Date histogram → intervalle : Auto
3. Axe Y : `Count of records`
4. Sauvegarder sous : `Evolution Temporelle Du Trafic`

---

### VIZ 3 — Top IP Sources (Bar horizontal)

1. Type : **Bar horizontal**
2. Axe vertical (valeurs) : `Count of records`
3. Axe horizontal (catégories) : glisser `source.ip` → Terms → Taille : 10 → Tri : Count desc
4. Sauvegarder sous : `Top IP Sources`

---

### VIZ 4 — Top IP Destinations (Bar horizontal)

1. Type : **Bar horizontal**
2. Axe vertical : `Count of records`
3. Axe horizontal : `destination.ip` → Terms → Taille : 10 → Tri : Count desc
4. Sauvegarder sous : `Top IP Destinations`

---

### VIZ 5 — Top Ports Destination (Bar horizontal)

1. Type : **Bar horizontal**
2. Axe vertical : `Count of records`
3. Axe horizontal : `destination.port` → Terms → Taille : 15 → Tri : Count desc
4. Sauvegarder sous : `Top Ports Destination`

---

### VIZ 6 — Protocoles Détectés (Donut)

1. Type : **Donut**
2. Slice by : `event.dataset` → Terms → Taille : 10
3. Size by : `Count of records`
4. Display : Percent
5. Sauvegarder sous : `Protocoles Détectés`

---

### VIZ 7 — Table Des Conversations (Datatable)

1. Type : **Table**
2. Colonnes (glisser dans l'ordre) :
   - `source.ip` → Terms → Taille 100
   - `destination.ip` → Terms → Taille 10
   - `destination.port` → Terms → Taille 10
   - `network.transport` → Terms → Taille 5
   - `Count of records`
3. Tri : Count desc
4. Sauvegarder sous : `Table Des Conversations Réseau`

---

### VIZ 8 — Top Équipements Contactés (Bar horizontal)

Identique à VIZ 4, renommer en `Top Équipements Contactés`.

---

### VIZ 9 — Top Équipements Émetteurs (Bar horizontal)

Identique à VIZ 3, renommer en `Top Équipements Émetteurs`.

---

### VIZ 10 — Services Et Ports Observés (Bar horizontal)

Identique à VIZ 5 avec Taille : 20, renommer en `Services Et Ports Observés`.

---

### VIZ 11 — Communications Ports Industriels (Datatable filtrée)

1. Type : **Table**
2. **Ajouter un filtre global** (bouton + Filters) :
   ```
   destination.port: 102 OR destination.port: 502 OR destination.port: 20000
   ```
3. Colonnes :
   - `source.ip` → Terms → Taille 100
   - `destination.ip` → Terms → Taille 10
   - `destination.port` → Terms → Taille 10
   - `network.transport` → Terms → Taille 5
   - `Count of records`
4. Sauvegarder sous : `Communications Vers Ports Industriels`

---

### VIZ 12 — Services Non Chiffrés (Datatable filtrée)

1. Type : **Table**
2. **Filtre global** :
   ```
   destination.port: 21 OR destination.port: 23 OR destination.port: 80
   ```
3. Colonnes :
   - `source.ip` → Terms → Taille 100
   - `destination.ip` → Terms → Taille 10
   - `destination.port` → Terms → Taille 5
   - `Count of records`
4. Sauvegarder sous : `Communications Vers Services Non Chiffrés`

---

### VIZ 13 — Matrice Des Communications (Datatable)

1. Type : **Table**
2. Colonnes :
   - `source.ip` → Terms → Taille 20
   - `destination.ip` → Terms → Taille 10
   - `destination.port` → Terms → Taille 10
   - `Count of records` (label : "Nombre de flux")
3. Tri : Count desc
4. Sauvegarder sous : `Matrice Des Communications`

---

## Créer Le Dashboard 1 — Vue Globale Du Trafic ICS

1. Aller dans **Dashboard** → **Create dashboard**
2. Cliquer **Add from library**
3. Ajouter dans cet ordre et disposer :

| Widget | Position approximative |
|---|---|
| Total Événements PacketBeat | Haut gauche (petit) |
| Protocoles Détectés (donut) | Haut milieu |
| Evolution Temporelle (area) | Haut droite ou toute la largeur |
| Top IP Sources | Milieu gauche |
| Top IP Destinations | Milieu droite |
| Top Ports Destination | Bas gauche |
| Table Des Conversations | Bas droite |

4. Régler la plage temporelle sur **20/10/2015**
5. Sauvegarder sous : `Dashboard 1 - Vue Globale Du Trafic ICS`

---

## Créer Le Dashboard 2 — Analyse Des Equipements ICS

1. **Dashboard** → **Create dashboard**
2. Ajouter :

| Widget | Position approximative |
|---|---|
| Top Équipements Contactés | Haut gauche |
| Top Équipements Émetteurs | Haut droite |
| Services Et Ports Observés | Milieu gauche |
| Matrice Des Communications | Milieu droite |
| Communications Ports Industriels | Toute la largeur |
| Services Non Chiffrés | Toute la largeur |

3. Sauvegarder sous : `Dashboard 2 - Analyse Des Equipements ICS`

---

## Exporter Les Dashboards

1. **Stack Management** → **Saved Objects**
2. Cocher les deux dashboards
3. Cliquer **Export**
4. Déplacer le fichier téléchargé :
   ```bash
   mv ~/Downloads/export.ndjson exports/4sics-dashboards.ndjson
   ```

Ou via l'API :
```bash
curl -s -X POST "http://localhost:5601/api/saved_objects/_export" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "objects": [
      {"type": "dashboard", "id": "4sics-d01-global"},
      {"type": "dashboard", "id": "4sics-d02-ics"}
    ],
    "includeReferencesDeep": true
  }' -o exports/4sics-dashboards.ndjson
```
