#!/bin/bash

# ==== CONFIG ====
DB_NAME="gil_db"
ODOO_VERSION="14.0"
PG_USER="postgres"
OUTPUT_DIR="/opt/odoo_backups"
FILESTORE_PATH="/opt/odoo/.local/share/Odoo/filestore/$DB_NAME"

# ==== SETUP ====
TIMESTAMP=$(date -Iseconds)
BACKUP_NAME="${DB_NAME}_backup_$(date +%Y%m%d_%H%M%S)"
TMP_DIR="$OUTPUT_DIR/tmp/${BACKUP_NAME}"
ZIP_FILE="${BACKUP_NAME}.zip"
ZIP_PATH="$OUTPUT_DIR/$ZIP_FILE"

# ==== Create necessary directories ====
sudo mkdir -p "$TMP_DIR"
sudo mkdir -p "$OUTPUT_DIR"

# ==== Step 1: Dump PostgreSQL database ====
sudo -u "$PG_USER" pg_dump -d "$DB_NAME" > "$TMP_DIR/dump.sql"
if [ $? -ne 0 ]; then
  echo "❌ Database dump failed"
  exit 1
fi

# ==== Step 2: Copy filestore ====
if [ -d "$FILESTORE_PATH" ]; then
  cp -r "$FILESTORE_PATH" "$TMP_DIR/filestore"
  HAS_FILESTORE=true
else
  HAS_FILESTORE=false
fi

# ==== Step 3: Create manifest.json ====
cat <<EOF > "$TMP_DIR/manifest.json"
{
  "backup_format": "zip",
  "database_name": "$DB_NAME",
  "odoo_version": "$ODOO_VERSION",
  "backup_date": "$TIMESTAMP",
  "has_filestore": $HAS_FILESTORE
}
EOF

# ==== Step 4: Create zip file ====
cd "$TMP_DIR"
zip -r "$ZIP_PATH" ./*
cd -

# ==== Step 5: Cleanup ====
rm -rf "$TMP_DIR"

# ==== Done ====
echo "✅ Backup created at: $ZIP_PATH"
echo "📥 To download it to your local machine, use the following command:"
echo "scp root@<your_server_ip>:$ZIP_PATH ./"

