#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
BACKUP_DIR="/backup"
LOG_FILE="/var/log/backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_CONTAINER="odoo-db"
ODOO_VOLUME="odoo-filestore"
ARCHIVE_NAME="backup_${TIMESTAMP}.tar.gz"
WORK_DIR=$(mktemp -d)

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE" >/dev/null
}

if [ ! -f "$ENV_FILE" ]; then
    echo "Erreur : fichier .env introuvable ($ENV_FILE)" >&2
    exit 1
fi
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

mkdir -p "$BACKUP_DIR"
log "=== Début sauvegarde ==="

log "pg_dump de la base ${POSTGRES_DB}..."
docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "$DB_CONTAINER" \
    pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -F p \
    > "$WORK_DIR/db.sql"
log "pg_dump terminé : $WORK_DIR/db.sql"

log "Archivage du filestore Odoo (volume ${ODOO_VOLUME})..."
docker run --rm \
    -v "${ODOO_VOLUME}:/data:ro" \
    -v "$WORK_DIR:/backup_tmp" \
    alpine \
    tar czf /backup_tmp/filestore.tar.gz -C /data .
log "Filestore archivé : $WORK_DIR/filestore.tar.gz"

tar czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$WORK_DIR" db.sql filestore.tar.gz
log "Archive finale créée : $BACKUP_DIR/$ARCHIVE_NAME"

rm -rf "$WORK_DIR"
log "=== Sauvegarde terminée avec succès ==="

echo "Backup créé : $BACKUP_DIR/$ARCHIVE_NAME"
