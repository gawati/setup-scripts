#!/bin/bash

function install {
  VERSION="${2}"
  installer_init "${1}" "" ""
  
  CFGFILES="00-http.conf ssl.conf userdir.conf welcome.conf"
  CFGSRC="${DOWNLOADFOLDER}/installer/${INSTALLER_NAME}/scripts/01"
  CFGDST="/etc/httpd/conf.d"

  OSinstall httpd 1
  OSinstall mod_ssl 1

  for FILE in ${CFGFILES} ; do
    cfgwrite "${CFGSRC}/${FILE}" "${CFGDST}"
    done
  }

