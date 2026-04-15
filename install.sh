#!/usr/bin/env bash
# ============================================================
#  ZSH Dotfiles Installer
#  Configures a complete ZSH environment with:
#    - Oh-My-Zsh + Powerlevel10k (rainbow, 3-line prompt)
#    - eza, bat, fzf, zsh-syntax-highlighting, zsh-autosuggestions
#    - Nerd Fonts (JetBrainsMono, MesloLGS, CascadiaCode)
#    - KDE Plasma font/rendering config (optional)
#    - Custom prompt with file-type icons, git, permissions
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"
FONTS_DIR="$HOME/.local/share/fonts"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "\n${CYAN}━━━ $* ━━━${NC}"; }

# ============================================================
# Detect distro and package manager
# ============================================================
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    elif command -v lsb_release &>/dev/null; then
        DISTRO="$(lsb_release -si | tr '[:upper:]' '[:lower:]')"
    else
        DISTRO="unknown"
    fi

    case "$DISTRO" in
        fedora|rhel|centos|rocky|alma)
            PKG_MANAGER="dnf"
            PKG_INSTALL="sudo dnf install -y"
            PKG_UPDATE="sudo dnf check-update || true"
            ;;
        ubuntu|debian|linuxmint|pop)
            PKG_MANAGER="apt"
            PKG_INSTALL="sudo apt install -y"
            PKG_UPDATE="sudo apt update"
            ;;
        arch|manjaro|endeavouros)
            PKG_MANAGER="pacman"
            PKG_INSTALL="sudo pacman -S --noconfirm"
            PKG_UPDATE="sudo pacman -Sy"
            ;;
        opensuse*|sles)
            PKG_MANAGER="zypper"
            PKG_INSTALL="sudo zypper install -y"
            PKG_UPDATE="sudo zypper refresh"
            ;;
        *)
            error "Distro '$DISTRO' não suportada automaticamente."
            error "Instale manualmente: zsh eza bat fzf zsh-syntax-highlighting"
            exit 1
            ;;
    esac

    info "Distro detectada: $DISTRO (gerenciador: $PKG_MANAGER)"
}

# ============================================================
# Backup existing configs
# ============================================================
backup_existing() {
    step "Backup dos arquivos existentes"
    mkdir -p "$BACKUP_DIR"

    local files=("$HOME/.zshrc" "$HOME/.p10k.zsh")
    for f in "${files[@]}"; do
        if [ -f "$f" ]; then
            cp "$f" "$BACKUP_DIR/"
            ok "Backup: $f → $BACKUP_DIR/"
        fi
    done

    if [ -d "$HOME/.oh-my-zsh" ]; then
        info "Oh-My-Zsh existente será preservado"
    fi
}

# ============================================================
# Install packages
# ============================================================
install_pkg() {
    local name="$1"
    shift
    if $PKG_INSTALL "$@"; then
        ok "$name instalado"
    else
        warn "$name: falha na instalação (continuando...)"
        return 1
    fi
}

install_packages() {
    step "Instalando pacotes do sistema"
    $PKG_UPDATE || true

    # No Ubuntu/Debian Docker, ativar universe para ter eza e outros
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        sudo apt install -y software-properties-common 2>/dev/null || true
        sudo add-apt-repository -y universe 2>/dev/null || true
        sudo apt update 2>/dev/null || true
    fi

    # zsh (crítico - não pode falhar)
    if ! command -v zsh &>/dev/null; then
        install_pkg "ZSH" zsh || { error "ZSH é obrigatório e não foi possível instalar!"; exit 1; }
    else
        ok "ZSH já instalado"
    fi

    # eza
    if ! command -v eza &>/dev/null; then
        if ! install_pkg "eza" eza; then
            # Fallback: instalar via cargo ou binário
            if command -v cargo &>/dev/null; then
                info "Tentando eza via cargo..."
                cargo install eza 2>/dev/null && ok "eza instalado (cargo)" || warn "eza indisponível"
            else
                warn "eza indisponível nos repositórios. Instale manualmente: https://eza.rocks/"
            fi
        fi
    else
        ok "eza já instalado"
    fi

    # bat
    if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            install_pkg "bat" bat || true
            # Debian/Ubuntu instala como batcat
            if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
                sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat 2>/dev/null || true
                ok "Link batcat → bat criado"
            fi
        else
            install_pkg "bat" bat || true
        fi
    else
        ok "bat já instalado"
    fi

    # fzf
    if ! command -v fzf &>/dev/null; then
        install_pkg "fzf" fzf || true
    else
        ok "fzf já instalado"
    fi

    # zsh-syntax-highlighting
    local zsh_hl_installed=false
    [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && zsh_hl_installed=true
    [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && zsh_hl_installed=true

    if ! $zsh_hl_installed; then
        install_pkg "zsh-syntax-highlighting" zsh-syntax-highlighting || true
    else
        ok "zsh-syntax-highlighting já instalado"
    fi
}

# ============================================================
# Install Oh-My-Zsh
# ============================================================
install_ohmyzsh() {
    step "Instalando Oh-My-Zsh"
    if [ -d "$HOME/.oh-my-zsh" ]; then
        ok "Oh-My-Zsh já instalado"
    else
        info "Baixando Oh-My-Zsh..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        ok "Oh-My-Zsh instalado"
    fi
}

# ============================================================
# Install Powerlevel10k
# ============================================================
install_p10k() {
    step "Instalando Powerlevel10k"
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ -d "$p10k_dir" ]; then
        info "Atualizando Powerlevel10k..."
        git -C "$p10k_dir" pull --quiet 2>/dev/null || true
        ok "Powerlevel10k atualizado"
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        ok "Powerlevel10k instalado"
    fi
}

# ============================================================
# Install zsh-autosuggestions
# ============================================================
install_autosuggestions() {
    step "Instalando zsh-autosuggestions"
    local dir="$HOME/.zsh/plugins/zsh-autosuggestions"
    if [ -d "$dir" ]; then
        git -C "$dir" pull --quiet 2>/dev/null || true
        ok "zsh-autosuggestions atualizado"
    else
        mkdir -p "$HOME/.zsh/plugins"
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$dir"
        ok "zsh-autosuggestions instalado"
    fi
}

# ============================================================
# Install Nerd Fonts
# ============================================================
install_fonts() {
    step "Instalando Nerd Fonts"
    mkdir -p "$FONTS_DIR"

    local -A font_urls=(
        ["JetBrainsMono"]="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        ["MesloLGS"]="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.tar.xz"
        ["CascadiaCode"]="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.tar.xz"
    )

    for font_name in "${!font_urls[@]}"; do
        local font_dir="$FONTS_DIR/$font_name"
        if [ -d "$font_dir" ] && [ "$(ls -A "$font_dir" 2>/dev/null)" ]; then
            ok "$font_name já instalada"
        else
            info "Baixando $font_name..."
            mkdir -p "$font_dir"
            local tmp_file
            tmp_file=$(mktemp /tmp/font-XXXXXX.tar.xz)
            if curl -fsSL "${font_urls[$font_name]}" -o "$tmp_file"; then
                tar -xf "$tmp_file" -C "$font_dir"
                rm -f "$tmp_file"
                ok "$font_name instalada"
            else
                warn "Falha ao baixar $font_name (verifique conexão)"
                rm -f "$tmp_file"
            fi
        fi
    done

    # Inter (UI font for KDE)
    local inter_dir="$FONTS_DIR/Inter"
    if [ -d "$inter_dir" ] && [ "$(ls -A "$inter_dir" 2>/dev/null)" ]; then
        ok "Inter já instalada"
    else
        info "Baixando Inter (fonte UI)..."
        mkdir -p "$inter_dir"
        local tmp_file
        tmp_file=$(mktemp /tmp/font-XXXXXX.zip)
        if curl -fsSL "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip" -o "$tmp_file"; then
            unzip -qo "$tmp_file" "Inter.ttc" -d "$inter_dir" 2>/dev/null || \
            unzip -qo "$tmp_file" "*.ttf" -d "$inter_dir" 2>/dev/null || \
            unzip -qo "$tmp_file" -d "$inter_dir"
            rm -f "$tmp_file"
            ok "Inter instalada"
        else
            warn "Falha ao baixar Inter"
            rm -f "$tmp_file"
        fi
    fi

    info "Atualizando cache de fontes..."
    fc-cache -f "$FONTS_DIR" 2>/dev/null
    ok "Cache de fontes atualizado"
}

# ============================================================
# Install dotfiles
# ============================================================
install_dotfiles() {
    step "Instalando configurações"

    # .zshrc
    if [ -f "$CONFIGS_DIR/zshrc" ]; then
        cp "$CONFIGS_DIR/zshrc" "$HOME/.zshrc"
        ok ".zshrc instalado"
    else
        error "Arquivo configs/zshrc não encontrado!"
    fi

    # .p10k.zsh
    if [ -f "$CONFIGS_DIR/p10k.zsh" ]; then
        cp "$CONFIGS_DIR/p10k.zsh" "$HOME/.p10k.zsh"
        ok ".p10k.zsh instalado"
    else
        error "Arquivo configs/p10k.zsh não encontrado!"
    fi

    # Fix zsh-syntax-highlighting path for different distros
    fix_syntax_highlighting_path
}

# ============================================================
# Fix paths that may differ between distros
# ============================================================
fix_syntax_highlighting_path() {
    local zshrc="$HOME/.zshrc"
    local found=false

    # Check common locations
    local paths=(
        "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    )

    for p in "${paths[@]}"; do
        if [ -f "$p" ]; then
            sed -i "s|source .*/zsh-syntax-highlighting.zsh|source $p|" "$zshrc"
            ok "Path zsh-syntax-highlighting ajustado: $p"
            found=true
            break
        fi
    done

    if ! $found; then
        warn "zsh-syntax-highlighting não encontrado - a linha será comentada no .zshrc"
        sed -i 's|^source .*/zsh-syntax-highlighting.zsh|# &|' "$zshrc"
    fi

    # Fix FZF keybindings path
    local fzf_paths=(
        "/usr/share/fzf/shell/key-bindings.zsh"
        "/usr/share/doc/fzf/examples/key-bindings.zsh"
        "/usr/share/fzf/key-bindings.zsh"
        "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
    )

    for p in "${fzf_paths[@]}"; do
        if [ -f "$p" ]; then
            sed -i "s|/usr/share/fzf/shell/key-bindings.zsh|$p|" "$zshrc"
            ok "Path FZF keybindings ajustado: $p"
            break
        fi
    done
}

# ============================================================
# Configure KDE Plasma (optional)
# ============================================================
configure_kde() {
    # Only run if KDE is detected
    if ! command -v kwriteconfig6 &>/dev/null && ! command -v kwriteconfig5 &>/dev/null; then
        info "KDE não detectado - pulando configuração do desktop"
        return
    fi

    step "Configurando KDE Plasma"

    local kwrite="kwriteconfig6"
    command -v kwriteconfig6 &>/dev/null || kwrite="kwriteconfig5"

    # Font rendering
    $kwrite --file kdeglobals --group General --key XftAntialias true
    $kwrite --file kdeglobals --group General --key XftHintStyle hintslight
    $kwrite --file kdeglobals --group General --key XftSubPixel rgb
    ok "Renderização de fontes configurada (antialiasing + hinting)"

    # System fonts
    $kwrite --file kdeglobals --group General --key font "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    $kwrite --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    ok "Fontes do sistema configuradas (Inter + JetBrainsMono NF)"

    # Konsole profile
    local konsole_dir="$HOME/.local/share/konsole"
    mkdir -p "$konsole_dir"
    if [ -f "$CONFIGS_DIR/konsole.profile" ]; then
        cp "$CONFIGS_DIR/konsole.profile" "$konsole_dir/zsh.profile"
        ok "Perfil Konsole instalado"
    else
        # Create a minimal one
        cat > "$konsole_dir/zsh.profile" <<'KONSOLE'
[Appearance]
ColorScheme=Breeze
Font=JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[General]
Command=/bin/zsh
Name=zsh
Parent=FALLBACK/
KONSOLE
        ok "Perfil Konsole criado"
    fi
}

# ============================================================
# Set ZSH as default shell
# ============================================================
set_default_shell() {
    step "Configurando shell padrão"
    local current_shell
    current_shell=$(getent passwd "$(whoami)" | cut -d: -f7)
    local zsh_path
    zsh_path=$(command -v zsh)

    if [[ "$current_shell" == *"zsh"* ]]; then
        ok "ZSH já é o shell padrão"
    else
        info "Alterando shell padrão para ZSH..."
        chsh -s "$zsh_path" 2>/dev/null || {
            warn "Falha ao alterar shell. Execute manualmente: chsh -s $zsh_path"
        }
        ok "Shell padrão alterado para $zsh_path"
    fi
}

# ============================================================
# Summary
# ============================================================
show_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}Instalação concluída!${NC}                               ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}Pacotes:${NC} zsh, eza, bat, fzf                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}Plugins:${NC} syntax-highlighting, autosuggestions        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}Tema:${NC}    Powerlevel10k (rainbow, 3 linhas)           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}Fontes:${NC}  JetBrainsMono NF, MesloLGS NF, Inter       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Backup salvo em:${NC}                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  $BACKUP_DIR    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Para aplicar, abra um novo terminal ou execute:${NC}     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}exec zsh${NC}                                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}No KDE: configure a fonte do Konsole para:${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}JetBrainsMono Nerd Font 11pt${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================================
# Main
# ============================================================
main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}ZSH Dotfiles Installer${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Powerlevel10k + Nerd Fonts + Tools                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""

    detect_distro
    backup_existing
    install_packages
    install_ohmyzsh
    install_p10k
    install_autosuggestions
    install_fonts
    install_dotfiles
    configure_kde
    set_default_shell
    show_summary
}

main "$@"
