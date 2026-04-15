# ZSH Dotfiles

Configuração completa de terminal ZSH com visual moderno e funcional.

## O que inclui

- **Oh-My-Zsh** + **Powerlevel10k** (tema rainbow, prompt de 3 linhas)
- **Nerd Fonts**: JetBrainsMono, MesloLGS, CascadiaCode, Inter
- **Ferramentas CLI**: eza (ls), bat (cat), fzf (fuzzy finder)
- **Plugins**: zsh-autosuggestions, zsh-syntax-highlighting
- **Configuração KDE Plasma** (fontes, antialiasing, Konsole)

## Prompt de 3 linhas

```
 fedora  ~/projeto/backend  on  main          at 16:09
       │  5  6  │  drwxr-xr-x
❯
```

- **Linha 1**: Ícone do OS + caminho + branch Git + hora
- **Linha 2**: Ícones por tipo de arquivo │ pastas/arquivos │ permissões
- **Linha 3**: Prompt de input (`❯`)

### Tipos de arquivo detectados

| Ícone | Extensões |
|-------|-----------|
|  | `.py` |
|  | `.js` `.mjs` `.cjs` |
|  | `.ts` `.tsx` |
|  | `.html` `.htm` |
|  | `.css` `.scss` `.sass` |
|  | `.json` |
|  | `.yml` `.yaml` |
|  | `.md` |
|  | `.sh` `.bash` `.zsh` |
|  | `.go` |
|  | `.rs` |
|  | `.java` |
|  | `.c` `.h` |
|  | `.cpp` `.hpp` `.cc` |
|  | `.rb` |
|  | `.php` |
|  | `.vue` |
|  | `.dart` |
|  | `Dockerfile` |
|  | `Makefile` |

## Instalação

```bash
git clone https://github.com/SEU_USUARIO/dotfiles-zsh.git
cd dotfiles-zsh
chmod +x install.sh
./install.sh
```

## Aliases incluídos

| Alias | Comando |
|-------|---------|
| `ls`  | `eza --icons` |
| `ll`  | `eza -lah --icons --git --time-style=long-iso` |
| `lt`  | `eza --tree --level=2 --icons` |
| `cat` | `bat --paging=never --style=plain` |
| `..`  | `cd ..` |
| `reload` | `source ~/.zshrc` |
| `ports`  | `ss -tulnp` |
| `myip`   | `curl -s ifconfig.me` |

## Distros suportadas

- Fedora / RHEL / CentOS / Rocky
- Ubuntu / Debian / Linux Mint / Pop!_OS
- Arch / Manjaro / EndeavourOS
- openSUSE

## Backup e restauração

O instalador cria um backup automático em `~/.dotfiles-backup/`.

Para restaurar:
```bash
./uninstall.sh
```

## Requisitos

- `git`, `curl`, `unzip`
- Acesso sudo (para instalar pacotes)
- Terminal com suporte a Unicode e cores (Konsole, Alacritty, Kitty, WezTerm)
