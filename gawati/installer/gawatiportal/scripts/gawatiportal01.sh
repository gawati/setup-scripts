#!/bin/bash

function install {
  VERSION="${2}"
  installer_init "${1}" "" ""
  
  CFGFILES="10-gawati.conf"
  CFGSRC="${DOWNLOADFOLDER}/installer/${INSTALLER_NAME}/scripts/01"
  CFGDST="/etc/httpd/conf.d"

  GAWATI_URL_ROOT="`iniget \"${INSTANCE}\" GAWATI_URL_ROOT`"
  EXIST_BE_URL="`iniget \"${INSTANCE}\" EXIST_BE_URL`"

  for FILE in ${CFGFILES} ; do
    cfgwrite "${CFGSRC}/${FILE}" "${CFGDST}"
    done
  }

