#####  INSTALL CLIENT

# REPO
curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo

# INSTALL
yum install vim epel-release -y && yum install wireguard-tools wireguard-dkms qrencode -y

# UPDATE
yum update -y

# Назначаем переменную рабочего интерфейса сетевухи в которой есть инет, чтобы вставить в конфиг
LAN="$(ip -br link show | grep -v lo | grep -v wg | grep -v tunsnx | grep -v wl | grep -v flannel | grep -v cni0 | grep -v veth | awk '{print $1}')"
IP="$(hostname -I | awk '{print $1}')"

# Наполняем конфиг
cat > /etc/wireguard/wg-client.conf <<EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = $CLIENT_PRIVATE_KEY
[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $IP:$PORT
PersistentKeepalive = 15
EOF

chmod 600 client.conf && chmod 600 wg0-server.conf

# UP intarface
wg-quick up wg-client

# Check intarface
wg
