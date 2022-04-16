#####  INSTALL LINUX CLIENT 

# REPO
curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo

# INSTALL CENTOS 7
yum install vim epel-release -y && yum install wireguard-tools wireguard-dkms qrencode -y

# INSTALL DEBIAN 11
apt install -y wireguard-dkms wireguard-tools resolvconf

# UPDATE
yum update -y

# Назначаем переменную рабочего интерфейса сетевухи в которой есть инет, чтобы вставить в конфиг
LAN="$(ip -o -4 route show to default | awk '{print $5}')"
IP="$(hostname -I | awk '{print $1}')"
PORT=36666

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

#### НА СЕРВЕРЕ
# После добавления ключа на сервере, нужно его перезагрузить
systemctl start wg-quick@wg0-server

# Прверяем что клиенты подключились
wg

# Выглядит так
#interface: wg0-server
#  public key: RBr9xD/bJdfgfdgfdgfdg
#  private key: (hidden)
#  listening port: 36666

#peer: WDSv9Omvfh5xvyfdgdfgfdgdfg
#  endpoint: 89.22.54.66:35676
#  allowed ips: 10.0.0.5/32
#  latest handshake: 56 seconds ago
#  transfer: 583.81 KiB received, 4.48 MiB sent

#### НА КЛИЕНТЕ теперь поднимаем интерфейс

# UP intarface на Linux машине.
wg-quick up wg-client

sudo wg
