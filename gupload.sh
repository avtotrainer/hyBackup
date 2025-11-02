#!/bin/bash
# ----------------------------------------------------------------------
# gupload.sh — Upload the latest backup archive to Google Drive
# Requires: rclone configured with remote named "gdrive"
# ----------------------------------------------------------------------

BACKUP_DIR="$HOME/.backup"
REMOTE_PATH="gdrive:Backups/hyBackup"
LATEST_BACKUP=$(ls -1t "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null | head -n 1)

if [[ -z "$LATEST_BACKUP" ]]; then
  echo "❌ No backup archives found in $BACKUP_DIR"
  exit 1
fi

echo "☁️  Uploading latest backup to Google Drive..."
echo "📦 Local file: $LATEST_BACKUP"
echo "➡️  Remote path: $REMOTE_PATH"

rclone copy "$LATEST_BACKUP" "$REMOTE_PATH" --progress

if [[ $? -eq 0 ]]; then
  echo "✅ Upload complete!"
else
  echo "❌ Upload failed."
fi

