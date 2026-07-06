# ELK Stack + PacketBeat - Analyse de captures reseau PCAP

Environnement local sous **WSL2 + Docker** pour analyser des fichiers PCAP avec PacketBeat et visualiser les donnees dans Kibana.

## But du projet

Ce projet permet de :
- Lire un fichier de capture reseau (PCAP) avec PacketBeat.
- Indexer automatiquement les evenements reseau dans Elasticsearch.
- Explorer et visualiser les donnees dans Kibana (protocoles, IPs, flux...).
- Creer et exporter des dashboards Kibana.

## Architecture

```
Fichier PCAP  -->  PacketBeat  -->  Elasticsearch  -->  Kibana  -->  Dashboard
```

Voir [docs/architecture.md](docs/architecture.md) pour le detail.

---

## Prerequis

### Cote Windows

- Windows 10/11 avec WSL2 active.
- **Docker Desktop** avec integration WSL2 activee (recommande), OU Docker Engine installe directement dans WSL.

### Cote WSL2 (Ubuntu)

- WSL2 avec Ubuntu 20.04 ou 22.04.
- Travaillez **depuis le systeme de fichiers Linux** (`~/projects/...`), pas depuis `/mnt/c/...`.

### Limites memoire Elasticsearch

Elasticsearch necessite une limite kernel elevee :

```bash
sudo sysctl -w vm.max_map_count=262144
```

Pour le rendre permanent :

```bash
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system
```

### Demarrage du daemon Docker (si Docker Engine sans Docker Desktop)

```bash
sudo service docker start
```

---

## Installation

### 1. Cloner ou ouvrir le projet

```bash
cd ~/projects/elk-packetbeat-project
```

### 2. Rendre les scripts executables

```bash
chmod +x scripts/*.sh
```

### 3. Copier le fichier d'environnement (optionnel)

```bash
cp .env.example .env
```

> La configuration par defaut fonctionne sans modification pour un usage local.

---

## Utilisation

### 4. Placer votre fichier PCAP

Copiez votre capture reseau dans le dossier `pcaps/` :

```bash
cp /chemin/vers/votre_capture.pcap pcaps/
```

Exemples de sources PCAP publiques :
- [Wireshark Sample Captures](https://wiki.wireshark.org/SampleCaptures)
- [Malware Traffic Analysis](https://malware-traffic-analysis.net/)

### 5. Demarrer la stack ELK

```bash
./scripts/start.sh
```

Attendez que les deux services soient prets (environ 1-2 minutes).

### 6. Verifier la sante des services

```bash
./scripts/check-health.sh
```

### 7. Lancer PacketBeat sur le fichier PCAP

```bash
./scripts/run-packetbeat.sh pcaps/votre_fichier.pcap
```

PacketBeat lit le fichier, extrait les evenements (DNS, HTTP, TLS, ICMP...) et les envoie vers Elasticsearch. Il se termine automatiquement a la fin du fichier.

### 8. Ouvrir Kibana

Ouvrez votre navigateur Windows et allez sur :

```
http://localhost:5601
```

### 9. Explorer les donnees

1. Aller dans **Discover**.
2. Creer un **Data View** avec le pattern `packetbeat-*`.
3. Selectionner un champ de temps : `@timestamp`.
4. Ajuster la plage de temps selon votre capture.

### 10. Creer un dashboard

1. Aller dans **Dashboard** > **Create dashboard**.
2. Ajouter des visualisations :
   - **Pie chart** : repartition des types de protocoles (`type`).
   - **Data table** : top des adresses IP sources (`source.ip`).
   - **Bar chart** : volume de trafic par heure.
3. Sauvegarder le dashboard.

### 11. Exporter le dashboard

1. Aller dans **Stack Management** > **Saved Objects**.
2. Selectionner le dashboard.
3. Cliquer sur **Export**.
4. Deplacer le fichier `.ndjson` dans `exports/`.

### 12. Arreter l'environnement

```bash
./scripts/stop.sh
```

Les donnees sont preservees dans le volume Docker. Pour tout supprimer :

```bash
docker compose down -v
```

---

## Commandes de reference rapide

```bash
# Rendre les scripts executables
chmod +x scripts/*.sh

# Demarrer ELK
./scripts/start.sh

# Verifier la sante
./scripts/check-health.sh

# Analyser un PCAP
./scripts/run-packetbeat.sh pcaps/sample.pcap

# Arreter
./scripts/stop.sh
```

---

## Note de securite

> **IMPORTANT** : La securite Elastic (TLS + authentification via `xpack.security`) est **desactivee** dans cette configuration pour simplifier la demonstration pedagogique.
>
> - Elasticsearch et Kibana n'ecoutent que sur `127.0.0.1` (loopback).
> - Cette configuration est **uniquement adaptee a un usage local isole**.
> - **Ne jamais deployer cette configuration en production** ou sur un reseau partage.

---

## Problemes frequents

### Elasticsearch ne demarre pas (`vm.max_map_count` trop bas)

```bash
sudo sysctl -w vm.max_map_count=262144
```

### Docker n'est pas accessible

```bash
# Demarrer le daemon
sudo service docker start

# Ou verifier l'integration WSL dans Docker Desktop
```

### Kibana affiche "Kibana server is not ready yet"

Attendez 1-2 minutes supplementaires. Kibana attend qu'Elasticsearch soit completement disponible.

```bash
docker compose logs kibana
```

### PacketBeat echoue avec "network not found"

Le reseau Docker `elk-packetbeat-project_elk-net` n'existe pas encore. Lancez d'abord :

```bash
./scripts/start.sh
```

### Les donnees n'apparaissent pas dans Kibana

1. Verifiez que PacketBeat a bien termine sans erreur.
2. Verifiez les indices crees : `curl http://localhost:9200/_cat/indices/packetbeat-*`
3. Ajustez la plage de temps dans Kibana (le `@timestamp` correspond a la date de la capture, pas d'aujourd'hui).

### Erreur de permissions sur `packetbeat.yml`

PacketBeat refuse les fichiers de config avec des permissions trop ouvertes. Le flag `--strict.perms=false` est passe automatiquement par les scripts.

---

## Creation Et Export Des Dashboards Kibana

Deux dashboards Kibana sont fournis pour l'analyse du PCAP `4SICS-GeekLounge-151020.pcap`.

### Importer les dashboards (fichier fourni)

```bash
curl -s -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  -F file=@exports/4sics-dashboards.ndjson | python3 -m json.tool
```

Ou via l'interface Kibana : **Stack Management** → **Saved Objects** → **Import** → choisir `exports/4sics-dashboards.ndjson`.

### Dashboards disponibles

| Dashboard | Description |
|---|---|
| `Dashboard 1 - Vue Globale Du Trafic ICS` | Vue d'ensemble : protocoles, IPs, ports, timeline |
| `Dashboard 2 - Analyse Des Equipements ICS` | Équipements ICS, ports industriels (S7comm/Modbus), matrice de communications |

> **Important** : Apres import, reglez la plage de temps sur **20 octobre 2015** dans Kibana pour voir les donnees.

### Exporter les dashboards (regenerer le NDJSON)

```bash
curl -s -X POST "http://localhost:5601/api/saved_objects/_export" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{"objects":[{"type":"dashboard","id":"4sics-d01-global"},{"type":"dashboard","id":"4sics-d02-ics"}],"includeReferencesDeep":true}' \
  -o exports/4sics-dashboards.ndjson
```

### Documentation des dashboards

- [Guide complet des dashboards](docs/dashboard-guide.md) - Widgets, champs, filtres, resultats
- [Etapes manuelles](docs/dashboard-manual-steps.md) - Recreer les visualisations manuellement dans Kibana Lens

---

## Documentation

- [Architecture](docs/architecture.md) - Composants et schema
- [Workflow](docs/workflow.md) - Flux de traitement detaille
- [Commandes](docs/commands.md) - Reference complete des commandes
- [Guide dashboards](docs/dashboard-guide.md) - Analyse 4SICS, widgets, resultats
- [Etapes manuelles](docs/dashboard-manual-steps.md) - Reproduction manuelle des dashboards
