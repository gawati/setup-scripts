function readconfig {
  VERSION="${2}"
  ZIP_CLIENT="gawati-editor-ui-${VERSION}.zip"

  installer_init "${1}" "${ZIP_CLIENT}" "http://dl.gawati.org/${PKGSRC}/${ZIP_CLIENT}"
  
  export GAWATI_URL_ROOT="`iniget \"${INSTANCE}\" GAWATI_URL_ROOT`"
  export GAWATI_URL_ROOT_="`echo ${GAWATI_URL_ROOT} | tr . _`"
  export GAWATI_URL_ROOT_ESC="`echo ${GAWATI_URL_ROOT} | sed 's%\.%\\\.%g'`"
  export EXIST_CL_URL="`iniget \"${INSTANCE}\" EXIST_CL_URL`"
  export KC_REALM="`iniget \"options" kc_realm`"
  export KC_URL="`iniget \"options" kc_authurl`"
  export KC_SECRET="`iniget \"options" kc_secret`"

  vardebug GAWATI_URL_ROOT GAWATI_URL_ROOT_ GAWATI_URL_ROOT_ESC EXIST_CL_URL KC_REALM KC_URL KC_SECRET
  setvars GAWATI_URL_ROOT GAWATI_URL_ROOT_ GAWATI_URL_ROOT_ESC EXIST_CL_URL KC_REALM KC_URL KC_SECRET
  }

function install {
  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/httpd/conf.d"
  vardebug CFGSRC CFGDST

  addtohosts "${MainIP}" "edit.${GAWATI_URL_ROOT}"

  OSinstall unzip 1


  #cfgwrite "${CFGSRC}/10-edit.gawati.conf" "${CFGDST}" "10-edit.${GAWATI_URL_ROOT}.conf"
  cfgwrite "${CFGSRC}/10-data.gawati.conf" "${CFGDST}" "10-data.${GAWATI_URL_ROOT}.conf"

  EDITROOT="/var/www/html/edit.${GAWATI_URL_ROOT}"
  vardebug EDITROOT
  [ -e "${EDITROOT}" ] || {
    mkdir -p "${EDITROOT}"
    chown root:apache "${EDITROOT}"
    }

  DSTOBJ="/etc/httpd/logs/edit.${GAWATI_URL_ROOT}"
  vardebug DSTOBJ
  [ -e "${DSTOBJ}" ] || {
    mkdir -p "${DSTOBJ}"
    chown root:apache "${DSTOBJ}"
    chmod 770 "${DSTOBJ}"
    }

  [ -f "${DOWNLOADFOLDER}/${ZIP_CLIENT}" ] || bail_out "Client package not available at >${DOWNLOADFOLDER}/${ZIP_CLIENT}<"
  unzip -q "${DOWNLOADFOLDER}/${ZIP_CLIENT}" -d "${EDITROOT}"

  systemctl restart httpd
  setsebool -P httpd_can_network_connect true
  }

