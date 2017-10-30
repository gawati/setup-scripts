OSinstall httpd 1
OSinstall mod_ssl 1

function install {
  VERSION="${2}"
  installer_init "${1}" "" ""
  
  CFGFILES="00-http.conf ssl.conf userdir.conf welcome.conf"
  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/httpd/conf.d"

  for FILE in ${CFGFILES} ; do
    cfgwrite "${CFGSRC}/${FILE}" "${CFGDST}"
    done

  systemctl enable httpd
  systemctl restart httpd

  firewall-cmd --zone=public --add-port=80/tcp --permanent
  firewall-cmd --zone=public --add-port=443/tcp --permanent
  firewall-cmd --reload
  }

