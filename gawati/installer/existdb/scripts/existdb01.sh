#!/bin/bash

function readconfig {
  VERSION="${2}"
  installer_init "${1}" "eXist-db-setup-${VERSION}.jar" "https://bintray.com/existdb/releases/download_file?file_path=eXist-db-setup-${VERSION}.jar"

  EXIST_HOME="${INSTANCE_PATH}"
  EXIST_DATA="`iniget \"${INSTANCE}\" dataFolder`"
  EXIST_DATA="`echo eval echo ${EXIST_DATA} | sudo -u \"${RUNAS_USER}\" bash -s`" || bail_out 1 "Failed to determine data folder for >${INSTANCE}<."

  EXIST_PORT="`iniget \"${INSTANCE}\" port`"
  EXIST_SPORT="`iniget \"${INSTANCE}\" sslport`"
  vardebug EXIST_HOME EXIST_DATA EXIST_PORT EXIST_SPORT
  setvars EXIST_HOME EXIST_DATA EXIST_PORT EXIST_SPORT
  }


function install {
  [ -e "${EXIST_HOME}" ] && {
    message 2 "Destination >${EXIST_HOME}< for >${INSTANCE}< already existing. Skipping."
    return
    }

  OSinstall xmlstarlet 1

  export adminPasswd="`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`"
  setvars adminPasswd

  addsummary "Admin Password of existDB instance ${INSTANCE}: >${adminPasswd}<"

  message 1 "Installing to folder >${INSTANCE_FOLDER}< as user >${RUNAS_USER}<."

  sudo -u "${RUNAS_USER}" bash -s "${INSTANCE}" "${EXIST_HOME}" "${INSTALLSRC}" "${EXIST_PORT}" "${EXIST_SPORT}" "${EXIST_DATA}" "${adminPasswd}" <<'EndOfScriptAsRUNAS_USER'
    echo "Running as `id`"

    export INSTANCE="${1}"
    export EXIST_HOME="${2}"
    export INSTALLSRC="${3}"
    export EXIST_PORT="${4}"
    export EXIST_SPORT="${5}"
    export EXIST_DATA="${6}"
    export adminPasswd="${7}"

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
    java -jar "${INSTALLSRC}" -options existdb.options
    sed -i "s%^.*wrapper.app.account=.*$%wrapper.app.account=${USER}%" "${EXIST_HOME}/tools/yajsw/conf/wrapper.conf"
    bin/client.sh --no-gui --local --user admin --xpath "xmldb:change-user('admin','${adminPasswd}','dba','/db')" >/dev/null
    echo -e "\033[0;32mYour eXistDB instance >${INSTANCE}< has admin password: >${adminPasswd}<\033[0m"
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
      cat "/etc/init.d/${INSTANCE}" | sed 's%^\(.*/usr/lib/jvm/jre-1.8.0-openjdk\).*\(/jre/bin/java.*\)$%\1\2%g' > /tmp/initfile
      cat /tmp/initfile > "/etc/init.d/${INSTANCE}"
      rm /tmp/initfile
      chcon -u system_u "/etc/init.d/${INSTANCE}"
      chkconfig --add "${INSTANCE}"
      chkconfig "${INSTANCE}" on
      }

    message 1 "Waiting for service >${INSTANCE}< to come up."
    systemctl restart "${INSTANCE}" 
    timeout 20s grep -q "Service ${INSTANCE} started" <(tail -n 5 -f /var/log/messages) && {
      message 1 ">${INSTANCE}< started as service."
      } || {
      message 3 ">${INSTANCE}< failed to start as service."
      }

    maxwait=20
    i=0
    message 4 "Waiting up to ${maxwait} seconds for >${INSTANCE}< to start answering requests."
    until curl -s -o /dev/null -w '%{http_code}' "http://localhost:${EXIST_PORT}"; do
      message 4 "${i}.. "
      ((i++))
      [ $i -gt ${maxwait} ] && break
      sleep 1
      done

    [ $i -gt ${maxwait} ] && {
      bail_out ">${INSTANCE}< fails to service requests."
      } || {
      message 1 ">${INSTANCE}< responds to requests."
      }
    }
  }

