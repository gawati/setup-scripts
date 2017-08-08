#!/bin/bash

function install {
  VERSION="${2}"
  installer_init "${1}" "" ""
  
  CFGFILES="10-gawati.conf"
  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/httpd/conf.d"

  export GAWATI_URL_ROOT="`iniget \"${INSTANCE}\" GAWATI_URL_ROOT`"
  export GAWATI_URL_ROOT_="`echo ${GAWATI_URL_ROOT} | tr . _`"
  export EXIST_BE_URL="`iniget \"${INSTANCE}\" EXIST_BE_URL`"

  for FILE in ${CFGFILES} ; do
    cfgwrite "${CFGSRC}/${FILE}" "${CFGDST}"
    done
  }

