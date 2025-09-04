#!/bin/bash

#==============================================================================
# SQL Server Database Manager for Linux (Debian/Ubuntu)
# Descrição: Script completo para instalação, configuração e gerenciamento
#            avançado de SQL Server 2022 em sistemas Linux
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
readonly SQLSERVER_VERSION="2022"
readonly LOG_FILE="/var/log/sqlserver_manager.log"
readonly SQLSERVER_DATA_DIR="/var/opt/mssql/data"
readonly SQLSERVER_LOG_DIR="/var/opt/mssql/log"
readonly BACKUP_DIR="/var/backups/sqlserver"
readonly SA_PASSWORD_FILE="/etc/mssql/.sa_password"

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
    
    # Verificar se é uma distribuição suportada
    local os_version
    os_version=$(lsb_release -rs)
    local os_id
    os_id=$(lsb_release -is)
    
    if [[ "$os_id" != "Ubuntu" ]] || [[ $(echo "$os_version < 18.04" | bc -l) -eq 1 ]]; then
        warning "SQL Server é oficialmente suportado no Ubuntu 18.04+ e RHEL 8+"
        info "Continuando mesmo assim..."
    fi
}

check_system_requirements() {
    local memory_gb
    memory_gb=$(free -g | awk 'NR==2{print $2}')
    local disk_space_gb
    disk_space_gb=$(df / --output=avail -BG | tail -1 | sed 's/G//')
    
    info "Verificando requisitos do sistema..."
    info "Memória disponível: ${memory_gb}GB"
    info "Espaço em disco: ${disk_space_gb}GB"
    
    if [[ $memory_gb -lt 2 ]]; then
        error "SQL Server requer pelo menos 2GB de RAM (recomendado: 4GB+)"
        exit 1
    fi
    
    if [[ $disk_space_gb -lt 6 ]]; then
        error "SQL Server requer pelo menos 6GB de espaço livre"
        exit 1
    fi
}

print_banner() {
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║          SQL Server Database Manager v2.0                    ║
║               Linux Edition (Ubuntu/Debian)                  ║
║                                                               ║
║  Instalação, configuração e gerenciamento completo do        ║
║  Microsoft SQL Server 2022 com funcionalidades avançadas    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

generate_strong_password() {
    # Gerar senha forte para SA (mínimo 8 caracteres, com maiúscula, minúscula, número e símbolo)
    openssl rand -base64 12 | tr -d "=+/" | cut -c1-12
    echo "$(openssl rand -base64 12 | tr -d '=+/')Aa1!"
}

#==============================================================================
# FUNÇÕES DE INSTALAÇÃO
#==============================================================================

install_sqlserver() {
    log "Iniciando instalação do SQL Server ${SQLSERVER_VERSION}"
    
    check_system_requirements
    
    # Atualizar sistema
    info "Atualizando sistema..."
    apt update && apt upgrade -y
    
    # Instalar dependências
    info "Instalando dependências..."
    apt install -y wget software-properties-common apt-transport-https \
                   ca-certificates curl gnupg lsb-release bc
    
    # Adicionar repositório Microsoft
    info "Adicionando repositório Microsoft..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/mssql-server-2022.list)"
    
    # Atualizar após adicionar repositório
    apt update
    
    # Instalar SQL Server
    info "Instalando SQL Server 2022..."
    apt install -y mssql-server
    
    # Configuração inicial
    info "Configurando SQL Server..."
    
    # Gerar senha forte para SA
    local sa_password
    sa_password=$(generate_strong_password)
    
    # Salvar senha em arquivo seguro
    mkdir -p "$(dirname "$SA_PASSWORD_FILE")"
    echo "$sa_password" > "$SA_PASSWORD_FILE"
    chmod 600 "$SA_PASSWORD_FILE"
    chown mssql:mssql "$SA_PASSWORD_FILE"
    
    # Configurar SQL Server
    MSSQL_SA_PASSWORD="$sa_password" \
    MSSQL_PID="Developer" \
    /opt/mssql/bin/mssql-conf -n setup accept-eula
    
    # Instalar ferramentas de linha de comando
    info "Instalando SQL Server Tools..."
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list)"
    apt update
    ACCEPT_EULA=Y apt install -y mssql-tools unixodbc-dev
    
    # Adicionar ferramentas ao PATH
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /etc/bash.bashrc
    
    # Habilitar e iniciar serviço
    systemctl enable mssql-server
    systemctl start mssql-server
    
    # Criar diretórios necessários
    mkdir -p "$BACKUP_DIR"
    chown mssql:mssql "$BACKUP_DIR"
    
    success "SQL Server ${SQLSERVER_VERSION} instalado com sucesso!"
    success "Senha do usuário SA salva em: ${SA_PASSWORD_FILE}"
    info "Para usar as ferramentas, execute: source /etc/bash.bashrc"
    
    log "SQL Server ${SQLSERVER_VERSION} instalado e configurado"
}

#==============================================================================
# CONFIGURAÇÃO E OTIMIZAÇÃO
#==============================================================================

optimize_sqlserver() {
    log "Iniciando otimização do SQL Server"
    
    local memory_mb
    memory_mb=$(free -m | awk 'NR==2{printf "%d", $2}')
    local max_server_memory=$((memory_mb * 80 / 100)) # 80% da RAM disponível
    
    info "Configurando otimizações baseadas em ${memory_mb}MB de RAM"
    info "Max Server Memory será configurado para: ${max_server_memory}MB"
    
    # Obter senha do SA
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    # Aplicar configurações de otimização via T-SQL
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" << EOF
-- ===============================================
-- CONFIGURAÇÕES DE OTIMIZAÇÃO SQL SERVER
-- Aplicadas em: $(date)
-- ===============================================

-- Configurar memória máxima do servidor
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO

EXEC sys.sp_configure N'max server memory (MB)', N'${max_server_memory}'
RECONFIGURE WITH OVERRIDE
GO

-- Configurar paralelismo
EXEC sys.sp_configure N'max degree of parallelism', N'4'
RECONFIGURE WITH OVERRIDE
GO

EXEC sys.sp_configure N'cost threshold for parallelism', N'50'
RECONFIGURE WITH OVERRIDE
GO

-- Configurar backup compression padrão
EXEC sys.sp_configure N'backup compression default', N'1'
RECONFIGURE WITH OVERRIDE
GO

-- Habilitar otimizações avançadas
EXEC sys.sp_configure N'optimize for ad hoc workloads', N'1'
RECONFIGURE WITH OVERRIDE
GO

-- Configurar Database Mail (se necessário)
-- EXEC sys.sp_configure N'Database Mail XPs', N'1'
-- RECONFIGURE WITH OVERRIDE
-- GO

PRINT 'Configurações de otimização aplicadas com sucesso!'
GO
EOF

    # Configurações no nível do sistema operacional
    info "Aplicando configurações de sistema..."
    
    # Configurar limites do sistema para o usuário mssql
    cat > /etc/security/limits.d/99-mssql.conf << EOF
# Limites para SQL Server
mssql soft nofile 65536
mssql hard nofile 65536
mssql soft nproc 32768
mssql hard nproc 32768
EOF

    # Configurações de rede
    /opt/mssql/bin/mssql-conf set network.tcpport 1433
    /opt/mssql/bin/mssql-conf set network.enabletls 1
    
    # Configurações de memória
    /opt/mssql/bin/mssql-conf set memory.memorylimitmb "$max_server_memory"
    
    # Reiniciar serviço
    systemctl restart mssql-server
    
    success "SQL Server otimizado com sucesso!"
    log "Otimizações aplicadas ao SQL Server"
}

#==============================================================================
# GERENCIAMENTO DE DATABASES E USUÁRIOS
#==============================================================================

create_database() {
    local dbname="$1"
    local initial_size="${2:-100}"
    local max_size="${3:-1000}"
    
    log "Criando database: ${dbname}"
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" << EOF
CREATE DATABASE [${dbname}]
ON (
    NAME = '${dbname}_Data',
    FILENAME = '${SQLSERVER_DATA_DIR}/${dbname}.mdf',
    SIZE = ${initial_size}MB,
    MAXSIZE = ${max_size}MB,
    FILEGROWTH = 10MB
)
LOG ON (
    NAME = '${dbname}_Log',
    FILENAME = '${SQLSERVER_LOG_DIR}/${dbname}.ldf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%
);

-- Configurar recovery model para FULL
ALTER DATABASE [${dbname}] SET RECOVERY FULL;

-- Habilitar AUTO_SHRINK = OFF (boa prática)
ALTER DATABASE [${dbname}] SET AUTO_SHRINK OFF;

PRINT 'Database ${dbname} criada com sucesso!'
GO
EOF

    success "Database ${dbname} criada com sucesso!"
}

create_user() {
    local username="$1"
    local password="$2"
    local dbname="${3:-master}"
    local role="${4:-db_datareader}"
    
    log "Criando usuário: ${username} na database ${dbname}"
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" << EOF
-- Criar login no servidor
CREATE LOGIN [${username}] WITH PASSWORD = '${password}';

-- Usar a database especificada
USE [${dbname}];

-- Criar usuário na database
CREATE USER [${username}] FOR LOGIN [${username}];

-- Adicionar ao role especificado
ALTER ROLE [${role}] ADD MEMBER [${username}];

PRINT 'Usuário ${username} criado com sucesso na database ${dbname}!'
GO
EOF

    success "Usuário ${username} criado com sucesso!"
}

list_databases() {
    info "Databases SQL Server:"
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -Q "
    SELECT 
        name AS 'Database Name',
        database_id AS 'ID',
        create_date AS 'Created',
        CAST(size * 8.0 / 1024 AS DECIMAL(10,2)) AS 'Size (MB)'
    FROM sys.databases 
    ORDER BY name;"
}

list_users() {
    local dbname="${1:-master}"
    
    info "Usuários na database: ${dbname}"
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -d "$dbname" -Q "
    SELECT 
        u.name AS 'User Name',
        l.name AS 'Login Name',
        u.type_desc AS 'Type',
        u.create_date AS 'Created'
    FROM sys.database_principals u
    LEFT JOIN sys.server_principals l ON u.sid = l.sid
    WHERE u.type IN ('S', 'U')
    ORDER BY u.name;"
}

#==============================================================================
# BACKUP E RESTORE
#==============================================================================

backup_database() {
    local dbname="$1"
    local backup_type="${2:-FULL}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/${dbname}_${backup_type}_${timestamp}.bak"
    
    log "Iniciando backup ${backup_type} da database: ${dbname}"
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    case "$backup_type" in
        "FULL")
            /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" << EOF
BACKUP DATABASE [${dbname}] 
TO DISK = '${backup_file}'
WITH 
    FORMAT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10;

PRINT 'Backup FULL da database ${dbname} concluído!'
GO
EOF
            ;;
        "DIFF")
            /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" << EOF
BACKUP DATABASE [${dbname}] 
TO DISK = '${backup_file}'
WITH 
    DIFFERENTIAL,
    FORMAT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10;

PRINT 'Backup DIFERENCIAL da database ${dbname} concluído!'
GO
EOF
            ;;
        "LOG")
            backup_file="${BACKUP_DIR}/${dbname}_LOG_${timestamp}.trn"
            /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" << EOF
BACKUP LOG [${dbname}] 
TO DISK = '${backup_file}'
WITH 
    FORMAT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10;

PRINT 'Backup de LOG da database ${dbname} concluído!'
GO
EOF
            ;;
    esac
    
    success "Backup ${backup_type} concluído: ${backup_file}"
    log "Backup ${backup_type} da database ${dbname} salvo em ${backup_file}"
}

restore_database() {
    local dbname="$1"
    local backup_file="$2"
    local restore_type="${3:-REPLACE}"
    
    log "Iniciando restore da database: ${dbname}"
    
    if [[ ! -f "$backup_file" ]]; then
        error "Arquivo de backup não encontrado: ${backup_file}"
        return 1
    fi
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    # Primeiro, verificar o conteúdo do backup
    info "Verificando conteúdo do backup..."
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -Q "
    RESTORE FILELISTONLY FROM DISK = '${backup_file}';"
    
    # Executar restore
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" << EOF
-- Colocar database em modo single user se existir
IF EXISTS (SELECT name FROM sys.databases WHERE name = '${dbname}')
BEGIN
    ALTER DATABASE [${dbname}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
END

-- Executar restore
RESTORE DATABASE [${dbname}]
FROM DISK = '${backup_file}'
WITH 
    REPLACE,
    CHECKSUM,
    STATS = 10;

-- Retornar ao modo multi user
ALTER DATABASE [${dbname}] SET MULTI_USER;

PRINT 'Restore da database ${dbname} concluído!'
GO
EOF
    
    success "Restore da database ${dbname} concluído!"
    log "Database ${dbname} restaurada de ${backup_file}"
}

#==============================================================================
# MONITORAMENTO E ESTATÍSTICAS
#==============================================================================

show_status() {
    info "=== STATUS DO SQL SERVER ==="
    systemctl status mssql-server --no-pager
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    echo
    info "=== INFORMAÇÕES DO SERVIDOR ==="
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -Q "
    SELECT 
        @@SERVERNAME AS 'Server Name',
        @@VERSION AS 'Version',
        SERVERPROPERTY('Edition') AS 'Edition',
        SERVERPROPERTY('ProductLevel') AS 'Service Pack',
        SERVERPROPERTY('Collation') AS 'Collation';"
    
    echo
    info "=== CONEXÕES ATIVAS ==="
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -Q "
    SELECT 
        DB_NAME(database_id) AS 'Database',
        COUNT(*) AS 'Active Connections'
    FROM sys.dm_exec_sessions 
    WHERE is_user_process = 1
    GROUP BY database_id
    ORDER BY COUNT(*) DESC;"
    
    echo
    info "=== UTILIZAÇÃO DE CPU E MEMÓRIA ==="
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -Q "
    SELECT 
        (SELECT COUNT(*) FROM sys.dm_exec_sessions WHERE is_user_process = 1) AS 'User Sessions',
        (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio') AS 'Buffer Cache Hit Ratio',
        (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Page life expectancy') AS 'Page Life Expectancy';"
    
    echo
    info "=== TAMANHO DAS DATABASES ==="
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -Q "
    SELECT 
        name AS 'Database Name',
        CAST((size * 8.0 / 1024) AS DECIMAL(10,2)) AS 'Size (MB)',
        CAST((FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024) AS DECIMAL(10,2)) AS 'Used (MB)',
        CAST(((size - FILEPROPERTY(name, 'SpaceUsed')) * 8.0 / 1024) AS DECIMAL(10,2)) AS 'Free (MB)'
    FROM sys.database_files
    WHERE type = 0;"
    
    echo
    info "=== UTILIZAÇÃO DE DISCO ==="
    df -h "$SQLSERVER_DATA_DIR" "$SQLSERVER_LOG_DIR" "$BACKUP_DIR"
}

analyze_performance() {
    info "=== ANÁLISE DE PERFORMANCE ==="
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    echo
    info "Top 10 queries por CPU:"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -Q "
    SELECT TOP 10
        total_worker_time/execution_count AS 'Avg CPU Time',
        total_worker_time AS 'Total CPU Time',
        execution_count AS 'Execution Count',
        SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
            ((CASE statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE qs.statement_end_offset END
                    - qs.statement_start_offset)/2) + 1) AS 'Statement Text'
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
    ORDER BY total_worker_time/execution_count DESC;"
    
    echo
    info "Estatísticas de I/O por database:"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -Q "
    SELECT 
        DB_NAME(database_id) AS 'Database Name',
        SUM(num_of_reads) AS 'Total Reads',
        SUM(num_of_writes) AS 'Total Writes',
        SUM(io_stall_read_ms) AS 'Total Read Stall (ms)',
        SUM(io_stall_write_ms) AS 'Total Write Stall (ms)'
    FROM sys.dm_io_virtual_file_stats(NULL, NULL)
    GROUP BY database_id
    ORDER BY SUM(num_of_reads + num_of_writes) DESC;"
    
    echo
    info "Wait Statistics (Top 10):"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" -Q "
    SELECT TOP 10
        wait_type,
        wait_time_ms,
        waiting_tasks_count,
        wait_time_ms / waiting_tasks_count AS 'Avg Wait Time (ms)'
    FROM sys.dm_os_wait_stats
    WHERE wait_time_ms > 0
    ORDER BY wait_time_ms DESC;"
}

#==============================================================================
# MANUTENÇÃO
#==============================================================================

maintenance() {
    log "Iniciando manutenção do SQL Server"
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    info "Executando manutenção em todas as databases..."
    
    # Script de manutenção abrangente
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" << 'EOF'
DECLARE @DatabaseName NVARCHAR(128)
DECLARE @SQL NVARCHAR(MAX)

DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE database_id > 4 -- Excluir databases do sistema
AND state = 0 -- Online apenas

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Executando manutenção na database: ' + @DatabaseName
    
    -- Update Statistics
    SET @SQL = 'USE [' + @DatabaseName + ']; EXEC sp_updatestats;'
    EXEC sp_executesql @SQL
    
    -- Rebuild/Reorganize Indexes
    SET @SQL = 'USE [' + @DatabaseName + '];
    DECLARE @TableName NVARCHAR(128)
    DECLARE @IndexName NVARCHAR(128)
    DECLARE @Fragmentation FLOAT
    DECLARE @IndexSQL NVARCHAR(MAX)
    
    DECLARE index_cursor CURSOR FOR
    SELECT 
        OBJECT_NAME(a.object_id) AS TableName,
        b.name AS IndexName,
        a.avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) a
    INNER JOIN sys.indexes b ON a.object_id = b.object_id AND a.index_id = b.index_id
    WHERE a.avg_fragmentation_in_percent > 5
    AND b.name IS NOT NULL
    
    OPEN index_cursor
    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Fragmentation > 30
            SET @IndexSQL = ''ALTER INDEX ['' + @IndexName + ''] ON ['' + @TableName + ''] REBUILD;''
        ELSE
            SET @IndexSQL = ''ALTER INDEX ['' + @IndexName + ''] ON ['' + @TableName + ''] REORGANIZE;''
        
        EXEC sp_executesql @IndexSQL
        FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation
    END
    
    CLOSE index_cursor
    DEALLOCATE index_cursor'
    
    EXEC sp_executesql @SQL
    
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END

CLOSE db_cursor
DEALLOCATE db_cursor

PRINT 'Manutenção concluída em todas as databases!'
GO
EOF

    info "Limpando logs antigos..."
    find "$SQLSERVER_LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
    find "$BACKUP_DIR" -name "*.bak" -mtime +7 -delete 2>/dev/null || true
    find "$BACKUP_DIR" -name "*.trn" -mtime +3 -delete 2>/dev/null || true
    
    success "Manutenção concluída!"
    log "Manutenção do SQL Server executada com sucesso"
}

#==============================================================================
# CONFIGURAÇÃO DE ALTA DISPONIBILIDADE
#==============================================================================

setup_always_on() {
    local ag_name="${1:-AG_Primary}"
    local partner_server="$2"
    
    if [[ -z "$partner_server" ]]; then
        error "É necessário especificar o servidor parceiro para Always On"
        return 1
    fi
    
    log "Configurando Always On Availability Groups"
    
    local sa_password
    sa_password=$(cat "$SA_PASSWORD_FILE")
    
    info "Habilitando Always On Availability Groups..."
    
    # Habilitar Always On
    /opt/mssql/bin/mssql-conf set hadr.hadrenabled 1
    systemctl restart mssql-server
    
    # Script para configurar Availability Group
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$sa_password" << EOF
-- Criar endpoints para Always On
IF NOT EXISTS (SELECT * FROM sys.endpoints WHERE name = 'Hadr_endpoint')
BEGIN
    CREATE ENDPOINT [Hadr_endpoint] 
    AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
    FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = WINDOWS NEGOTIATE
    , ENCRYPTION = REQUIRED ALGORITHM AES)
    
    ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;
END

-- Criar Availability Group
-- NOTA: Este é um exemplo básico. A configuração completa requer
-- configuração em ambos os servidores
PRINT 'Always On habilitado. Configure o parceiro: ${partner_server}'
PRINT 'Endpoint criado na porta 5022'
GO
EOF

    success "Always On Availability Groups configurado!"
    info "Configure o servidor parceiro (${partner_server}) com as mesmas configurações"
    info "Endpoint criado na porta 5022"
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
    echo "  1)  Instalar SQL Server completo"
    echo "  2)  Otimizar configurações"
    echo
    echo "  ${YELLOW}GERENCIAMENTO:${NC}"
    echo "  3)  Criar database"
    echo "  4)  Criar usuário"
    echo "  5)  Listar databases"
    echo "  6)  Listar usuários"
    echo
    echo "  ${YELLOW}BACKUP E RESTORE:${NC}"
    echo "  7)  Backup Full"
    echo "  8)  Backup Diferencial"
    echo "  9)  Backup de Log"
    echo "  10) Restaurar database"
    echo
    echo "  ${YELLOW}MONITORAMENTO:${NC}"
    echo "  11) Status do sistema"
    echo "  12) Análise de performance"
    echo
    echo "  ${YELLOW}MANUTENÇÃO:${NC}"
    echo "  13) Executar
