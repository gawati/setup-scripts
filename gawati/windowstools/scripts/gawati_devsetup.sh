firewall-cmd --zone=trusted --change-interface=eth0 --permanent
curl http://dl.gawati.org/dev/setup -o setup
chmod 755 setup
./setup | tee /var/log/setup.log
./setup | tee -a /var/log/setup.log
reboot && exit