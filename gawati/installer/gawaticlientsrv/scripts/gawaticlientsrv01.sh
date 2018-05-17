#!/bin/bash

function readconfig {
  VERSION="${2}"
  ZIP_SERVER="gawati-editor-fe-${VERSION}.zip"

  installer_init "${1}" "${ZIP_SERVER}" "http://dl.gawati.org/${PKGSRC}/${ZIP_SERVER}"

  export SERVER_HOME="${INSTANCE_PATH}/portal"
  export SERVER_PORT="`iniget \"${INSTANCE}\" port`"
  export EXIST="`iniget \"${INSTANCE}\" exist | tr '-' '_'`"
  export KC_REALM="`iniget \"options" kc_realm`"
  export KC_URL="`iniget \"options" kc_authurl`"
  export KC_SECRET_CLIENT="`iniget \"options" kc_secret`"

  VARNAME="${EXIST}_LURL"
  export EXIST_URL="${!VARNAME}"

  vardebug SERVER_HOME SERVER_PORT EXIST KC_REALM KC_URL KC_SECRET_CLIENT VARNAME EXIST_URL
  setvars SERVER_HOME SERVER_PORT EXIST KC_REALM KC_URL KC_SECRET_CLIENT
  }

function install {
  [ -e "${SERVER_HOME}" ] && {
    message 2 "Destination >${SERVER_HOME}< for >${INSTANCE}< already existing. Skipping."
    return
    }

  CFGSRC="${INSTALLER_HOME}/01"
  vardebug CFGSRC

  message 1 "Installing to folder >${SERVER_HOME}< as user >${RUNAS_USER}<."

  sudo -u "${RUNAS_USER}" bash -s "${INSTALLSRC}" "${SERVER_HOME}" "${EXIST_URL}" <<'EndOfScriptAsRUNAS_USER'
    echo "Running as `id`"

    export INSTALLSRC="${1}"
    export SERVER_HOME="${2}"
    export EXIST_URL="${3}"

    mkdir -p "${SERVER_HOME}"
    cd "${SERVER_HOME}"

    unzip -q "${INSTALLSRC}"

    sed -i'' "s%\(.*serviceEndPoint[^:]*:\).*%\1 \"${EXIST_URL}/restxq\",%g" configs/dataServer.json
EndOfScriptAsRUNAS_USER

  echo "${OPTIONS}" | grep -i daemon >/dev/null && {
    cfgwrite "${CFGSRC}/gawatiserver.service" "/etc/systemd/system" "${RUNAS_USER}_server.service"
    systemctl daemon-reload
    systemctl enable ${RUNAS_USER}_server
    systemctl restart ${RUNAS_USER}_server
    }
  }

