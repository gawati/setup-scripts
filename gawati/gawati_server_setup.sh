#!/bin/bash
trap "exit 1" TERM

[ '0' -eq "`id -ur`" ] || {
  echo 'This installer must be run as root.'
  exit 1
  }

COLOR_OFF='\033[0m'
COLOR_0='\033[0m'
COLOR_1='\033[0;32m'
COLOR_2='\033[0;33m'
COLOR_3='\033[0;31m'
COLOR_4='\033[0;96m'

DEBUG=1

function message {
  [ "$#" -gt 2 ] && {
    [ "${3}" -ge "${DEBUG}" ] && return 0
    }
  COLOR_ON="`eval echo \$\{COLOR_${1}\}`"
  echo -e "${COLOR_ON}${2}${COLOR_OFF}"
  }

function bail_out {
  message 3 "${2}"
  kill -s TERM ${MYPID}
  }

function vardebug {
  for VARIABLE in $* ; do
    message 4 "${VARIABLE}: >${!VARIABLE}<" 2
    done
  }

function ensureFolder {
  [ -d "${1}" ] && return 0
  [ -e "${1}" ] && bail_out 1 "Destination >${1}< in use, but not a folder."
  mkdir -p "${1}"
  }

function iniget {
  crudini --get "${INIFILE}" "${1}" "${2}" || bail_out 1 "Parameter >${2}< not defined for >${1}< in >${INIFILE}<."
  }

function download {
  message 1 "Starting download of >${1}<. This may take a moment."
  wget -nv -c "${2}" -O "${1}" || {
    rm "${1}"
    return 1
    }
  }

function install {
  rpm -q "${1}" >/dev/null 2>&1 && {
    message 1 ">${1}< already installed."
    return 0
    }
  message 4 "Installing >${1}<..." 1
  yum -q -y install "${1}" || bail_out 1 "Failed to install package >${1}<."
  message 1 "Installed package >${1}<."
  }

MYPID=$$
TARGET="${1:-dev}"
INIFILE="${HOME}/${TARGET}.ini"
vardebug INIFILE

[ -f "${INIFILE}" ] || {
  download "${INIFILE}" "https://github.com/gawati/setup-scripts/raw/master/gawati/ini/${TARGET}.ini" || message 2 "Failed to download an installation template for >${TARGET}< at Gawati."
  message 1 "Please verify installation parameters in >${INIFILE}<."
  message 1 "Then rerun ${0} to install."
  exit 0
  }

[ -f "${INIFILE}" ] || bail_out 1 "No installation template file at >${INIFILE}<."
message 1 "Reading installation instructions from >${INIFILE}<."

TEMP="`crudini --get \"${INIFILE}\" options debug 2>/dev/null`" && DEBUG="${TEMP}"
PACKAGES="`crudini --get \"${INIFILE}\" options installPackages`"
vardebug DEBUG PACKAGES

for PACKAGE in `echo ${PACKAGES}` ; do
  install "${PACKAGE}"
  done


DOWNLOADFOLDER="`iniget options downloadFolder`"
DEPLOYMENTFOLDER="`iniget options deploymentFolder`"
ensureFolder "${DOWNLOADFOLDER}"
ensureFolder "${DEPLOYMENTFOLDER}"

TASKS="`crudini --get \"${INIFILE}\" | grep -v options`"
declare -A RESOURCES
declare -A INSTALLS

for TASK in ${TASKS} ; do
  vardebug TASK
  TYPE="`iniget "${TASK}" type`"
  vardebug TYPE
  [ "${TYPE}" = "resource" ] && RESOURCES+=(["${TASK}"]="`iniget \"${TASK}\" download`")
  [ "${TYPE}" = "install" ] && INSTALLS+=(["${TASK}"]="`iniget \"${TASK}\" resources`")
  done

pushd "${DOWNLOADFOLDER}" >/dev/null || bail_out 1 "Failed to enter folder >${DOWNLOADFOLDER}<."

for RESOURCE in ${!RESOURCES[@]} ; do
  vardebug RESOURCE
  OUTFILE="`echo ${RESOURCES[$RESOURCE]} | cut -d ' ' -f 1`"
  URL="`echo ${RESOURCES[$RESOURCE]} | cut -d ' ' -f 2-`"
  vardebug OUTFILE URL
  [ -f "${OUTFILE}" ] || {
    download "${OUTFILE}" "${URL}" || bail_out 2 "Failed to download >${OUTFILE}< for resource >${RESOURCE}< from >${URL}<."
    }
  done

popd >/dev/null


# Installer section


function set_environment_java {
  echo 'JAVA_HOME="`readlink -f /usr/bin/java | sed "s:/bin/java::"`"' >~/.javarc
  echo 'export JAVA_HOME' >>~/.javarc
  grep '\.javarc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.javarc ] && . ~/.javarc' >>~/.bash_profile ; }
  . ~/.javarc
  }

function iniget_installer {
  INSTANCE="${1}"
  RESOURCE="${INSTALLS[$INSTANCE]}"
  #vardebug INSTANCE RESOURCE
  OUTFILE="`echo ${RESOURCES[$RESOURCE]} | cut -d ' ' -f 1`"
  INSTALLSRC="${DOWNLOADFOLDER}/${OUTFILE}"
  #vardebug OUTFILE INSTALLSRC

  RUNAS_USER="`iniget \"${INSTANCE}\" user`"
  #vardebug RUNAS_USER
  INSTANCE_FOLDER="`iniget \"${INSTANCE}\" instanceFolder`"
  #vardebug INSTANCE_FOLDER
  INSTANCE_PATH="`echo eval echo ${INSTANCE_FOLDER} | sudo -u \"${RUNAS_USER}\" bash -s`" || bail_out 1 "Failed to determine instance folder for >${INSTANCE}<."
  #vardebug INSTANCE_PATH
  OPTIONS="`crudini --get \"${INIFILE}\" \"${INSTANCE}\" options`"
  #vardebug OPTIONS
  }

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


function install_jetty {
  iniget_installer "${1}"
  EXIST_HOME="${INSTANCE_PATH}"
  vardebug INSTANCE RESOURCE OUTFILE INSTALLSRC RUNAS_USER INSTANCE_FOLDER EXIST_HOME OPTIONS

  UNPACKFOLDER="${DEPLOYMENTFOLDER}/`iniget \"${RESOURCE}\" unpackfolder`"
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
  grep "^${RUNAS_USER}:.*" /etc/passwd >/dev/null || useradd "${RUNAS_USER}"

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




# Install eXistdb

function install_existdb {
  iniget_installer "${1}"
  EXIST_HOME="${INSTANCE_PATH}"
  vardebug INSTANCE RESOURCE OUTFILE INSTALLSRC RUNAS_USER INSTANCE_FOLDER EXIST_HOME OPTIONS

  EXIST_DATA="`iniget \"${INSTANCE}\" dataFolder`"
  EXIST_DATA="`echo eval echo ${EXIST_DATA} | sudo -u \"${RUNAS_USER}\" bash -s`" || bail_out 1 "Failed to determine data folder for >${INSTANCE}<."
  vardebug EXIST_DATA

  EXIST_PORT="`iniget \"${INSTANCE}\" port`"
  vardebug EXIST_PORT
  EXIST_SPORT="`iniget \"${INSTANCE}\" sslport`"
  vardebug EXIST_SPORT

  [ -e "${EXIST_HOME}" ] && {
    echo -e "\033[0;32mDestination >${EXIST_HOME}< for >${INSTANCE}< already existing. Skipping.<\033[0m"
    return
    }

  message 1 "Installing to folder >${INSTANCE_FOLDER}< as user >${RUNAS_USER}<."

  grep "^${RUNAS_USER}:.*" /etc/passwd >/dev/null || useradd "${RUNAS_USER}"
  sudo -u "${RUNAS_USER}" bash -s "${INSTANCE}" "${EXIST_HOME}" "${INSTALLSRC}" "${EXIST_PORT}" "${EXIST_SPORT}" "${EXIST_DATA}" <<'EndOfScriptAsRUNAS_USER'
    export INSTANCE="${1}"
    export EXIST_HOME="${2}"
    export INSTALLSRC="${3}"
    export EXIST_PORT="${4}"
    export EXIST_SPORT="${5}"
    export EXIST_DATA="${6}"

    function set_jettyxml_property {
      PROPERTY="${1}"
      VALUE="${2}"

      xmlstarlet -q sel -t -v '/Configure[@id="Server"]/Call[@class="java.lang.System"][@name="setProperty"]/Arg[1]' jetty.xml | grep "^${PROPERTY}$" >/dev/null 2>&1 && {
        xmlstarlet -q ed -P -L -u "/Configure[@id=\"Server\"]/Call[@class=\"java.lang.System\"][@name=\"setProperty\"][Arg=\"${PROPERTY}\"]/Arg[2]" -v "${VALUE}" jetty.xml >/dev/null
        echo "jetty sytem property >${PROPERTY}< was configured as >${VALUE}<"
        } || {
        echo "Adding sytem property >${PROPERTY}< as >${VALUE}<"
        xmlstarlet -q ed -L -s '/Configure[@id="Server"]' -t elem -n NewCall -v "" \
          -a //NewCall -t attr -n "class" -v "java.lang.System" \
          -a //NewCall -t attr -n "name" -v "setProperty" \
          -s //NewCall -t elem -n "Arg" -v "${PROPERTY}" \
          -s //NewCall -t elem -n "Arg" -v "${VALUE}" \
          -r //NewCall -v Call \
          jetty.xml >/dev/null
        }
      }

    function set_yajsm_property {
      PROPERTY="${1}"
      VALUE="${2}"
      FILE="${EXIST_HOME}/tools/yajsw/conf/${3}.conf"

      [ -f "${FILE}" ] && sed -i "s%^.*${PROPERTY} *=.*$%${PROPERTY}=${VALUE}%" "${FILE}" || echo "Failed to set >${PROPERTY}< to >${VALUE}< in >${FILE}<"
      }

    echo 'JAVA_HOME="`readlink -f /usr/bin/java | sed "s:/bin/java::"`"' >~/.javarc
    echo 'export JAVA_HOME' >>~/.javarc
    grep '\.javarc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.javarc ] && . ~/.javarc' >>~/.bash_profile ; }
    . ~/.javarc

    echo "EXIST_HOME='${EXIST_HOME}'" >~/.existrc
    echo 'export EXIST_HOME' >>~/.existrc
    grep '\.existrc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.existrc ] && . ~/.existrc' >>~/.bash_profile ; }
    . ~/.existrc

    echo "JETTY_HOME='${EXIST_HOME}/tools/jetty'" >~/.jettyrc
    echo "export JETTY_HOME" >>~/.jettyrc
    grep '\.jettyrc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.jettyrc ] && . ~/.jettyrc' >>~/.bash_profile ; }
    . ~/.jettyrc

    mkdir -p "${EXIST_HOME}/bin"
    cd "${EXIST_HOME}" || exit 1
    touch bin/setup.sh
    chmod 600 bin/setup.sh
    echo "INSTALL_PATH=${EXIST_HOME}" > existdb.options
    echo "dataDir=${EXIST_DATA}" >> existdb.options
    echo "MAX_MEMORY=2048" >> existdb.options
    echo "cacheSize=256" >> existdb.options
    export adminPasswd="`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`"
    java -jar "${INSTALLSRC}" -options existdb.options
    sed -i "s%^.*wrapper.app.account=.*$%wrapper.app.account=${USER}%" "${EXIST_HOME}/tools/yajsw/conf/wrapper.conf"
    bin/client.sh --no-gui --local --user admin --xpath "xmldb:change-user('admin','${adminPasswd}','dba','/db')" >/dev/null
    echo -e "\033[0;32mYour eXistDB instance >${INSTANCE}< has admin password: >${adminPasswd}<\033[0m"
    #read -n 1 -s -r -p 'Take note of this password for user "admin". Press any key to continue.'
    set_yajsm_property wrapper.ntservice.name "${INSTANCE}" wrapper
    cd "${JETTY_HOME}/etc"
    set_jettyxml_property jetty.port "${EXIST_PORT}"
    set_jettyxml_property jetty.ssl.port "${EXIST_SPORT}"
    exit;
EndOfScriptAsRUNAS_USER

  echo "${OPTIONS}" | grep -i daemon >/dev/null && {
    message 1 "Installing eXistdb instance in >${EXIST_HOME}< as daemon named >${INSTANCE}< running as user >${RUNAS_USER}<."

    export RUN_AS_USER="${RUNAS_USER}"
    cd "${EXIST_HOME}"
    echo N | tools/yajsw/bin/installDaemon.sh >/dev/null

    [ -f "/etc/init.d/${INSTANCE}" ] && {
      chcon -u system_u "/etc/init.d/${INSTANCE}"
      chkconfig --add "${INSTANCE}"
      chkconfig "${INSTANCE}" on
      }
    }
  }




set_environment_java

for INSTANCE in ${!INSTALLS[@]} ; do
  [ "${INSTANCE}" = "" ] && bail_out 1 "Installer instance name empty."
  vardebug INSTANCE
  RESOURCE="${INSTALLS[$INSTANCE]}"
  vardebug RESOURCE
  INSTALLER="install_${RESOURCE}"
  vardebug INSTALLER
  [ "`type -t ${INSTALLER}`" != function ] && bail_out 1 "No installer available for resource type >${RESOURCE}<."
  message 4 "Calling installer >${INSTALLER}<." 2
  "${INSTALLER}" "${INSTANCE}"
  done

