# Configuração Automática do Servidor Samba

Este repositório contém um script Bash para configurar automaticamente um servidor Samba no Arch Linux. O Samba permite compartilhar arquivos e impressoras entre sistemas Windows e Unix/Linux.

## Funcionalidades do Script

- Atualiza a lista de pacotes.
- Instala o Samba.
- Cria um diretório para compartilhamento.
- Configura o Samba para compartilhar a pasta criada.
- Reinicia e habilita o serviço Samba para iniciar na inicialização.

## Requisitos

- Arch Linux
- Permissões de superusuário (sudo)

## Como Usar

1. Clone o repositório:

   ```bash
   git clone <URL_DO_SEU_REPOSITORIO>
   cd nome_do_repositorio

Torne o script executável:

bash
Copiar código
chmod +x setup_samba.sh
Execute o script:

bash
Copiar código
./setup_samba.sh
Descrição do Script
O script realiza as seguintes etapas:

Atualização de Pacotes: Atualiza a lista de pacotes do sistema.
Instalação do Samba: Instala o Samba utilizando o gerenciador de pacotes pacman.
Criação do Diretório de Compartilhamento: Cria um diretório em /srv/samba/shared para compartilhar.
Configuração do Samba: Adiciona uma nova seção de compartilhamento no arquivo de configuração do Samba.
Reinício do Serviço: Reinicia os serviços smb e nmb e os habilita para iniciar na inicialização.
Notas
O diretório compartilhado é configurado com permissões de leitura e escrita para todos os usuários.
O compartilhamento é configurado para permitir o acesso de convidados sem a necessidade de autenticação.
