#!/bin/bash

# DevShell Setup - Configurador Avançado para Ambiente de Desenvolvimento
# Criado para amantes do terminal no Debian/Ubuntu

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Variáveis globais
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.devshell-setup.log"
CONFIG_DIR="$HOME/.config/devshell"

# Função para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Banner criativo
show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
    ██████╗ ███████╗██╗   ██╗███████╗██╗  ██╗███████╗██╗     ██╗     
    ██╔══██╗██╔════╝██║   ██║██╔════╝██║  ██║██╔════╝██║     ██║     
    ██║  ██║█████╗  ██║   ██║███████╗███████║█████╗  ██║     ██║     
    ██║  ██║██╔══╝  ╚██╗ ██╔╝╚════██║██╔══██║██╔══╝  ██║     ██║     
    ██████╔╝███████╗ ╚████╔╝ ███████║██║  ██║███████╗███████╗███████╗
    ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}    🚀 Configurador Avançado para Ambiente de Desenvolvimento${NC}"
    echo -e "${YELLOW}    📦 Focado em usuários que amam o terminal${NC}"
    echo -e "${GREEN}    🎯 Otimizado para Debian/Ubuntu${NC}"
    echo ""
}

# Função para mostrar progresso
show_progress() {
    local current=$1
    local total=$2
    local step_name=$3
    local percentage=$((current * 100 / total))
    
    echo -ne "${BLUE}[${current}/${total}] ${WHITE}${step_name}${NC} "
    printf "["
    for ((i=0; i<50; i++)); do
        if [ $i -lt $((percentage/2)) ]; then
            printf "█"
        else
            printf "░"
        fi
    done
    printf "] ${percentage}%%\r"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# Verificar se está rodando no Debian/Ubuntu
check_system() {
    if [[ ! -f /etc/debian_version ]]; then
        echo -e "${RED}❌ Este script é otimizado para sistemas Debian/Ubuntu${NC}"
        exit 1
    fi
    
    # Verificar se é root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}❌ Não execute este script como root!${NC}"
        exit 1
    fi
}

# Criar diretórios necessários
setup_directories() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/Dev"
    mkdir -p "$HOME/Scripts"
}

# Atualizar sistema
update_system() {
    echo -e "\n${YELLOW}📦 Atualizando sistema...${NC}"
    sudo apt update && sudo apt upgrade -y
    log "Sistema atualizado"
}

# Instalar dependências essenciais
install_essentials() {
    echo -e "\n${YELLOW}🔧 Instalando ferramentas essenciais...${NC}"
    
    local essentials=(
        "curl" "wget" "git" "vim" "neovim" "tmux" "htop" "btop" "tree" "jq" "yq"
        "fd-find" "ripgrep" "bat" "exa" "zoxide" "fzf" "build-essential"
        "software-properties-common" "apt-transport-https" "ca-certificates"
        "gnupg" "lsb-release" "unzip" "zip" "p7zip-full" "rsync" "ncdu"
        "tldr" "thefuck" "silversearcher-ag" "mc" "ranger" "python3-pip"
        "nodejs" "npm" "golang-go" "default-jdk" "ruby" "lua5.3"
    )
    
    for package in "${essentials[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            sudo apt install -y "$package" 2>/dev/null || echo -e "${RED}❌ Falha ao instalar $package${NC}"
        fi
    done
    
    log "Ferramentas essenciais instaladas"
}

# Configurar ZSH e Oh My Zsh
setup_zsh() {
    echo -e "\n${YELLOW}🐚 Configurando ZSH...${NC}"
    
    # Instalar ZSH
    sudo apt install -y zsh
    
    # Instalar Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    
    # Instalar plugins
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    
    # zsh-completions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
        git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
    fi
    
    # Instalar Powerlevel10k
    if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k "$ZSH_CUSTOM/themes/powerlevel10k"
    fi
    
    log "ZSH configurado com Oh My Zsh"
}

# Criar configuração personalizada do ZSH
create_zshrc() {
    echo -e "\n${YELLOW}⚙️  Criando configuração personalizada do ZSH...${NC}"
    
    cat > "$HOME/.zshrc" << 'EOF'
# DevShell ZSH Configuration
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    docker
    docker-compose
    kubectl
    terraform
    aws
    gcp
    azure
    python
    pip
    node
    npm
    yarn
    rust
    golang
    ruby
    rails
    laravel
    symfony
    django
    flask
    react
    vue
    angular
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    colored-man-pages
    command-not-found
    extract
    z
    web-search
    history-substring-search
    jsontools
    urltools
    encode64
)

source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8
export EDITOR='nvim'
export ARCHFLAGS="-arch x86_64"

# Custom PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Aliases
alias ll='exa -la --icons'
alias la='exa -la --icons'
alias ls='exa --icons'
alias lt='exa --tree --icons'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias top='btop'
alias du='ncdu'
alias ps='procs'
alias vim='nvim'
alias vi='nvim'
alias code='code .'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias h='history'
alias c='clear'
alias ports='netstat -tulanp'
alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias search='apt search'
alias myip='curl ifconfig.me'
alias weather='curl wttr.in'
alias news='curl getnews.tech'

# Git aliases
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline'
alias gp='git push'
alias gpl='git pull'
alias gs='git status'
alias gst='git stash'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs'
alias dstop='docker stop'
alias drm='docker rm'
alias drmi='docker rmi'
alias dprune='docker system prune -af'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs'
alias kex='kubectl exec -it'

# Functions
mkcd() { mkdir -p "$1" && cd "$1"; }
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Load zoxide
eval "$(zoxide init zsh)"

# Load thefuck
eval $(thefuck --alias)

# Completion for zsh-completions
autoload -U compinit && compinit

# History settings
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS

# Load Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load local config if exists
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
EOF
    
    log "Configuração personalizada do ZSH criada"
}

# Instalar ferramentas modernas via snap/cargo/npm
install_modern_tools() {
    echo -e "\n${YELLOW}🚀 Instalando ferramentas modernas...${NC}"
    
    # Instalar Rust
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # Instalar ferramentas Rust
    cargo install bat exa ripgrep fd-find procs zoxide du-dust tokei git-delta bottom
    
    # Instalar Node.js tools globalmente
    npm config set prefix "$HOME/.npm-global"
    npm install -g yarn pnpm tldr http-server live-server nodemon pm2 typescript ts-node
    
    # Instalar Deno
    if ! command -v deno &> /dev/null; then
        curl -fsSL https://deno.land/x/install/install.sh | sh
    fi
    
    # Instalar Bun
    if ! command -v bun &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash
    fi
    
    log "Ferramentas modernas instaladas"
}

# Configurar Docker
setup_docker() {
    echo -e "\n${YELLOW}🐳 Configurando Docker...${NC}"
    
    # Remover versões antigas
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Instalar Docker
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Adicionar usuário ao grupo docker
    sudo usermod -aG docker $USER
    
    # Instalar Docker Compose standalone
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    log "Docker configurado"
}

# Configurar Neovim
setup_neovim() {
    echo -e "\n${YELLOW}✏️  Configurando Neovim...${NC}"
    
    # Instalar Neovim via AppImage (versão mais recente)
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim
    
    # Instalar vim-plug
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
           https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    
    # Criar configuração básica
    mkdir -p "$HOME/.config/nvim"
    cat > "$HOME/.config/nvim/init.vim" << 'EOF'
" DevShell Neovim Configuration
call plug#begin()
    Plug 'preservim/nerdtree'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'tpope/vim-fugitive'
    Plug 'airblade/vim-gitgutter'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'preservim/nerdcommenter'
    Plug 'jiangmiao/auto-pairs'
    Plug 'morhetz/gruvbox'
call plug#end()

" General settings
set number
set relativenumber
set autoindent
set tabstop=4
set shiftwidth=4
set smarttab
set softtabstop=4
set mouse=a
set clipboard=unnamedplus
set encoding=UTF-8

" Theme
colorscheme gruvbox
set background=dark

" Key mappings
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-p> :FZF<CR>
EOF
    
    log "Neovim configurado"
}

# Configurar tmux
setup_tmux() {
    echo -e "\n${YELLOW}🖥️  Configurando Tmux...${NC}"
    
    # Instalar TPM (Tmux Plugin Manager)
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    
    # Criar configuração do tmux
    cat > "$HOME/.tmux.conf" << 'EOF'
# DevShell Tmux Configuration

# Change prefix key
set -g prefix C-a
unbind C-b
bind-key C-a send-prefix

# Improve colors
set -g default-terminal "screen-256color"

# Set scrollback buffer to 10000
set -g history-limit 10000

# Customize the status line
set -g status-fg green
set -g status-bg black

# Enable mouse mode
set -g mouse on

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Reload config file
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
EOF
    
    log "Tmux configurado"
}

# Criar aliases e funções úteis
create_useful_scripts() {
    echo -e "\n${YELLOW}📜 Criando scripts úteis...${NC}"
    
    # Script para limpar sistema
    cat > "$HOME/.local/bin/system-cleanup" << 'EOF'
#!/bin/bash
echo "🧹 Limpando sistema..."
sudo apt autoremove -y
sudo apt autoclean
docker system prune -f
snap refresh
echo "✅ Sistema limpo!"
EOF
    
    # Script para backup de dotfiles
    cat > "$HOME/.local/bin/backup-dotfiles" << 'EOF'
#!/bin/bash
BACKUP_DIR="$HOME/Backups/dotfiles-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"
cp -r ~/.config "$BACKUP_DIR/"
cp ~/.zshrc ~/.tmux.conf ~/.gitconfig "$BACKUP_DIR/" 2>/dev/null
echo "✅ Dotfiles backed up to $BACKUP_DIR"
EOF
    
    # Script para verificar portas abertas
    cat > "$HOME/.local/bin/check-ports" << 'EOF'
#!/bin/bash
echo "🔍 Verificando portas abertas..."
netstat -tuln | grep LISTEN
EOF
    
    # Script para monitorar sistema
    cat > "$HOME/.local/bin/sysinfo" << 'EOF'
#!/bin/bash
echo "💻 Informações do Sistema"
echo "========================="
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "CPU: $(lscpu | grep 'Model name' | cut -f 2 -d ':' | awk '{print $1}')"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 " used)"}')"
EOF
    
    chmod +x "$HOME/.local/bin/"*
    log "Scripts úteis criados"
}

# Menu interativo
show_menu() {
    while true; do
        clear
        show_banner
        echo -e "${WHITE}Selecione os componentes para instalar:${NC}\n"
        
        echo -e "${GREEN}1.${NC} Atualizar Sistema"
        echo -e "${GREEN}2.${NC} Instalar Ferramentas Essenciais"
        echo -e "${GREEN}3.${NC} Configurar ZSH + Oh My Zsh"
        echo -e "${GREEN}4.${NC} Instalar Ferramentas Modernas"
        echo -e "${GREEN}5.${NC} Configurar Docker"
        echo -e "${GREEN}6.${NC} Configurar Neovim"
        echo -e "${GREEN}7.${NC} Configurar Tmux"
        echo -e "${GREEN}8.${NC} Criar Scripts Úteis"
        echo -e "${GREEN}9.${NC} 🚀 Instalação Completa (Tudo)"
        echo -e "${RED}0.${NC} Sair"
        
        echo -ne "\n${CYAN}Escolha uma opção [0-9]: ${NC}"
        read -r choice
        
        case $choice in
            1) update_system ;;
            2) install_essentials ;;
            3) setup_zsh && create_zshrc ;;
            4) install_modern_tools ;;
            5) setup_docker ;;
            6) setup_neovim ;;
            7) setup_tmux ;;
            8) create_useful_scripts ;;
            9) full_installation ;;
            0) echo -e "\n${GREEN}👋 Até mais!${NC}" && exit 0 ;;
            *) echo -e "\n${RED}❌ Opção inválida!${NC}" && sleep 2 ;;
        esac
        
        echo -ne "\n${YELLOW}Pressione Enter para continuar...${NC}"
        read
    done
}

# Instalação completa
full_installation() {
    echo -e "\n${PURPLE}🚀 Iniciando instalação completa...${NC}"
    
    local steps=(
        "update_system"
        "install_essentials"
        "setup_zsh"
        "create_zshrc"
        "install_modern_tools"
        "setup_docker"
        "setup_neovim"
        "setup_tmux"
        "create_useful_scripts"
    )
    
    local total_steps=${#steps[@]}
    local current_step=0
    
    for step in "${steps[@]}"; do
        ((current_step++))
        show_progress $current_step $total_steps "Executando $step"
        $step
        sleep 1
    done
    
    echo -e "\n${GREEN}✅ Instalação completa finalizada!${NC}"
    echo -e "${YELLOW}📝 Log salvo em: $LOG_FILE${NC}"
    echo -e "${CYAN}🔄 Reinicie o terminal ou execute 'exec zsh' para aplicar as mudanças${NC}"
}

# Função principal
main() {
    # Verificações iniciais
    check_system
    setup_directories
    
    # Iniciar log
    echo "=== DevShell Setup - $(date) ===" > "$LOG_FILE"
    log "Iniciando configuração"
    
    # Verificar se foi passado argumento para instalação completa
    if [[ "$1" == "--full" || "$1" == "-f" ]]; then
        show_banner
        sleep 2
        full_installation
    else
        show_menu
    fi
}

# Executar função principal com todos os argumentos
main "$@"
