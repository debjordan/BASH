#!/bin/bash

echo "Atualizando a lista de pacotes..."
sudo pacman -Syu --noconfirm

echo "Instalando o Samba..."
sudo pacman -S samba --noconfirm

SHARED_DIR="/srv/samba/shared"
echo "Criando diretório de compartilhamento: $SHARED_DIR"
sudo mkdir -p "$SHARED_DIR"
sudo chmod 777 "$SHARED_DIR"

SAMBA_CONF="/etc/samba/smb.conf"
echo "Configurando o Samba..."

sudo cp "$SAMBA_CONF" "$SAMBA_CONF.bak"

cat <<EOL | sudo tee -a "$SAMBA_CONF" > /dev/null

[shared]
   path = $SHARED_DIR
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
EOL

echo "Reiniciando o serviço Samba..."
sudo systemctl restart smb.service
sudo systemctl restart nmb.service

echo "Habilitando o Samba para iniciar na inicialização..."
sudo systemctl enable smb.service
sudo systemctl enable nmb.service

echo "Servidor Samba configurado com sucesso!"

