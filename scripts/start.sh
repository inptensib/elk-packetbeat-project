#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=============================================="
echo "  Demarrage de la stack ELK (Elasticsearch + Kibana)"
echo "=============================================="
echo ""

# Verifier que Docker est accessible
if ! docker info >/dev/null 2>&1; then
    echo "[ERREUR] Docker n'est pas accessible."
    echo "  - Verifiez que Docker Desktop est lance et que l'integration WSL est activee."
    echo "  - Ou lancez le daemon Docker : sudo service docker start"
    exit 1
fi

# Verifier que docker compose est disponible
if ! docker compose version >/dev/null 2>&1; then
    echo "[ERREUR] 'docker compose' (v2) n'est pas disponible."
    echo "  Installez Docker Desktop >= 3.6 ou docker-compose-plugin."
    exit 1
fi

echo "[INFO] Lancement des services Elasticsearch et Kibana..."
docker compose up -d elasticsearch kibana

echo ""
echo "[INFO] Attente de la disponibilite des services (peut prendre 1-2 minutes)..."

# Attendre Elasticsearch
MAX_RETRIES=30
RETRY=0
until curl -s http://localhost:9200/_cluster/health >/dev/null 2>&1; do
    RETRY=$((RETRY + 1))
    if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
        echo "[ERREUR] Elasticsearch ne repond pas apres ${MAX_RETRIES} tentatives."
        echo "  Verifiez les logs : docker compose logs elasticsearch"
        exit 1
    fi
    printf "."
    sleep 5
done
echo ""
echo "[OK] Elasticsearch est pret."

# Attendre Kibana
RETRY=0
until curl -s http://localhost:5601/api/status >/dev/null 2>&1; do
    RETRY=$((RETRY + 1))
    if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
        echo "[ERREUR] Kibana ne repond pas apres ${MAX_RETRIES} tentatives."
        echo "  Verifiez les logs : docker compose logs kibana"
        exit 1
    fi
    printf "."
    sleep 5
done
echo ""
echo "[OK] Kibana est pret."

echo ""
echo "=============================================="
echo "  Stack ELK demarree avec succes !"
echo "=============================================="
echo ""
echo "  Kibana        : http://localhost:5601"
echo "  Elasticsearch : http://localhost:9200"
echo ""
echo "  Verifier la sante : ./scripts/check-health.sh"
echo "  Lancer PacketBeat : ./scripts/run-packetbeat.sh pcaps/votre_fichier.pcap"
echo "  Arreter la stack  : ./scripts/stop.sh"
echo ""
