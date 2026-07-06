#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# ---- Usage ----
usage() {
    echo "Usage: $0 <chemin_vers_fichier.pcap>"
    echo ""
    echo "  Exemple : $0 pcaps/sample.pcap"
    echo ""
    echo "  Le fichier doit etre place dans le dossier pcaps/ du projet."
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

PCAP_PATH="$1"

# ---- Verifications ----

# Verifier que Docker est accessible
if ! docker info >/dev/null 2>&1; then
    echo "[ERREUR] Docker n'est pas accessible."
    echo "  Lancez la stack d'abord : ./scripts/start.sh"
    exit 1
fi

# Verifier que le fichier existe
if [ ! -f "$PCAP_PATH" ]; then
    echo "[ERREUR] Fichier PCAP introuvable : $PCAP_PATH"
    echo ""
    echo "  Placez votre fichier PCAP dans le dossier pcaps/ :"
    echo "    cp /chemin/vers/votre/capture.pcap pcaps/"
    echo ""
    echo "  Puis relancez : $0 pcaps/votre_capture.pcap"
    exit 1
fi

# Verifier l'extension
case "$PCAP_PATH" in
    *.pcap|*.pcapng|*.cap) ;;
    *)
        echo "[AVERTISSEMENT] L'extension du fichier ne ressemble pas a un PCAP : $PCAP_PATH"
        echo "  Formats attendus : .pcap, .pcapng, .cap"
        ;;
esac

# Verifier qu'Elasticsearch est disponible
if ! curl -s --max-time 5 http://localhost:9200/_cluster/health >/dev/null 2>&1; then
    echo "[ERREUR] Elasticsearch n'est pas accessible sur localhost:9200."
    echo "  Demarrez la stack d'abord : ./scripts/start.sh"
    exit 1
fi

# ---- Extraction du nom de fichier pour le montage ----
PCAP_FILENAME=$(basename "$PCAP_PATH")
PCAP_ABS_DIR="$(cd "$(dirname "$PCAP_PATH")" && pwd)"

echo "=============================================="
echo "  Lancement de PacketBeat"
echo "=============================================="
echo ""
echo "  Fichier PCAP : $PCAP_FILENAME"
echo "  Dossier      : $PCAP_ABS_DIR"
echo ""

# ---- Lancement PacketBeat avec Docker directement ----
# On utilise docker run pour permettre de passer -I (input file) a packetbeat
# tout en montant le dossier pcaps en lecture seule.

docker run --rm \
    --name elk-packetbeat-run \
    --network elk-packetbeat-project_elk-net \
    --user root \
    --cap-add NET_ADMIN \
    --cap-add NET_RAW \
    -v "$PROJECT_DIR/config/packetbeat.yml:/usr/share/packetbeat/packetbeat.yml:ro" \
    -v "$PCAP_ABS_DIR:/pcaps:ro" \
    docker.elastic.co/beats/packetbeat:8.13.4 \
    packetbeat -e \
        -c /usr/share/packetbeat/packetbeat.yml \
        --strict.perms=false \
        -E packetbeat.interfaces.file="/pcaps/${PCAP_FILENAME}" \
        -t \
        -E output.elasticsearch.hosts='["http://elasticsearch:9200"]' \
        -E setup.kibana.host="kibana:5601"

echo ""
echo "[OK] PacketBeat a termine le traitement du fichier PCAP."
echo ""
echo "  Ouvrez Kibana pour visualiser les resultats :"
echo "    http://localhost:5601"
echo ""
echo "  Index cree dans Elasticsearch : packetbeat-*"
echo "  Consultez dans Kibana > Discover > selectionner l'index packetbeat-*"
echo ""
