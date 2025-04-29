#!/bin/bash
clear
#--------------------------
# PAINEL SSHPLUS WEB
# DEV: CRAZY AND KIOOPOL
# CANAL TELEGRAM: @SSHPLUS
#--------------------------

# - Cores
RED='\033[1;31m'
YELLOW='\033[1;33m'
SCOLOR='\033[0m'

# - Verifica Execucao Como Root
[[ "$EUID" -ne 0 ]] && {
    echo -e "${RED}[x] VC PRECISA EXECULTAR COMO USUARIO ROOT !${SCOLOR}"
    exit 1
}

# - Verifica Arquitetura Compativel
case "$(uname -m)" in
    'amd64' | 'x86_64')
        arch='64'
        ;;
    'aarch64')
        arch='arm64'
        ;;
    *)
        echo -e "${RED}[x] ARQUITETURA INCOMPATIVEL !${SCOLOR}"
        exit 1
        ;;
esac

# - Verifica OS Compativel
if grep -qs "ubuntu" /etc/os-release; then
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
    [[ "$os_version" -lt 2004 ]] && {
        echo -e "${RED}[x] VERSAO DO UBUNTU INCOMPATIVEL !\n${YELLOW}[!] REQUER UBUNTU 20.04 OU SUPERIOR !${SCOLOR}"
        exit 1
    }
elif [[ -e /etc/debian_version ]]; then
	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	[[ "$os_version" -lt 11 ]] && {
        echo -e "${RED}[x] VERSAO DO DEBIAN INCOMPATIVEL !\n${YELLOW}[!] REQUER DEBIAN 11 OU SUPERIOR !${SCOLOR}"
        exit 1
    }
else
    echo -e "${RED}[x] OS INCOMPATIVEL !\n${YELLOW}[!] REQUER DISTROS BASE DEBIAN/UBUNTU !${SCOLOR}"
    exit 1
fi

# - Atualiza Lista/Pacotes/Sistema
dpkg --configure -a
apt update -y && apt upgrade -y
apt install cron unzip python3 curl -y

# - Desabilita ipv6 e ajusta o sysctl
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf && sysctl -p
sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -p
echo 'net.ipv6.conf.all.disable_ipv6 = 1' > /etc/sysctl.d/70-disable-ipv6.conf
sysctl -p -f /etc/sysctl.d/70-disable-ipv6.conf

# - Execulta instalador
[[ -e install-painel ]] && rm install-painel
wget sshplus.xyz/scripts/${arch}/install-painel
chmod +x install-painel
[[ $(systemctl | grep -ic fuse) != '0' ]] && ./install-painel || ./install-painel --appimage-extract-and-run
ln -s /opt/sshplus_painel/main_painel /bin/painel > /dev/null 2>&1
rm install-painel > /dev/null 2>&1