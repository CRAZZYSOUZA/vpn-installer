#!/bin/bash
# Instalador VPN com Nginx + SSH + WebSocket + BadVPN

# Verifica se é root
if [[ $EUID -ne 0 ]]; then
  echo "Execute como root"
  exit 1
fi

# Atualiza pacotes
apt update && apt upgrade -y

# Instala dependências
apt install -y nginx curl git unzip screen build-essential cmake

# Instala OpenSSH Server
apt install -y openssh-server
systemctl enable ssh && systemctl restart ssh

# Instala Node.js para o WebSocket
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Instala WebSocket (SSHWS)
git clone https://github.com/eduardokum/sshws.git /etc/sshws
cd /etc/sshws
npm install

# Cria serviço systemd para o SSHWS
cat > /etc/systemd/system/sshws.service <<EOF
[Unit]
Description=WebSocket SSH
After=network.target

[Service]
ExecStart=/usr/bin/node /etc/sshws/index.js
Restart=always
User=root
Environment=PORT=80

[Install]
WantedBy=multi-user.target
EOF

# Inicia o WebSocket
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable sshws
systemctl start sshws

# Configura Nginx (opcional - camuflagem site)
rm /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/ws <<EOF
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

ln -s /etc/nginx/sites-available/ws /etc/nginx/sites-enabled/ws
systemctl restart nginx

# Instala BadVPN (UDP tunel)
cd /opt
wget https://github.com/ambrop72/badvpn/archive/refs/heads/master.zip -O badvpn.zip
unzip badvpn.zip && mv badvpn-* badvpn
cd badvpn
cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 .
make install

# Inicia o BadVPN em background na porta 7300
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# Script de criação de usuários SSH
cat > /usr/bin/addusuario <<EOF
#!/bin/bash
echo "Usuário SSH"
read -p "Usuário: " user
read -p "Senha: " pass
read -p "Dias válido: " dias

useradd -M -s /bin/false \$user
echo "\$user:\$pass" | chpasswd
chage -E \$(date -d "+\$dias days" +%F) \$user

echo "Usuário criado:"
echo "Usuário: \$user"
echo "Senha : \$pass"
echo "Validade: \$dias dias"
EOF

chmod +x /usr/bin/addusuario

echo ""
echo "----------------------------------------"
echo "INSTALAÇÃO FINALIZADA!"
echo "Use o comando: addusuario"
echo "SSH porta: 22"
echo "WebSocket porta: 80"
echo "BadVPN rodando na porta 7300"
echo "----------------------------------------"