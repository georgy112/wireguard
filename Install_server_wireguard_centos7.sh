#!/bin/sh
# Обновляемся
yum update -y

# Отключаем firewalld
systemctl stop firewalld
systemctl disable firewalld

# Ставим репо
curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo

# Ставим ПО
yum install epel-release -y && yum install wireguard-tools wireguard-dkms qrencode resolveconf -y

# Проверям утсновку модуля ядра
modprobe wireguard && lsmod | grep wireguard

# Включите форвардинг пакетов между интерфейсами
cat > /etc/sysctl.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
EOF

# Проверяем вывод
sysctl -p

# Создаем директории Wireguard
mkdir -p /etc/wireguard && cd /etc/wireguard

# Генерим ключи сервера
wg genkey | tee server-private.key | wg pubkey > server-public.key

# Генерим ключи 1ого клиента
wg genkey | tee client-private.key | wg pubkey > client-public.key

# Генерим ключи 2ого клиента
wg genkey | tee client2-private.key | wg pubkey > client-public.key

# Назначаем переменные, чтобы ключи сами добавились в конфиг
SERVER_PRIVATE_KEY="$(cat /etc/wireguard/server-private.key)"
CLIENT_PUBLIC_KEY="$(cat /etc/wireguard/client-public.key)"
# Вывел отдельно, для проверки в конце на предмет правильного старта Wireguard
PORT=36666

# Выставляем правильные права на файлы
chmod 600 ./*-private.key

# Создаем конфиг сервера
touch /etc/wireguard/wg0-server.conf

# Назначаем переменную рабочего интерфейса сетевухи в которой есть инет, чтобы вставить в конфиг
LAN="$(ip -br link show | grep -v lo | grep -v wg | grep -v tunsnx | grep -v wl | grep -v flannel | grep -v cni0 | grep -v veth | awk '{print $1}')"

# Проверяем что интерфейсов сетевухи должен быть один
echo $LAN


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
EOF

# Запускаем wireguard, где wg0-server - этот интефейс создается согласно наименованию конфига здесь /etc/wireguard/wg0-server.conf
systemctl start wg-quick@wg0-server

# Его автостарт
systemctl enable wg-quick@wg0-server

# Проверяем стартанул ли наш vpn-интерфейс
ip a show wg0-server

# Проверяем туннель
wg show
