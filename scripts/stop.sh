#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=============================================="
echo "  Arret de la stack ELK"
echo "=============================================="
echo ""

if ! docker info >/dev/null 2>&1; then
    echo "[ERREUR] Docker n'est pas accessible."
    exit 1
fi

echo "[INFO] Arret de tous les conteneurs ELK..."
docker compose down

echo ""
echo "[OK] Stack arretee. Les donnees Elasticsearch sont preservees dans le volume Docker."
echo ""
echo "  Pour supprimer egalement les volumes (perte des donnees) :"
echo "    docker compose down -v"
echo ""
