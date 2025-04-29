#!/bin/bash

# Paths and variables
BACKUP_DIR="/opt/client_backups"
TMP_DIR="$BACKUP_DIR/tmp"
BACKUP_NAME="Itec-17"
DB_NAME="Itec-17"
ODOO_CONFIG="/etc/odoo.conf"
ODOO_BIN="/opt/venv/odoo17-venv/bin/python3 /opt/odoo/odoo-bin"
PG_USER="postgres"
S3_BUCKET="mcmillan-client-backup"
S3_FOLDER="Itec-17"
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
ZIP_FILE="${BACKUP_NAME}_${TIMESTAMP}.zip"
ZIP_PATH="$BACKUP_DIR/$ZIP_FILE"
RETENTION_DAYS=15

# Create backup folder if it doesn't exist
mkdir -p "$TMP_DIR"

# Dump the database into a SQL file
echo "🗄️ Dumping the database..."
sudo -u "$PG_USER" pg_dump -d "$DB_NAME" > "$TMP_DIR/dump.sql"

# Copy the filestore
echo "📂 Copying the filestore..."
mkdir "$TMP_DIR/filestore"
cp -r "/opt/odoo/.local/share/Odoo/filestore/$DB_NAME"/* "$TMP_DIR/filestore/"

# ==== Step: Get Odoo version_info safely (without importing odoo) ====
echo "🔍 Fetching Odoo version_info..."
ODOO_RELEASE_FILE="/opt/odoo/odoo/release.py"

if [ -f "$ODOO_RELEASE_FILE" ]; then
    # Extract raw version_info
    RAW_VERSION_INFO=$(grep "^version_info" "$ODOO_RELEASE_FILE" | cut -d "=" -f2- | tr -d '()')
    
    # Replace the release level with a proper string ("final" instead of FINAL) and handle the empty string properly
    FORMATTED_VERSION_INFO=$(echo "$RAW_VERSION_INFO" | sed -E 's/\b(ALPHA|BETA|RELEASE_CANDIDATE|FINAL)\b/\"\L\1\"/g' | sed "s/'/\"/g")
    
    # Prepare Odoo version info (removing the empty string part from the version)
    ODOO_VERSION_INFO="[$FORMATTED_VERSION_INFO]"

    # Extract the major and minor version for the short version string
    ODOO_VERSION=$(echo "$FORMATTED_VERSION_INFO" | cut -d ',' -f1-3 | tr -d ' ' | sed 's/,/./g')  # For example, 17.0

    echo "Odoo version_info detected: $ODOO_VERSION_INFO"
    echo "Odoo version detected: $ODOO_VERSION"
else
    echo "❌ Error: Odoo release file not found at $ODOO_RELEASE_FILE"
    exit 1
fi

# ==== Step: Get Dynamic PostgreSQL Version ====
echo "🔍 Fetching PostgreSQL version..."
PG_VERSION=$(psql --version | awk '{print $3}')
echo "PostgreSQL version detected: $PG_VERSION"

# Get installed modules and their versions
echo "📦 Getting installed modules..."
MODULES=$(sudo -u postgres psql  -d "$DB_NAME" -At -c "SELECT name, latest_version FROM ir_module_module WHERE state = 'installed';")

# Generate manifest.json
echo "📝 Creating manifest.json..."
cat > "$TMP_DIR/manifest.json" <<EOL
{
    "odoo_dump": "1",
    "db_name": "$DB_NAME",
    "version": "$ODOO_VERSION",
    "version_info":$ODOO_VERSION_INFO,
    "major_version": "$ODOO_VERSION",
    "pg_version": "$PG_VERSION",
    "modules": {
EOL

# Add modules to the manifest
while IFS='|' read -r module version; do
    echo "        \"$module\": \"$version\"," >> "$TMP_DIR/manifest.json"
done <<< "$MODULES"

# Close the modules section
sed -i '$ s/,$//' "$TMP_DIR/manifest.json"
echo "    }" >> "$TMP_DIR/manifest.json"
echo "}" >> "$TMP_DIR/manifest.json"

# Now, zip the backup
echo "🗜️ Creating zip archive..."
cd "$TMP_DIR" && zip -r "$ZIP_PATH" filestore dump.sql manifest.json

# Clean up temporary files
echo "🧹 Cleaning up..."
rm -rf "$TMP_DIR"

echo "✅ Backup complete: $ZIP_PATH"

# Upload to S3
echo "☁️ Uploading $ZIP_FILE to S3..."
aws s3 cp "$ZIP_PATH" "s3://$S3_BUCKET/$S3_FOLDER/$ZIP_FILE"
if [ $? -eq 0 ]; then
  echo "✅ Uploaded to S3: s3://$S3_BUCKET/$S3_FOLDER/$ZIP_FILE"
else
  echo "❌ Failed to upload to S3"
fi

# Delete old backups from S3
echo "🧹 Checking for old backups to delete..."
aws s3 ls "s3://$S3_BUCKET/$S3_FOLDER/" | while read -r line; do
  create_date=$(echo $line | awk '{print $1" "$2}')
  file_name=$(echo $line | awk '{print $4}')
  if [[ "$file_name" == *.zip ]]; then
    create_date_seconds=$(date -d "$create_date" +%s)
    now_seconds=$(date +%s)
    age_days=$(( (now_seconds - create_date_seconds) / 86400 ))
    if [ $age_days -gt $RETENTION_DAYS ]; then
      echo "🗑️ Deleting old backup: $file_name (age: $age_days days)"
      aws s3 rm "s3://$S3_BUCKET/$S3_FOLDER/$file_name"
    fi
  fi
done

# 🎉 All done! Backup available at S3
echo "🎉 All done! Backup available at: s3://$S3_BUCKET/$S3_FOLDER/$ZIP_FILE"
