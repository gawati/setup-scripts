firewall-cmd --zone=trusted --change-interface=eth0 --permanent
curl http://dl.gawati.org/dev/setup -o setup
chmod 755 setup
./setup
./setup
reboot