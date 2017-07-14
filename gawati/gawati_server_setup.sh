#!/bin/bash

[ '0' -eq "`id -ur`" ] || {
  echo 'This installer must be run as root.'
  exit 1
  }

COLOR_STD='\033[0m'
COLOR_NOTE='\033[0;32m'

# Read installation configuration from ~/gawati_server_setup.cfg
# If ~/gawati_server_setup.cfg does not exist, create a default one and exit

[ -f ~/gawati_server_setup.cfg ] || {
echo "~/gawati_server_setup.cfg missing, creating default."
cat << EOF >~/gawati_server_setup.cfg
export JETTY_USER="dev01"
export JETTY_PROJECT="jetty-apps"
export JETTY_PORT="9084"
export JETTY_SPORT="9444"
export EXIST_BACKEND_USER="xstbe"
export EXIST_BACKEND_PORT="10084"
export EXIST_BACKEND_SPORT="10444"
export EXIST_STAGING_USER="xstst"
export EXIST_STAGING_PORT="10083"
export EXIST_STAGING_SPORT="10443"
EOF
echo "Please verify installation parameters in ~/gawati_server_setup.cfg"
echo "Then rerun ${0} to install."
exit
}

. ~/gawati_server_setup.cfg

: <<TESTVARIABLES || exit 1
${JETTY_USER?}
${JETTY_PROJECT?}
${JETTY_PORT?}
${JETTY_SPORT?}
${EXIST_BACKEND_USER?}
${EXIST_BACKEND_PORT?}
${EXIST_BACKEND_SPORT?}
${EXIST_STAGING_USER?}
${EXIST_STAGING_PORT?}
${EXIST_STAGING_SPORT?}
TESTVARIABLES


# Install components from OS packages

yum -q -y install java-1.8.0-openjdk httpd wget xmlstarlet git
echo 'JAVA_HOME="`readlink -f /usr/bin/java | sed "s:/bin/java::"`"' >~/.javarc
echo 'export JAVA_HOME' >>~/.javarc
grep '\.javarc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.javarc ] && . ~/.javarc' >>~/.bash_profile ; }
. ~/.javarc


# Fetch resources
[ -d /opt/Download ] || mkdir /opt/Download
cd /opt/Download
echo "Downloading resources. This may take a moment."
[ -f "jetty-distribution-9.4.6.v20170531.tar.gz" ] || wget -nv -c "http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.4.6.v20170531/jetty-distribution-9.4.6.v20170531.tar.gz"
[ -f "eXist-db-setup-3.3.0.jar" ] || wget -nv -c "https://bintray.com/existdb/releases/download_file?file_path=eXist-db-setup-3.3.0.jar" -O "eXist-db-setup-3.3.0.jar"



# Install jetty

function install_jetty {
  export JETTY_USER="${1}"
  echo -e "${COLOR_NOTE}Installing jetty-base as user ${JETTY_USER}.${COLOR_STD}"
  grep "^${JETTY_USER}:.*" /etc/passwd >/dev/null || useradd "${JETTY_USER}"
  sudo -u "${JETTY_USER}" bash -s "${2}" "${3}" "${4}" <<'EndOfScriptAsJETTY_USER'
    export JETTY_BASE="${HOME}/apps/${1}"
    export JETTY_PORT="${2}"
    export JETTY_SPORT="${3}"

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
    [ -e "jettyserver" ] || ln -s /opt/jetty-distribution-9.4.6.v20170531 jettyserver
    java -jar "${JETTY_HOME}/start.jar" --create-startd
    java -jar "${JETTY_HOME}/start.jar" --add-to-start=server,http,console-capture,deploy,ext,jsp,resources,jstl,websocket,webapp,home-base-warning
    set_jettyini_property "jetty.http.host" "127.0.0.1" "http"
    set_jettyini_property "jetty.http.port" "${JETTY_PORT}" "http"
    set_jettyini_property "jetty.httpConfig.securePort" "${JETTY_SPORT}" "server"
    exit;
EndOfScriptAsJETTY_USER
  export JETTY_USERHOME="/home/${JETTY_USER}"
}

cd /opt
tar -xzf /opt/Download/jetty-distribution-9.4.6.v20170531.tar.gz

install_jetty "${JETTY_USER}" "${JETTY_PROJECT}" "${JETTY_PORT}" "${JETTY_SPORT}"

export JETTY_BASE="${JETTY_USERHOME}/apps/${JETTY_PROJECT}"
export JETTY_HOME="${JETTY_BASE}/jettyserver"

echo "JETTY_USER='${JETTY_USER}'" >/etc/default/jetty
echo "JETTY_HOME='${JETTY_HOME}'" >>/etc/default/jetty
echo "JETTY_BASE='${JETTY_BASE}'" >>/etc/default/jetty
echo "JETTY_RUN='${JETTY_BASE}/run'" >>/etc/default/jetty
echo "TMPDIR='${JETTY_BASE}/tmp'" >>/etc/default/jetty

echo -e "${COLOR_NOTE}Installing jetty instance in ${JETTY_BASE} as service running as user ${JETTY_USER}.${COLOR_STD}"


chcon -u system_u /etc/default/jetty
cat "${JETTY_HOME}/bin/jetty.sh" >/etc/init.d/jetty
chcon -u system_u -t initrc_exec_t /etc/init.d/jetty
chkconfig --add jetty
chkconfig jetty on


# Install eXistdb

function install_exist {
  export EXIST_USER="${1}"
  echo -e "${COLOR_NOTE}Installing eXistdb as user ${EXIST_USER}.${COLOR_STD}"
  grep "^${EXIST_USER}:.*" /etc/passwd >/dev/null || useradd "${EXIST_USER}"
  sudo -u "${EXIST_USER}" bash -s "${2}" "${3}" <<'EndOfScriptAsEXIST_USER'
    export EXIST_PORT="${1}"
    export EXIST_SPORT="${2}"

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

    echo 'JAVA_HOME="`readlink -f /usr/bin/java | sed "s:/bin/java::"`"' >~/.javarc
    echo 'export JAVA_HOME' >>~/.javarc
    grep '\.javarc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.javarc ] && . ~/.javarc' >>~/.bash_profile ; }
    . ~/.javarc

    echo "EXIST_HOME='${HOME}/apps/existdb'" >~/.existrc
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
    echo "INSTALL_PATH=${HOME}/apps/existdb" > existdb.options
    echo "dataDir=${HOME}/apps/existdata" >> existdb.options
    echo "MAX_MEMORY=2048" >> existdb.options
    echo "cacheSize=256" >> existdb.options
    export adminPasswd="`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`"
    java -jar /opt/Download/eXist-db-setup-3.3.0.jar -options existdb.options
    sed -i "s%^.*wrapper.app.account=.*$%wrapper.app.account=${USER}%" "${EXIST_HOME}/tools/yajsw/conf/wrapper.conf"
    bin/client.sh --no-gui --local --user admin --xpath "xmldb:change-user('admin','${adminPasswd}','dba','/db')" >/dev/null
    echo -e "\033[0;32mYour eXistDB instance ${USER} has admin password: >${adminPasswd}<\033[0m"
    #read -n 1 -s -r -p 'Take note of this password for user "admin". Press any key to continue.'
    cd "${JETTY_HOME}/etc"
    set_jettyxml_property jetty.port "${EXIST_PORT}"
    set_jettyxml_property jetty.ssl.port "${EXIST_SPORT}"
    exit;
EndOfScriptAsEXIST_USER
  export EXIST_USERHOME="/home/${EXIST_USER}"
  export EXIST_HOME="${EXIST_USERHOME}/apps/existdb"
}

install_exist "${EXIST_STAGING_USER}" "${EXIST_STAGING_PORT}" "${EXIST_STAGING_SPORT}"
install_exist "${EXIST_BACKEND_USER}" "${EXIST_BACKEND_PORT}" "${EXIST_BACKEND_SPORT}"

echo -e "${COLOR_NOTE}Installing eXistdb instance in ${EXIST_HOME} as service running as user ${EXIST_USER}.${COLOR_STD}"

export RUN_AS_USER="${EXIST_USER}"
cd "${EXIST_HOME}"
yes | tools/yajsw/bin/installDaemon.sh >/dev/null

[ -f /etc/systemd/system/eXist-db.service ] && {
  chcon -u system_u /etc/systemd/system/eXist-db.service
  systemctl enable eXist-db
  }
[ -f /etc/init.d/eXist-db ] && {
  chcon -u system_u /etc/init.d/eXist-db
  chkconfig --add eXist-db
  chkconfig eXist-db on
  }

