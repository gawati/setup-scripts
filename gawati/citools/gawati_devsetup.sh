stty onlcr
cd
ip addr show dev eth0
firewall-cmd --zone=trusted --change-interface=eth0 --permanent
curl https://gawati.org/setup -o setup
chmod 755 setup
./setup
./setup
reboot
