#!/bin/bash

#==============================================================================
# PostgreSQL Database Manager for Debian/Ubuntu
# Descrição: Script completo para instalação, configuração e gerenciamento
#            avançado de PostgreSQL em sistemas Debian/Ubuntu
#==============================================================================

set -euo pipefail

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configurações globais
readonly SCRIPT_VERSION="2.0"
readonly POSTGRES_VERSION="15"
readonly LOG_FILE="/var/log/postgres_manager.log"
readonly CONFIG_DIR="/etc/postgresql/${POSTGRES_VERSION}/main"
readonly DATA_DIR="/var/lib/postgresql/${POSTGRES_VERSION}/main"

#==============================================================================
# FUNÇÕES UTILITÁRIAS
#==============================================================================

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" >/dev/null
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | sudo tee -a "$LOG_FILE" >/dev/null
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" | sudo tee -a "$LOG_FILE" >/dev/null
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script precisa ser executado como root (sudo)"
        exit 1
    fi
}

check_os() {
    if ! command -v apt >/dev/null 2>&1; then
        error "Sistema não suportado. Este script é para Debian/Ubuntu"
        exit 1
    fi
}

print_banner() {
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║          PostgreSQL Database Manager v2.0                    ║
║               Debian/Ubuntu Edition                           ║
║                                                               ║
║  Instalação, configuração e gerenciamento completo do        ║
║  PostgreSQL com funcionalidades avançadas                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#==============================================================================
# FUNÇÕES DE INSTALAÇÃO
#==============================================================================

install_postgresql() {
    log "Iniciando instalação do PostgreSQL ${POSTGRES_VERSION}"
    
    # Atualizar repositórios
    info "Atualizando repositórios do sistema..."
    apt update && apt upgrade -y
    
    # Instalar dependências
    info "Instalando dependências..."
    apt install -y wget ca-certificates software-properties-common apt-transport-https lsb-release
    
    # Adicionar repositório oficial do PostgreSQL
    info "Adicionando repositório oficial do PostgreSQL..."
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
    
    # Atualizar após adicionar novo repo
    apt update
    
    # Instalar PostgreSQL e ferramentas adicionais
    info "Instalando PostgreSQL ${POSTGRES_VERSION} e ferramentas..."
    apt install -y postgresql-${POSTGRES_VERSION} postgresql-client-${POSTGRES_VERSION} \
                   postgresql-contrib-${POSTGRES_VERSION} postgresql-${POSTGRES_VERSION}-pgaudit \
                   postgresql-${POSTGRES_VERSION}-pg-stat-kcache pgbouncer \
                   postgresql-${POSTGRES_VERSION}-repack postgresql-plpython3-${POSTGRES_VERSION}
    
    # Iniciar e habilitar serviço
    systemctl start postgresql
    systemctl enable postgresql
    
    success "PostgreSQL ${POSTGRES_VERSION} instalado com sucesso!"
    log "PostgreSQL ${POSTGRES_VERSION} instalado e configurado"
}

#==============================================================================
# CONFIGURAÇÃO E OTIMIZAÇÃO
#==============================================================================

optimize_postgresql() {
    log "Iniciando otimização do PostgreSQL"
    
    local memory_mb=$(free -m | awk 'NR==2{printf "%d", $2}')
    local shared_buffers=$((memory_mb / 4))
    local effective_cache_size=$((memory_mb * 3 / 4))
    local work_mem=$((memory_mb / 32))
    
    info "Configurando otimizações baseadas em ${memory_mb}MB de RAM"
    
    # Backup da configuração original
    cp "${CONFIG_DIR}/postgresql.conf" "${CONFIG_DIR}/postgresql.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Aplicar configurações otimizadas
    cat >> "${CONFIG_DIR}/postgresql.conf" << EOF

# ==============================================
# CONFIGURAÇÕES OTIMIZADAS - PostgreSQL Manager
# Aplicadas em: $(date)
# ==============================================

# Configurações de Memória
shared_buffers = ${shared_buffers}MB
effective_cache_size = ${effective_cache_size}MB
work_mem = ${work_mem}MB
maintenance_work_mem = 256MB

# Configurações de WAL
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 2GB
min_wal_size = 512MB

# Configurações de Performance
random_page_cost = 1.1
effective_io_concurrency = 200
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4

# Configurações de Logging
log_destination = 'stderr,csvlog'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Configurações de Segurança
ssl = on
password_encryption = 'scram-sha-256'

# Configurações de Auditoria
shared_preload_libraries = 'pgaudit,pg_stat_statements'
pgaudit.log = 'write,ddl'
pg_stat_statements.track = all
EOF

    # Configurar pg_hba.conf para segurança
    cp "${CONFIG_DIR}/pg_hba.conf" "${CONFIG_DIR}/pg_hba.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    cat > "${CONFIG_DIR}/pg_hba.conf" << EOF
# PostgreSQL Client Authentication Configuration File
# Configurado pelo PostgreSQL Manager

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" é para conexões Unix domain socket apenas
local   all             postgres                                peer
local   all             all                                     scram-sha-256

# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             10.0.0.0/8              scram-sha-256
host    all             all             172.16.0.0/12           scram-sha-256
host    all             all             192.168.0.0/16          scram-sha-256

# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256
EOF

    systemctl restart postgresql
    success "PostgreSQL otimizado com sucesso!"
    log "Otimizações aplicadas ao PostgreSQL"
}

#==============================================================================
# GERENCIAMENTO DE USUÁRIOS E DATABASES
#==============================================================================

create_user() {
    local username="$1"
    local password="$2"
    local is_superuser="${3:-false}"
    
    log "Criando usuário: ${username}"
    
    local superuser_flag=""
    if [[ "$is_superuser" == "true" ]]; then
        superuser_flag="SUPERUSER"
    fi
    
    sudo -u postgres psql -c "CREATE USER ${username} WITH PASSWORD '${password}' ${superuser_flag};"
    success "Usuário ${username} criado com sucesso!"
}

create_database() {
    local dbname="$1"
    local owner="${2:-postgres}"
    local encoding="${3:-UTF8}"
    
    log "Criando database: ${dbname}"
    
    sudo -u postgres psql -c "CREATE DATABASE ${dbname} WITH OWNER ${owner} ENCODING '${encoding}';"
    success "Database ${dbname} criado com sucesso!"
}

list_users() {
    info "Usuários PostgreSQL:"
    sudo -u postgres psql -c "\du"
}

list_databases() {
    info "Databases PostgreSQL:"
    sudo -u postgres psql -c "\l"
}

#==============================================================================
# BACKUP E RESTORE
#==============================================================================

backup_database() {
    local dbname="$1"
    local backup_dir="/var/backups/postgresql"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_dir}/${dbname}_backup_${timestamp}.sql"
    
    # Criar diretório de backup se não existir
    mkdir -p "$backup_dir"
    
    log "Iniciando backup da database: ${dbname}"
    
    # Backup completo com dados e esquema
    sudo -u postgres pg_dump -d "$dbname" \
        --verbose \
        --format=custom \
        --blobs \
        --file="${backup_file}.dump"
    
    # Backup em SQL puro para compatibilidade
    sudo -u postgres pg_dump -d "$dbname" > "$backup_file"
    
    # Comprimir backups
    gzip "$backup_file"
    
    success "Backup concluído: ${backup_file}.gz e ${backup_file}.dump"
    log "Backup da database ${dbname} salvo em ${backup_file}.gz"
}

restore_database() {
    local dbname="$1"
    local backup_file="$2"
    
    log "Iniciando restore da database: ${dbname}"
    
    if [[ "$backup_file" == *.dump ]]; then
        # Restore do formato custom
        sudo -u postgres pg_restore -d "$dbname" --verbose --clean --if-exists "$backup_file"
    else
        # Restore do formato SQL
        if [[ "$backup_file" == *.gz ]]; then
            gunzip -c "$backup_file" | sudo -u postgres psql -d "$dbname"
        else
            sudo -u postgres psql -d "$dbname" < "$backup_file"
        fi
    fi
    
    success "Restore da database ${dbname} concluído!"
    log "Database ${dbname} restaurada de ${backup_file}"
}

#==============================================================================
# MONITORAMENTO E ESTATÍSTICAS
#==============================================================================

show_status() {
    info "=== STATUS DO POSTGRESQL ==="
    systemctl status postgresql --no-pager
    
    echo
    info "=== CONEXÕES ATIVAS ==="
    sudo -u postgres psql -c "SELECT count(*) as conexoes_ativas FROM pg_stat_activity WHERE state = 'active';"
    
    echo
    info "=== TOP 10 QUERIES POR TEMPO ==="
    sudo -u postgres psql -c "
    SELECT query, calls, total_time, mean_time 
    FROM pg_stat_statements 
    ORDER BY total_time DESC 
    LIMIT 10;"
    
    echo
    info "=== TAMANHO DAS DATABASES ==="
    sudo -u postgres psql -c "
    SELECT datname, pg_size_pretty(pg_database_size(datname)) as tamanho 
    FROM pg_database 
    ORDER BY pg_database_size(datname) DESC;"
    
    echo
    info "=== UTILIZAÇÃO DE DISCO ==="
    df -h /var/lib/postgresql
}

analyze_performance() {
    info "=== ANÁLISE DE PERFORMANCE ==="
    
    echo
    info "Cache Hit Ratio (deve ser > 99%):"
    sudo -u postgres psql -c "
    SELECT 
        sum(heap_blks_read) as heap_read,
        sum(heap_blks_hit)  as heap_hit,
        (sum(heap_blks_hit) - sum(heap_blks_read)) / sum(heap_blks_hit) as ratio
    FROM pg_statio_user_tables;"
    
    echo
    info "Estatísticas de Checkpoint:"
    sudo -u postgres psql -c "
    SELECT checkpoints_timed, checkpoints_req, checkpoint_write_time, checkpoint_sync_time 
    FROM pg_stat_bgwriter;"
    
    echo
    info "Locks ativos:"
    sudo -u postgres psql -c "
    SELECT mode, count(*) 
    FROM pg_locks 
    GROUP BY mode 
    ORDER BY count DESC;"
}

#==============================================================================
# MANUTENÇÃO
#==============================================================================

maintenance() {
    log "Iniciando manutenção do PostgreSQL"
    
    info "Executando VACUUM e ANALYZE em todas as databases..."
    
    # Obter lista de databases
    databases=$(sudo -u postgres psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
    
    for db in $databases; do
        info "Manutenção na database: $db"
        sudo -u postgres psql -d "$db" -c "VACUUM ANALYZE;"
    done
    
    info "Limpando logs antigos (>30 dias)..."
    find /var/log/postgresql -name "*.log" -mtime +30 -delete
    
    info "Executando REINDEX em databases críticas..."
    for db in $databases; do
        sudo -u postgres psql -d "$db" -c "REINDEX DATABASE $db;" 2>/dev/null || true
    done
    
    success "Manutenção concluída!"
    log "Manutenção do PostgreSQL executada com sucesso"
}

#==============================================================================
# CONFIGURAÇÃO DE REPLICAÇÃO
#==============================================================================

setup_replication() {
    local slave_ip="$1"
    local replication_user="replicator"
    local replication_pass=$(openssl rand -base64 12)
    
    log "Configurando replicação master para ${slave_ip}"
    
    # Criar usuário de replicação
    sudo -u postgres psql -c "CREATE USER ${replication_user} WITH REPLICATION PASSWORD '${replication_pass}';"
    
    # Configurar pg_hba.conf para replicação
    echo "host replication ${replication_user} ${slave_ip}/32 scram-sha-256" >> "${CONFIG_DIR}/pg_hba.conf"
    
    # Configurar postgresql.conf para replicação
    cat >> "${CONFIG_DIR}/postgresql.conf" << EOF

# Configurações de Replicação
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
hot_standby = on
EOF

    systemctl restart postgresql
    
    success "Replicação configurada!"
    info "Usuário de replicação: ${replication_user}"
    info "Senha de replicação: ${replication_pass}"
    info "Adicione esta linha no slave: host replication ${replication_user} ${slave_ip}/32 scram-sha-256"
}

#==============================================================================
# MENU PRINCIPAL
#==============================================================================

show_menu() {
    clear
    print_banner
    
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo
    echo "  ${YELLOW}INSTALAÇÃO E CONFIGURAÇÃO:${NC}"
    echo "  1)  Instalar PostgreSQL completo"
    echo "  2)  Otimizar configurações"
    echo
    echo "  ${YELLOW}GERENCIAMENTO:${NC}"
    echo "  3)  Criar usuário"
    echo "  4)  Criar database"
    echo "  5)  Listar usuários"
    echo "  6)  Listar databases"
    echo
    echo "  ${YELLOW}BACKUP E RESTORE:${NC}"
    echo "  7)  Fazer backup de database"
    echo "  8)  Restaurar database"
    echo
    echo "  ${YELLOW}MONITORAMENTO:${NC}"
    echo "  9)  Status do sistema"
    echo "  10) Análise de performance"
    echo
    echo "  ${YELLOW}MANUTENÇÃO:${NC}"
    echo "  11) Executar manutenção"
    echo "  12) Configurar replicação"
    echo
    echo "  ${YELLOW}AVANÇADO:${NC}"
    echo "  13) Shell PostgreSQL (psql)"
    echo "  14) Ver logs"
    echo
    echo "  0)  Sair"
    echo
    echo -ne "${GREEN}Digite sua escolha [0-14]: ${NC}"
}

#==============================================================================
# FUNÇÃO PRINCIPAL
#==============================================================================

main() {
    check_root
    check_os
    
    # Criar arquivo de log se não existir
    touch "$LOG_FILE"
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                clear
                install_postgresql
                read -p "Pressione ENTER para continuar..."
                ;;
            2)
                clear
                optimize_postgresql
                read -p "Pressione ENTER para continuar..."
                ;;
            3)
                clear
                echo -n "Nome do usuário: "
                read -r username
                echo -n "Senha: "
                read -rs password
                echo
                echo -n "É superusuário? (y/N): "
                read -r is_super
                [[ "$is_super" =~ ^[Yy]$ ]] && is_super="true" || is_super="false"
                create_user "$username" "$password" "$is_super"
                read -p "Pressione ENTER para continuar..."
                ;;
            4)
                clear
                echo -n "Nome da database: "
                read -r dbname
                echo -n "Owner (padrão: postgres): "
                read -r owner
                owner=${owner:-postgres}
                create_database "$dbname" "$owner"
                read -p "Pressione ENTER para continuar..."
                ;;
            5)
                clear
                list_users
                read -p "Pressione ENTER para continuar..."
                ;;
            6)
                clear
                list_databases
                read -p "Pressione ENTER para continuar..."
                ;;
            7)
                clear
                echo -n "Nome da database para backup: "
                read -r dbname
                backup_database "$dbname"
                read -p "Pressione ENTER para continuar..."
                ;;
            8)
                clear
                echo -n "Nome da database para restore: "
                read -r dbname
                echo -n "Caminho do arquivo de backup: "
                read -r backup_file
                restore_database "$dbname" "$backup_file"
                read -p "Pressione ENTER para continuar..."
                ;;
            9)
                clear
                show_status
                read -p "Pressione ENTER para continuar..."
                ;;
            10)
                clear
                analyze_performance
                read -p "Pressione ENTER para continuar..."
                ;;
            11)
                clear
                maintenance
                read -p "Pressione ENTER para continuar..."
                ;;
            12)
                clear
                echo -n "IP do servidor slave: "
                read -r slave_ip
                setup_replication "$slave_ip"
                read -p "Pressione ENTER para continuar..."
                ;;
            13)
                clear
                info "Abrindo shell PostgreSQL (digite \q para sair)"
                sudo -u postgres psql
                ;;
            14)
                clear
                info "Últimas 50 linhas do log:"
                tail -n 50 "$LOG_FILE"
                read -p "Pressione ENTER para continuar..."
                ;;
            0)
                success "Obrigado por usar o PostgreSQL Manager!"
                exit 0
                ;;
            *)
                error "Opção inválida!"
                sleep 1
                ;;
        esac
    done
}

#==============================================================================
# EXECUÇÃO
#==============================================================================

# Verificar se script está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
