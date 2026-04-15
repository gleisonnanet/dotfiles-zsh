#!/usr/bin/env bash
# ============================================================
#  Uninstaller - reverte para o estado anterior
# ============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "\033[0;34m[INFO]\033[0m  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

echo ""
echo -e "${CYAN}ZSH Dotfiles Uninstaller${NC}"
echo ""

# Find latest backup
BACKUP_BASE="$HOME/.dotfiles-backup"
if [ -d "$BACKUP_BASE" ]; then
    LATEST=$(ls -td "$BACKUP_BASE"/*/ 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
        echo -e "${YELLOW}Último backup encontrado: $LATEST${NC}"
        read -rp "Restaurar a partir deste backup? [s/N] " answer
        if [[ "$answer" =~ ^[sS]$ ]]; then
            for f in "$LATEST"*; do
                base=$(basename "$f")
                case "$base" in
                    .zshrc)   cp "$f" "$HOME/.zshrc"   && ok "Restaurado: .zshrc"   ;;
                    .p10k.zsh) cp "$f" "$HOME/.p10k.zsh" && ok "Restaurado: .p10k.zsh" ;;
                esac
            done
            echo ""
            ok "Backup restaurado. Execute 'exec zsh' para aplicar."
        fi
    fi
else
    warn "Nenhum backup encontrado em $BACKUP_BASE"
fi
