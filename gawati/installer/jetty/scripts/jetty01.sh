#!/bin/bash

function deploy_jetty {
  UNPACKFOLDER="${1}"
  DOWNLOADFILE="${2}"
  vardebug UNPACKFOLDER DOWNLOADFOLDER
  pushd "${DEPLOYMENTFOLDER}" >/dev/null ||  bail_out 1 "Failed to enter folder >${1}<."
  [ -e "${UNPACKFOLDER}" ] && {
    message 1 "Deployment destination folder >${UNPACKFOLDER}< already exists. Skipping."
    return
    }
  tar -xzf "${DOWNLOADFILE}" || bail_out 1 "Error while extracting >${DOWNLOADFILE}<."
  popd >/dev/null
  }


function install {
  VERSION="${2}"
  installer_init "${1}" "jetty-distribution-${VERSION}.tar.gz" "http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${VERSION}/jetty-distribution-${VERSION}.tar.gz"
  vardebug INSTANCE OUTFILE INSTALLSRC RUNAS_USER INSTANCE_FOLDER VERSION OPTIONS

  EXIST_HOME="${INSTANCE_PATH}"
  vardebug EXIST_HOME

  UNPACKFOLDER="${DEPLOYMENTFOLDER}/jetty-distribution-${VERSION}"
  deploy_jetty "${UNPACKFOLDER}" "${INSTALLSRC}"

  JETTY_BASE="`echo eval echo ${INSTANCE_FOLDER} | sudo -u \"${RUNAS_USER}\" bash -s`" || bail_out 1 "Failed to determine instance folder for >${INSTANCE}<."
  vardebug JETTY_BASE
  JETTY_PORT="`iniget \"${INSTANCE}\" port`"
  vardebug JETTY_PORT
  JETTY_SPORT="`iniget \"${INSTANCE}\" sslport`"
  vardebug JETTY_SPORT
  JETTY_MODULES="`iniget \"${INSTANCE}\" modules`"
  vardebug JETTY_MODULES

  [ -e "${JETTY_BASE}" ] && {
    message 1 "Destination >${EXIST_HOME}< for >${INSTANCE}< already existing. Skipping."
    return
    }

  message 1 "Installing to jetty-base folder >${INSTANCE_FOLDER}< as user >${RUNAS_USER}<."

  sudo -u "${RUNAS_USER}" bash -s "${INSTANCE}" "${JETTY_BASE}" "${UNPACKFOLDER}" "${JETTY_PORT}" "${JETTY_SPORT}" "${JETTY_MODULES}" <<'EndOfScriptAsRUNAS_USER'
    export INSTANCE="${1}"
    export JETTY_BASE="${2}"
    export UNPACKFOLDER="${3}"
    export JETTY_PORT="${4}"
    export JETTY_SPORT="${5}"
    export JETTY_MODULES="${6}"

    function set_jettyini_property {
      PROPERTY="${1}"
      VALUE="${2}"
      FILE="${JETTY_BASE}/start.d/${3}.ini"

      [ -f "${FILE}" ] && sed -i "s%^.*${PROPERTY}=.*$%${PROPERTY}=${VALUE}%" "${FILE}" || echo "Failed to set >${PROPERTY}< to >${VALUE}< in >${FILE}<"
    }

    echo 'JAVA_HOME="`readlink -f /usr/bin/java | sed "s:/bin/java::"`"' >~/.javarc
    echo 'export JAVA_HOME' >>~/.javarc
    grep '\.javarc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.javarc ] && . ~/.javarc' >>~/.bash_profile ; }
    . ~/.javarc

    echo "JETTY_BASE='${JETTY_BASE}'" >~/.jettyrc
    echo "JETTY_HOME='${JETTY_BASE}/jettyserver'" >>~/.jettyrc
    echo "export JETTY_HOME" >>~/.jettyrc
    echo "export JETTY_BASE" >>~/.jettyrc
    grep '\.jettyrc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.jettyrc ] && . ~/.jettyrc' >>~/.bash_profile ; }
    . ~/.jettyrc

    [ -e "${JETTY_BASE}/logs" ] || mkdir -p "${JETTY_BASE}/logs"
    [ -e "${JETTY_BASE}/run" ] || mkdir -p "${JETTY_BASE}/run"
    [ -e "${JETTY_BASE}/tmp" ] || mkdir -p "${JETTY_BASE}/tmp"

    cd "${JETTY_BASE}" || exit 1
    [ -e "jettyserver" ] || ln -s "${UNPACKFOLDER}" jettyserver
    java -jar "${JETTY_HOME}/start.jar" --create-startd
    java -jar "${JETTY_HOME}/start.jar" --add-to-start="${JETTY_MODULES}"
    set_jettyini_property "jetty.http.host" "127.0.0.1" "http"
    set_jettyini_property "jetty.http.port" "${JETTY_PORT}" "http"
    set_jettyini_property "jetty.httpConfig.securePort" "${JETTY_SPORT}" "server"
    set_jettyini_property "jetty.console-capture.dir" "${JETTY_BASE}/logs" "console-capture"
EndOfScriptAsRUNAS_USER

  echo "${OPTIONS}" | grep -i daemon >/dev/null && {
    JETTY_HOME="${JETTY_BASE}/jettyserver"
    JETTY_DEFCONFIG="/etc/default/${INSTANCE}"
    JETTY_INIT="/etc/init.d/${INSTANCE}"
    vardebug JETTY_BASE JETTY_HOME JETTY_DEFCONFIG JETTY_INIT

    message 1 "Installing jetty instance in >${JETTY_BASE}< as daemon named >${INSTANCE}< running as user >${RUNAS_USER}<."

    echo "JETTY_USER='${RUNAS_USER}'" >"${JETTY_DEFCONFIG}"
    echo "JETTY_HOME='${JETTY_HOME}'" >>"${JETTY_DEFCONFIG}"
    echo "JETTY_BASE='${JETTY_BASE}'" >>"${JETTY_DEFCONFIG}"
    echo "JETTY_RUN='${JETTY_BASE}/run'" >>"${JETTY_DEFCONFIG}"
    echo "TMPDIR='${JETTY_BASE}/tmp'" >>"${JETTY_DEFCONFIG}"
    chcon -u system_u "${JETTY_DEFCONFIG}"

    cat "${JETTY_HOME}/bin/jetty.sh" >"${JETTY_INIT}"
    chmod 755 "${JETTY_INIT}"
    chcon -u system_u -t initrc_exec_t "${JETTY_INIT}"

    chkconfig --add "${INSTANCE}"
    chkconfig "${INSTANCE}" on
    }
  }

