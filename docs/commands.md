# Commandes de reference - ELK Stack + PacketBeat sous WSL

## Installation des prerequis (WSL Ubuntu)

### Verifier WSL2

```bash
# Dans PowerShell Windows
wsl --version
wsl --list --verbose
```

### Installer Docker Engine dans WSL (si Docker Desktop non utilise)

```bash
# Mise a jour des paquets
sudo apt-get update && sudo apt-get upgrade -y

# Dependances
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Cle GPG Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Depot Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker "$USER"
newgrp docker

# Demarrer le daemon
sudo service docker start

# Verification
docker version
docker compose version
```

### Augmenter les limites memoire pour Elasticsearch

```bash
# Necessite d'etre fait a chaque demarrage WSL, ou persiste via /etc/sysctl.conf
sudo sysctl -w vm.max_map_count=262144

# Pour le rendre permanent dans WSL2 :
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system
```

---

## Demarrage du projet

### Rendre les scripts executables

```bash
chmod +x scripts/*.sh
```

### Demarrer la stack ELK

```bash
./scripts/start.sh
```

### Verifier la sante

```bash
./scripts/check-health.sh
```

### Verification manuelle via curl

```bash
# Elasticsearch
curl -s http://localhost:9200/_cluster/health | python3 -m json.tool

# Version Elasticsearch
curl -s http://localhost:9200/

# Kibana
curl -s http://localhost:5601/api/status | python3 -m json.tool
```

---

## Lancement de PacketBeat

### Analyser un fichier PCAP

```bash
./scripts/run-packetbeat.sh pcaps/votre_fichier.pcap
```

### Verifier les indices crees dans Elasticsearch

```bash
curl -s http://localhost:9200/_cat/indices/packetbeat-* | sort
```

### Compter les documents indexes

```bash
curl -s http://localhost:9200/packetbeat-*/_count | python3 -m json.tool
```

### Rechercher des evenements DNS

```bash
curl -s "http://localhost:9200/packetbeat-*/_search" \
  -H "Content-Type: application/json" \
  -d '{"query": {"term": {"type": "dns"}}, "size": 5}' | python3 -m json.tool
```

---

## Consultation des logs

### Logs Elasticsearch

```bash
docker compose logs elasticsearch
docker compose logs -f elasticsearch   # suivi en temps reel
```

### Logs Kibana

```bash
docker compose logs kibana
docker compose logs -f kibana
```

### Logs PacketBeat (pendant l'execution)

```bash
docker logs elk-packetbeat-run
```

### Etat des conteneurs

```bash
docker compose ps
docker stats --no-stream
```

---

## Arret et nettoyage

### Arreter la stack (sans supprimer les donnees)

```bash
./scripts/stop.sh
```

### Arreter et supprimer les volumes (perte des donnees)

```bash
docker compose down -v
```

### Supprimer un index specifique dans Elasticsearch

```bash
curl -X DELETE http://localhost:9200/packetbeat-8.13.4-2024.01.01
```

### Supprimer tous les indices PacketBeat

```bash
curl -X DELETE "http://localhost:9200/packetbeat-*"
```

### Nettoyer les images Docker inutilisees

```bash
docker image prune -f
```

### Nettoyage complet (conteneurs, volumes, reseaux, images)

```bash
docker compose down -v --rmi local
docker system prune -f
```

---

## Kibana - Operations utiles

### Ouvrir Kibana

```
http://localhost:5601
```

### Creer un Data View (index pattern)

1. Kibana > Stack Management > Index Patterns (ou Data Views)
2. Create data view
3. Pattern : `packetbeat-*`
4. Time field : `@timestamp`

### Exporter un dashboard

1. Stack Management > Saved Objects
2. Selectionner le dashboard
3. Export

### Importer un dashboard

```bash
curl -X POST "http://localhost:5601/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  -F file=@exports/dashboard-pcap-analyse.ndjson
```

---

## Divers

### Inspecter le reseau Docker

```bash
docker network ls
docker network inspect elk-packetbeat-project_elk-net
```

### Entrer dans le conteneur Elasticsearch

```bash
docker exec -it elk-elasticsearch bash
```

### Entrer dans le conteneur Kibana

```bash
docker exec -it elk-kibana bash
```

### Tester la resolution DNS interne Docker

```bash
docker exec elk-kibana curl -s http://elasticsearch:9200/
```
