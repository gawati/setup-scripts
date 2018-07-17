function readconfig {
  VERSION="${2}"
  ZIP_SERVER="gawati-profiles-fe-${VERSION}.tbz"

  installer_init "${1}" "${ZIP_SERVER}" "http://dl.gawati.org/${PKGSRC}/${ZIP_SERVER}"

  export SERVER_HOME="${INSTANCE_PATH}/portal"
  export SERVER_PORT="`iniget \"${INSTANCE}\" port`"
  export UI_VERSION="`iniget \"${INSTANCE}\" ui_version`"

  ZIP_UI="gawati-user-profiles-ui-${UI_VERSION}.tbz"

  vardebug SERVER_HOME SERVER_PORT
  setvars SERVER_HOME SERVER_PORT
  }

function install {
  [ -e "${SERVER_HOME}" ] && {
    message 2 "Destination >${SERVER_HOME}< for >${INSTANCE}< already existing. Skipping."
    return
    }

  OSinstall mongodb 1
  OSinstall mongodb-server 1

  CFGSRC="${INSTALLER_HOME}/01"
  vardebug CFGSRC

  message 1 "Installing to folder >${SERVER_HOME}< as user >${RUNAS_USER}<."

  sudo -u "${RUNAS_USER}" bash -s "${INSTALLSRC}" "${SERVER_HOME}" <<'EndOfScriptAsRUNAS_USER'
    echo "Running as `id`"

    export INSTALLSRC="${1}"
    export SERVER_HOME="${2}"

    mkdir -p "${SERVER_HOME}"
    cd "${SERVER_HOME}"

    tar -xjf "${INSTALLSRC}"
EndOfScriptAsRUNAS_USER

  cfgwrite "${CFGSRC}/variables.env" "${SERVER_HOME}" "variables.env"

  echo "${OPTIONS}" | grep -i daemon >/dev/null && {
    cfgwrite "${CFGSRC}/gawatiuserprofiles.service" "/etc/systemd/system" "${RUNAS_USER}_server.service"
    systemctl daemon-reload
    systemctl enable mongod
    systemctl restart mongod
    systemctl enable ${RUNAS_USER}_server
    systemctl restart ${RUNAS_USER}_server
    }

  UI_DLFILE="${DOWNLOADFOLDER}/${ZIP_UI}"
  [ -e ${UI_DLFILE} ] || download "${UI_DLFILE}" "http://dl.gawati.org/dev/${ZIP_UI}"
  [ -e "/var/www/html/${GAWATI_URL_ROOT}/profiles" ] || {
    mkdir -p "/var/www/html/${GAWATI_URL_ROOT}/profiles"
    }

  tar -C "/var/www/html/${GAWATI_URL_ROOT}/profiles" -xjf "${UI_DLFILE}"
  chown -R root:apache "/var/www/html/${GAWATI_URL_ROOT}/profiles"
  }

