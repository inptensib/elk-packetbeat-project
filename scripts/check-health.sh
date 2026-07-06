#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo "  Verification de la sante de la stack ELK"
echo "=============================================="
echo ""

ALL_OK=true

# --- Elasticsearch ---
echo -n "  Elasticsearch (localhost:9200) ... "
ES_RESPONSE=$(curl -s --max-time 5 http://localhost:9200/_cluster/health 2>/dev/null || true)

if [ -z "$ES_RESPONSE" ]; then
    echo "HORS LIGNE"
    echo "    -> Demarrez la stack : ./scripts/start.sh"
    ALL_OK=false
else
    ES_STATUS=$(echo "$ES_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || true)
    case "$ES_STATUS" in
        green)  echo "OK (green)" ;;
        yellow) echo "OK (yellow - normal en cluster 1 noeud)" ;;
        red)    echo "DEGRADED (red)" ; ALL_OK=false ;;
        *)      echo "INCONNU ($ES_RESPONSE)" ; ALL_OK=false ;;
    esac
fi

# --- Kibana ---
echo -n "  Kibana        (localhost:5601) ... "
KB_RESPONSE=$(curl -s --max-time 10 http://localhost:5601/api/status 2>/dev/null || true)

if [ -z "$KB_RESPONSE" ]; then
    echo "HORS LIGNE"
    echo "    -> Demarrez la stack : ./scripts/start.sh"
    ALL_OK=false
else
    KB_LEVEL=$(echo "$KB_RESPONSE" | grep -o '"level":"[^"]*"' | head -1 | cut -d'"' -f4 || true)
    if [ "$KB_LEVEL" = "available" ]; then
        echo "OK (available)"
    else
        echo "EN DEMARRAGE ou DEGRADED (level=$KB_LEVEL)"
        ALL_OK=false
    fi
fi

echo ""
if [ "$ALL_OK" = true ]; then
    echo "  Tous les services sont operationnels."
    echo ""
    echo "  Kibana        : http://localhost:5601"
    echo "  Elasticsearch : http://localhost:9200"
else
    echo "  Un ou plusieurs services ne repondent pas correctement."
    echo "  Consultez les logs : docker compose logs"
    exit 1
fi
echo ""
