#!/bin/bash

set -euo pipefail

TFTP_DIR="/var/lib/tftpboot"
TFTP_USER="tftp"
TFTP_GROUP="tftp"
CONFIG_FILE="/etc/default/tftpd-hpa"
LOG_FILE="/var/log/tftp-setup.log"

# =========================
# CORES
# =========================
VERDE="\e[32m"
VERMELHO="\e[31m"
AMARELO="\e[33m"
AZUL="\e[34m"
RESET="\e[0m"

log() {
    echo -e "${AZUL}[INFO]${RESET} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

erro() {
    echo -e "${VERMELHO}[ERRO]${RESET} $1"
    echo "[ERRO] $1" >> "$LOG_FILE"
    exit 1
}

sucesso() {
    echo -e "${VERDE}[OK]${RESET} $1"
    echo "[OK] $1" >> "$LOG_FILE"
}

instalar_tftp() {
    log "Atualizando pacotes..."
    sudo apt update -y >> "$LOG_FILE" 2>&1

    log "Instalando servidor TFTP..."
    sudo apt install -y tftpd-hpa >> "$LOG_FILE" 2>&1

    log "Criando diretório $TFTP_DIR..."
    sudo mkdir -p "$TFTP_DIR"
    sudo chown -R $TFTP_USER:$TFTP_GROUP "$TFTP_DIR"
    sudo chmod -R 0777 "$TFTP_DIR"

    log "Configurando $CONFIG_FILE..."
    sudo bash -c "cat > $CONFIG_FILE <<EOF
TFTP_USERNAME=\"$TFTP_USER\"
TFTP_DIRECTORY=\"$TFTP_DIR\"
TFTP_ADDRESS=\"0.0.0.0:69\"
TFTP_OPTIONS=\"--secure --create\"
EOF"

    log "Reiniciando serviço..."
    sudo systemctl daemon-reexec
    sudo systemctl restart tftpd-hpa
    sudo systemctl enable tftpd-hpa

    sucesso "Servidor TFTP configurado com sucesso!"
    echo -e "📂 Diretório: ${AMARELO}$TFTP_DIR${RESET}"
    echo -e "⚡ Teste com: ${AMARELO}tftp <ip_servidor>${RESET}"
}

testar_tftp() {
    TEST_FILE="$TFTP_DIR/teste.txt"
    echo "Arquivo de teste TFTP - $(date)" | sudo tee "$TEST_FILE" > /dev/null
    sudo chmod 666 "$TEST_FILE"

    log "Testando envio e download do arquivo..."

    tftp localhost <<EOF > /dev/null 2>&1
get teste.txt
quit
EOF

    if [[ -f "teste.txt" ]]; then
        sucesso "Teste bem-sucedido! Arquivo transferido via TFTP."
        rm -f teste.txt
    else
        erro "Falha no teste. Verifique firewall ou permissões."
    fi
}

# =========================
# STATUS
# =========================
status_tftp() {
    systemctl status tftpd-hpa --no-pager
}

# =========================
# REMOVER
# =========================
remover_tftp() {
    log "Parando e removendo serviço..."
    sudo systemctl stop tftpd-hpa || true
    sudo apt purge -y tftpd-hpa >> "$LOG_FILE" 2>&1
    sudo rm -rf "$TFTP_DIR"
    sudo rm -f "$CONFIG_FILE"
    sucesso "Servidor TFTP removido do sistema."
}

# =========================
# MENU
# =========================
menu() {
    clear
    echo -e "${AMARELO}===== Gerenciador de Servidor TFTP =====${RESET}"
    echo "1) Instalar e configurar"
    echo "2) Testar servidor"
    echo "3) Mostrar status"
    echo "4) Remover servidor"
    echo "5) Sair"
    echo "========================================="
    read -rp "Escolha uma opção: " opcao

    case $opcao in
        1) instalar_tftp ;;
        2) testar_tftp ;;
        3) status_tftp ;;
        4) remover_tftp ;;
        5) exit 0 ;;
        *) erro "Opção inválida." ;;
    esac
}

# =========================
# EXECUÇÃO
# =========================
menu
