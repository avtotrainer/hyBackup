#!/bin/bash
# ----------------------------------------------------------------------
# hyBackup Restore Script
# Restores configurations from a backup archive
# ----------------------------------------------------------------------

BACKUP_DIR="$HOME/.backup"

show_menu() {
  echo
  echo "📂 Available backups:"
  select FILE in "$BACKUP_DIR"/backup-*.tar.gz; do
    [[ -n "$FILE" ]] && ARCHIVE="$FILE" && break
  done

  echo
  echo "Select restore option:"
  echo " 1) Configs (.config, .local/share)"
  echo " 2) Zsh setup"
  echo " 3) SSH keys"
  echo " 4) Full restore (except /etc & nvim)"
  echo " 5) GitHub projects (auto-clone)"
  echo " 6) Inspect mode"
  echo " 7) Extract post-install.md only"
  echo " 8) Extract /etc (fstab, NetworkManager)"
  echo " 9) Preview restore (dry-run)"
  echo "10) Clone Neovim config from GitHub"
  read -rp "👉 Choose (1-10): " MODE
}

restore_configs() {
  local include_paths=()
  for path in ".config" ".local/share"; do
    [ -d "$HOME/$path" ] && include_paths+=("$path")
  done

  for p in "${include_paths[@]}"; do
    tar -xzf "$ARCHIVE" -C "$HOME" --wildcards "$p/*"
  done
}

restore_zsh() {
  tar -xzf "$ARCHIVE" -C "$HOME" --wildcards \
    ".zshrc" ".p10k.zsh" ".oh-my-zsh/*"
}

restore_ssh() {
  tar -xzf "$ARCHIVE" -C "$HOME" --wildcards ".ssh/*"
  chmod 700 "$HOME/.ssh" 2>/dev/null
  chmod 600 "$HOME/.ssh"/* 2>/dev/null
}

restore_full() {
  tar -xzf "$ARCHIVE" -C "$HOME" \
    --exclude='./etc' \
    --exclude='.config/nvim'
}

restore_github_projects() {
  PROJECTS_DIR="$HOME/Projects"
  mkdir -p "$PROJECTS_DIR"
  echo "📦 Restoring GitHub projects..."
  grep -Eo 'git@github.com:[^ ]+\.git' "$HOME/Documents/post-install.md" | while read -r repo; do
    name=$(basename "$repo" .git)
    if [ -d "$PROJECTS_DIR/$name" ]; then
      echo "🔄 Updating $name..."
      (cd "$PROJECTS_DIR/$name" && git pull)
    else
      echo "⬇️  Cloning $name..."
      git clone "$repo" "$PROJECTS_DIR/$name"
    fi
  done
}

clone_nvim() {
  NVIM_DIR="$HOME/.config/nvim"
  REPO="${NVIM_CONFIG_REPO:-git@github.com:avtotrainer/nvchad-2.5-config.git}"
  if [ -d "$NVIM_DIR/.git" ]; then
    echo "🔄 Updating existing Neovim config..."
    (cd "$NVIM_DIR" && git pull)
  else
    echo "⬇️  Cloning Neovim config..."
    git clone "$REPO" "$NVIM_DIR"
  fi
}

# ----------------------------------------------------------------------
# Main logic
# ----------------------------------------------------------------------
ARCHIVE="$1"
MODE="$2"

if [ -z "$ARCHIVE" ]; then
  show_menu
elif [ -z "$MODE" ]; then
  echo "📦 Using archive: $ARCHIVE"
  read -rp "👉 Choose restore mode (1-10): " MODE
fi

case "$MODE" in
  1) restore_configs ;;
  2) restore_zsh ;;
  3) restore_ssh ;;
  4) restore_full ;;
  5) restore_github_projects ;;
  6) tar -tzf "$ARCHIVE" ;;
  7) tar -xzf "$ARCHIVE" -C "$HOME" --wildcards "post-install.md" ;;
  8) tar -xzf "$ARCHIVE" -C "$HOME" --wildcards "etc/*" ;;
  9) tar -tzf "$ARCHIVE" | less ;;
  10) clone_nvim ;;
  *) echo "❌ Invalid option"; exit 1 ;;
esac

echo "✅ Restore complete."
