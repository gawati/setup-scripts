function readconfig {
  VERSION="${2}"
  ZIP_SERVER="gawati-portal-fe-${VERSION}.tbz"

  installer_init "${1}" "${ZIP_SERVER}" "http://dl.gawati.org/${PKGSRC}/${ZIP_SERVER}"

  export SERVER_HOME="${INSTANCE_PATH}/portal"

  export SERVER_PORT="`iniget \"${INSTANCE}\" port`"
  export SERVER_APIPORT="`iniget \"${INSTANCE}\" api_port`"

  vardebug SERVER_HOME SERVER_PORT SERVER_APIPORT
  setvars SERVER_HOME SERVER_PORT SERVER_APIPORT
  }

function install {
  [ -e "${SERVER_HOME}" ] && {
    message 2 "Destination >${SERVER_HOME}< for >${INSTANCE}< already existing. Skipping."
    return
    }

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

  echo "${OPTIONS}" | grep -i daemon >/dev/null && {
    cfgwrite "${CFGSRC}/gawatiserver.service" "/etc/systemd/system" "${RUNAS_USER}_server.service"
    cfgwrite "${CFGSRC}/gawaticron.service" "/etc/systemd/system" "${RUNAS_USER}_cron.service"
    systemctl daemon-reload
    systemctl enable ${RUNAS_USER}_server
    systemctl restart ${RUNAS_USER}_server
    systemctl enable ${RUNAS_USER}_cron
    systemctl restart ${RUNAS_USER}_cron
    }
  }

