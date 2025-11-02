#!/bin/bash
# ----------------------------------------------------------------------
# hyBackup — Lightweight configuration backup system
# Focuses only on manually customized configs
# ----------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIST_FILE="${1:-$SCRIPT_DIR/.backup.list}"
BACKUP_DIR="$HOME/.backup"
SESSION_DIR="$BACKUP_DIR/session-$(date '+%Y-%m-%d_%H-%M-%S')"
ARCHIVE_NAME="backup-$(date '+%Y-%m-%d_%H-%M-%S').tar.gz"
MAX_BACKUPS=5

mkdir -p "$SESSION_DIR"
mkdir -p "$BACKUP_DIR"

echo "📦 Creating backup..."
echo "📂 Using list: $LIST_FILE"

# ----------------------------------------------------------------------
# Read and copy each item from .backup.list
# ----------------------------------------------------------------------
while IFS= read -r ITEM; do
  [[ -z "$ITEM" || "$ITEM" =~ ^# ]] && continue
  SRC="$HOME/$ITEM"
  DEST="$SESSION_DIR/$ITEM"

  if [ -e "$SRC" ]; then
    echo "➡️  Adding: $ITEM"
    mkdir -p "$(dirname "$DEST")"
    rsync -a --delete "$SRC" "$DEST" 2>/dev/null
  else
    echo "⚠️  Skipping missing: $ITEM"
  fi
done < "$LIST_FILE"

# ----------------------------------------------------------------------
# Generate system info
# ----------------------------------------------------------------------
echo "📄 Generating system info..."
{
  echo "# System Info ($(date))"
  uname -a
  echo
  echo "## Explicitly Installed Packages"
  pacman -Qent | awk '{print "- " $1}'
} > "$SESSION_DIR/system-info.txt"

# ----------------------------------------------------------------------
# Create compressed archive
# ----------------------------------------------------------------------
cd "$SESSION_DIR" || exit
tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" . >/dev/null
echo "✅ Archive created: $BACKUP_DIR/$ARCHIVE_NAME"

# ----------------------------------------------------------------------
# Keep only last N backups
# ----------------------------------------------------------------------
COUNT=$(ls -1t "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null | wc -l)
if [ "$COUNT" -gt "$MAX_BACKUPS" ]; then
  REMOVE=$((COUNT - MAX_BACKUPS))
  echo "🧹 Removing oldest $REMOVE backups..."
  ls -1t "$BACKUP_DIR"/backup-*.tar.gz | tail -n "$REMOVE" | xargs rm -f
fi

# ----------------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------------
rm -rf "$SESSION_DIR"
echo "🧽 Temporary files cleaned."
echo "✅ Done."
