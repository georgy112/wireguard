#!/bin/sh

# REPO
curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo

# INSTALL
yum install vim epel-release -y && yum install wireguard-tools wireguard-dkms qrencode -y

# UPDATE
yum update -y

# Check module core
modprobe wireguard && lsmod | grep wireguard

# FORWARDING PACKET
cat > /etc/sysctl.conf <<EOF
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
EOF

# FIREWALLD
# Останавливаем файрвол, также ниже будет еще iptables в конфиге.
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --zone=public --add-port=36666/udp
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --reload

# WAREGUARD
# Создаем директории Wireguard
mkdir -p /etc/wireguard && cd /etc/wireguard

# Генерим ключи сервера
wg genkey | tee server-private.key | wg pubkey > server-public.key

# Генерим ключи 1ого клиента
wg genkey | tee client-private.key | wg pubkey > client-public.key

# Генерим ключи 2ого клиента
wg genkey | tee client2-private.key | wg pubkey > client2-public.key

# Генерим ключи 3ого клиента
wg genkey | tee client3-private.key | wg pubkey > client3-public.key

# Назначаем переменные, чтобы ключи сами добавились в конфиг
SERVER_PRIVATE_KEY="$(cat /etc/wireguard/server-private.key)"
CLIENT_PUBLIC_KEY="$(cat /etc/wireguard/client-public.key)"
CLIENT_PUBLIC_KEY1="$(cat /etc/wireguard/client2-public.key)"
CLIENT_PUBLIC_KEY2="$(cat /etc/wireguard/client3-public.key)"
CLIENT_PRIVATE_KEY="$(cat /etc/wireguard/client-private.key)"
SERVER_PUBLIC_KEY="$(cat /etc/wireguard/server-public.key)"
# Вывел отдельно, для проверки в конце на предмет правильного старта Wireguard
PORT=36666

# Выставляем правильные права на файлы
chmod 600 ./*-private.key

# Создаем конфиг сервера
touch /etc/wireguard/wg0-server.conf

# Назначаем переменную рабочего интерфейса сетевухи в которой есть инет, чтобы вставить в конфиг
LAN="$(ip -br link show | grep -v lo | grep -v wg | grep -v tunsnx | grep -v wl | grep -v flannel | grep -v cni0 | grep -v veth | awk '{print $1}')"
IP="$(hostname -I | awk '{print $1}')"

# Проверяем что интерфейсов сетевухи должен быть один
echo $LAN

#####  INSTALL SERVER
# Наполняем конфиг, правила iptables обязательны, если не включить маскарадинг, то инета не будет, хотя вы и подключитесь
cat > /etc/wireguard/wg0-server.conf <<EOF
[Interface]
Address = 10.0.0.1/24
PrivateKey = $SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $LAN -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $LAN -j MASQUERADE
ListenPort = $PORT
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
PublicKey = $CLIENT_PUBLIC_KEY1
AllowedIPs = 10.0.0.3/32
PublicKey = $CLIENT_PUBLIC_KEY2
AllowedIPs = 10.0.0.4/32
EOF

# Запускаем wireguard, где wg0-server - этот интефейс создается согласно наименованию конфига здесь /etc/wireguard/wg0-server.conf
systemctl enable wg-quick@wg0-server && systemctl start wg-quick@wg0-server

# Проверяем запуск интерфейса
wg

# Проверяем стартанул ли наш vpn-интерфейс
ip a show wg0-server

