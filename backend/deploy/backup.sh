#!/usr/bin/env bash
# Daily MongoDB backup for the DODOMED database. Keeps the last 14 days,
# deletes anything older. Not scheduled automatically — add it to cron
# yourself (see below).
#
# Install:
#   sudo cp backend/deploy/backup.sh /opt/dodomed/backup.sh
#   sudo chmod +x /opt/dodomed/backup.sh
#   # as the user that should own the backups:
#   crontab -e
#   # then add:
#   0 3 * * * /opt/dodomed/backup.sh >> /var/log/dodomed-backup.log 2>&1
set -euo pipefail

MONGODB_URI="${MONGODB_URI:-mongodb://127.0.0.1:27017/dodomed}"
BACKUP_DIR="${BACKUP_DIR:-/opt/dodomed/backups}"
KEEP_DAYS="${KEEP_DAYS:-14}"
STAMP="$(date +%Y-%m-%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"
mongodump --uri="$MONGODB_URI" --gzip --archive="$BACKUP_DIR/dodomed_$STAMP.gz"

find "$BACKUP_DIR" -name 'dodomed_*.gz' -mtime "+$KEEP_DAYS" -delete

echo "[backup] wrote $BACKUP_DIR/dodomed_$STAMP.gz"
