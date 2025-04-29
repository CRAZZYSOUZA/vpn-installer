#!/bin/bash
# Atualizar sistema
apt update
apt upgrade -y
apt install curl wget socat cron bash-completion lsof unzip -y

# Perguntar domínio para SSL
clear
read -p "Digite seu domínio (ex: vpn.seudominio.com): " domain
clear
echo "Dominio informado: $domain"
read -p "Confirma? (S/n): " confirm
if [[ "$confirm" =~ ^([nN][oO]?|[nN])$ ]]; then
    echo "Instalação cancelada."
    exit 1
fi

# Instalar ACME.sh para SSL
echo "[+] Instalando ACME para SSL..."
curl https://get.acme.sh | sh

# Ativar acme.sh
source ~/.bashrc
export PATH="$HOME/.acme.sh":$PATH

# Gerar certificado SSL
echo "[+] Gerando SSL para $domain..."
~/.acme.sh/acme.sh --issue --standalone -d $domain --force --keylength ec-256

# Instalar certificado
mkdir -p /etc/ssl/private
~/.acme.sh/acme.sh --install-cert -d $domain --ecc \
--fullchain-file /etc/ssl/private/$domain.crt \
--key-file /etc/ssl/private/$domain.key

# Instalar Xray-core
echo "[+] Instalando Xray-core..."
bash <(curl -sL https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh) install

# Instalar painel x-ui-gg
echo "[+] Instalando painel x-ui-gg..."
bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)

# Ativar painel
systemctl enable x-ui
systemctl start x-ui

# Adicionar template WebSocket + TLS no painel
echo "[+] Configurando template WebSocket + TLS (porta 443)..."
x-ui api addInbound << EOF
{
  "remark": "ws_tls_443",
  "port": 443,
  "protocol": "vless",
  "settings": {
    "clients": []
  },
  "streamSettings": {
    "network": "ws",
    "security": "tls",
    "tlsSettings": {
      "certificates": [
        {
          "certificateFile": "/etc/ssl/private/$domain.crt",
          "keyFile": "/etc/ssl/private/$domain.key"
        }
      ]
    },
    "wsSettings": {
      "path": "/ws"
    }
  },
  "sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls"]
  }
}
EOF

# Finalizado instalação Xray e Painel
clear
echo "=================================================="
echo " Xray-core e Painel x-ui-gg Instalados com sucesso!"
echo " Painel: https://$domain:54321"
echo " Login padrão: admin / admin"
echo "=================================================="
sleep 5

# Agora instalar e executar seu SSHPLUS
echo "[+] Instalando SSHPLUS..."
curl -o sshplus https://worldofdragon.us.eu.org/sshpluspro/$(uname -m)/sshplus
chmod +x sshplus
./sshplus