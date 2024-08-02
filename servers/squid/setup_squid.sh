#!/bin/bash

echo "Atualizando a lista de pacotes..."
sudo apt-get update -y

echo "Instalando o Squid..."
sudo apt-get install squid -y

SQUID_CONF="/etc/squid/squid.conf"
echo "Fazendo backup do arquivo de configuração do Squid..."
sudo cp "$SQUID_CONF" "$SQUID_CONF.bak"

echo "Configurando o Squid..."

cat <<EOL | sudo tee "$SQUID_CONF" > /dev/null
# Define a porta na qual o Squid escutará as requisições
http_port 3128

# Permite acesso ao proxy de qualquer IP
acl all src 0.0.0.0/0
http_access allow all

# Diretório onde o cache será armazenado
cache_dir ufs /var/spool/squid 100 16 256

# Define o tempo de expiração dos objetos em cache
maximum_object_size 4 MB
EOL

echo "Criando diretório de cache..."
sudo mkdir -p /var/spool/squid
sudo chown -R squid:squid /var/spool/squid

echo "Inicializando o cache do Squid..."
sudo squid -z

echo "Reiniciando o serviço do Squid..."
sudo systemctl restart squid

echo "Habilitando o Squid para iniciar na inicialização..."
sudo systemctl enable squid

echo "Servidor Squid configurado com sucesso!"

