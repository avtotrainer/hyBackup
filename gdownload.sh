#!/bin/bash
# ----------------------------------------------------------------------
# gdownload.sh — Download the latest backup archive from Google Drive
# Requires: rclone configured with remote named "gdrive"
# ----------------------------------------------------------------------

REMOTE_PATH="gdrive:Backups/hyBackup"
LOCAL_PATH="$HOME/.backup"

echo "🔍 Checking for latest backup on Google Drive..."
LATEST=$(rclone lsf --sort '-modtime' "$REMOTE_PATH" | grep 'backup-.*\.tar\.gz' | head -n 1)

if [[ -z "$LATEST" ]]; then
  echo "❌ No backups found in $REMOTE_PATH"
  exit 1
fi

mkdir -p "$LOCAL_PATH"

echo "☁️  Downloading: $LATEST"
rclone copy "$REMOTE_PATH/$LATEST" "$LOCAL_PATH" --progress

if [[ $? -eq 0 ]]; then
  echo "✅ Download complete!"
  echo "📦 Saved to: $LOCAL_PATH/$LATEST"
else
  echo "❌ Download failed."
fi

