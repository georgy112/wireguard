####   Wireguard

yum install kernel-devel
 
PrivateKey = <~Aоде~@жимое private-server.key>   GGO3jqI8TKRaXcxwUyvEBK1RspvK6HoorTUqPA8mmGs=
[Peer]
PublicKey = <~Aоде~@жимое public-client.key>   vlOt0/1fQvjxD5N59s6lrRxvJLJjVmHOYYIN4PsWKwI=

PrivateKey = <~Aоде~@жимое private-client.key>  ICnz1JC9NM6npGFfqb+gxPKlxgmuxRSp6R0NQ6gyE3k=
[Peer]
PublicKey = <~Aоде~@жимое public-server.key>  I7GYakRDQogzYNVlKGLERi+261MqHRD27xzZEyjFNwQ=



Ошибка: Apr 12 14:45:46 oracle-vm-01 wg-quick[30375]: RTNETLINK answers: Operation not supported.
https://itbru.ru/index.php/2020/01/30/wireguard-rtnetlin/


dkms build wireguard/1.0.20211208
Error! Your kernel headers for kernel 3.10.0-1160.49.1.el7.x86_64 cannot be found at /lib/modules/3.10.0-1160.49.1.el7.x86_64/build or /lib/modules/3.10.0-1160.49.1.el7.x86_64/source.
Please install the linux-headers-3.10.0-1160.49.1.el7.x86_64 package or use the --kernelsourcedir option to tell DKMS where it's located.

#### Управление:
sudo systemctl restart wg-quick@wg0-server
sudo wg show
sudo wg show wg0-server

sudo wg-quick up wg0-server
wg-quick down wg0-server

Автостарт интерфейса:
sudo systemctl enable wg-quick@wg0-server



sudo vim /etc/wireguard/wg0-server.conf


ens3

172.21.0.0/16


PrivateKey = ICnz1JC9NM6npGFfqb+gxPKlxgmuxRSp6R0NQ6gyE3k=

Порядко в виндовом клиенте:
cat public-client.key
cat public-server.key


10.0.0.0/8, 172.16.0.0/12 или 192.168.0.0/16