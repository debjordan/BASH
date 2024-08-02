# Configuração Automática do Servidor Squid

Este repositório contém um script Bash para configurar automaticamente um servidor Squid em sistemas baseados em Debian/Ubuntu. O Squid é um servidor proxy que pode ser usado para cache de conteúdo, controle de acesso e monitoramento de tráfego.

## Funcionalidades do Script

- Atualiza a lista de pacotes.
- Instala o Squid.
- Configura uma configuração básica para o Squid.
- Cria diretório para cache e inicializa o cache.
- Reinicia e habilita o serviço Squid para iniciar na inicialização.

## Requisitos

- Sistema baseado em Debian/Ubuntu
- Permissões de superusuário (sudo)

## Como Usar

Descrição do Script
O script realiza as seguintes etapas:

Atualização de Pacotes: Atualiza a lista de pacotes do sistema.
Instalação do Squid: Instala o Squid utilizando o gerenciador de pacotes apt-get.
Configuração do Squid: Substitui o arquivo de configuração padrão do Squid com uma configuração básica.
Criação do Diretório de Cache: Cria e configura o diretório onde o cache do Squid será armazenado.
Inicialização do Cache: Inicializa o cache do Squid.
Reinício do Serviço: Reinicia o serviço Squid e o habilita para iniciar na inicialização.
Notas
O Squid é configurado para escutar na porta padrão 3128.
O script permite o acesso ao proxy de qualquer IP, o que é adequado para testes, mas pode precisar de ajustes para ambientes de produção.
O cache é configurado para armazenar objetos com um tamanho máximo de 4 MB.
