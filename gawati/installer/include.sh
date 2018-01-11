OSinstall gettext 1
OSinstall iproute 1

export PKGSRC="`iniget options pkgsrc`"
vardebug PKGSRC

function set_environment_java {
  echo 'JAVA_HOME="`readlink -f /usr/bin/java | sed "s:/bin/java::"`"' >~/.javarc
  echo 'export JAVA_HOME' >>~/.javarc
  grep '\.javarc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.javarc ] && . ~/.javarc' >>~/.bash_profile ; }
  . ~/.javarc
  }


function setvar {
  VARIABLENAME="${1}"
  VALUE="${2}"
  FORINSTANCE="${3:-${INSTANCE}}"
  localvar="`echo ${FORINSTANCE}_${1} | tr '.-' '_'`"
  declare -g "${localvar}"="${VALUE}"
  export ${localvar}
  vardebug ${localvar}
  }


function setvars {
  for item in $*; do
    setvar "${item}" "${!item}"
    done
  }


function getvar {
  VARIABLENAME="${1}"
  FORINSTANCE="${2}"
  [ "${FORINSTANCE}" = "" ] && FORINSTANCE="${INSTANCE}"
  localvar="`echo ${FORINSTANCE}_${VARIABLENAME} | tr '.-' '_'`"
  echo "${!localvar}"
  }


function addsummary {
  SUMMARY+="${1}"$'\n'
  }


function ensureuser {
  NEWUSER="${1}"
  [ "${NEWUSER}" = "" ] && return
  grep "^${NEWUSER}:.*" /etc/passwd >/dev/null || useradd "${NEWUSER}" || bail_out 1 "Failed to add missing user >${NEWUSER}<."
  }


function orginfo_init {
  declare -g ORG="`iniget options organisation`"
  declare -g COUNTRY="`iniget options country`"
  declare -g STATE="`iniget options state`"
  declare -g CITY="`iniget options city`"
  declare -g ORGMAIL="`iniget options orgmail`"
  export ORG COUNTRY STATE CITY ORGMAIL
  vardebug ORG COUNTRY STATE CITY ORGMAIL
  }


function installer_init {
  declare -g INSTANCE="${1}"
  declare -g OUTFILE="${2}"
  declare -g SRCURL="${3}"
  declare -g INSTALLER_NAME="`iniget \"${INSTANCE}\" installer`"
  declare -g INSTALLER_HOME="${DOWNLOADFOLDER}/installer/${INSTALLER_NAME}/scripts"
  declare -g INSTALLSRC="${DOWNLOADFOLDER}/${OUTFILE}"
  vardebug INSTANCE OUTFILE SRCURL INSTALLER_NAME INSTALLER_HOME INSTALLSRC

  declare -g RUNAS_USER="`iniget \"${INSTANCE}\" user`"
  [ "${RUNAS_USER}" = "" ] && declare -g RUNAS_USER="`whoami`"
  vardebug RUNAS_USER
  ensureuser "${RUNAS_USER}"

  declare -g INSTANCE_FOLDER="`iniget \"${INSTANCE}\" instanceFolder`"
  vardebug INSTANCE_FOLDER
  declare -g INSTANCE_PATH="`echo eval echo ${INSTANCE_FOLDER} | sudo -u \"${RUNAS_USER}\" bash -s`" || bail_out 1 "Failed to determine instance folder for >${INSTANCE}<."
  vardebug INSTANCE_PATH
  declare -g OPTIONS="`crudini --get \"${INIFILE}\" \"${INSTANCE}\" options`"
  vardebug OPTIONS

  export INSTANCE VERSION OUTFILE SRCURL INSTALLER_NAME INSTALLER_HOME INSTALLSRC RUNAS_USER INSTANCE_FOLDER INSTANCE_PATH OPTIONS
  setvars VERSION OUTFILE SRCURL INSTALLER_NAME INSTALLER_HOME INSTALLSRC RUNAS_USER INSTANCE_FOLDER INSTANCE_PATH OPTIONS

  [ "${TYPE}" = "install" ] && {
    [ "${OUTFILE}" = "" ] || [ -f "${INSTALLSRC}" ] || {
      download "${INSTALLSRC}" "${SRCURL}" || bail_out 2 "Failed to download >${OUTFILE}< from >${URL}<."
      declare -g OUTFILE=""
      }
    }
  }


function cfgwrite {
  SRCFILE="${1}"
  DSTFOLDER="${2}"
  DSTFILENAME="${3}"
  [ "${DSTFILENAME}" = "" ] && DSTFILENAME="`basename ${SRCFILE}`"
  DSTFILE="${DSTFOLDER}/${DSTFILENAME}"
  vardebug SRCFILE DSTFILE

  [ -f "${SRCFILE}" ] || {
    message 3 "Source file >${SRCFILE}< missing."
    return
    }

  [ -d "${DSTFOLDER}" ] || {
    message 3 "Folder missing at >${DSTFOLDER}<."
    return
    }

  [ -e "${DSTFILE}" ] && {
    cp "${DSTFILE}" "${DSTFILE}.${STAMP}"
    }

  message 1 "Deploying template >${SRCFILE}< to >${DSTFILE}<."
  cat "${SRCFILE}" | envsubst > "${DSTFILE}"
  chcon -u system_u "${DSTFILE}"
  }


function cfgdeploy {
  FILES="${1}"
  DSTFOLDER="${2}"
  SRCFOLDER="${3}"

  [ "${SRCFOLDER}" = "" ] || SRCFOLDER+=/

  for FILE in ${FILES} ; do
    [ -f "${DSTFOLDER}/${FILE}" ] && {
      message 2 ">${DSTFOLDER}/${FILE}< already exists. Not changing."
      continue
      }
    cfgwrite "${SRCFOLDER}${FILE}" "${DSTFOLDER}"
    done
  }


function addtohosts {
  IP="${1}"
  NAMES="${*:2}"
  CHANGES=0
  ALLNAMES="`cat /etc/hosts | sed -r 's%^[0-9:\.]+(.*)%\1%g' | xargs -I str echo -n ' str '`"
  echo "$(cat /etc/hosts)" | grep -v "^${IP}\s" >/tmp/hosts.tmp
  OTHERNAMES="`cat /tmp/hosts.tmp | sed -r 's%^[0-9:\.]+(.*)%\1%g' | xargs -I str echo -n ' str '`"
  HOSTSdata="`grep \"^${IP}\s\" /etc/hosts`"

  for NAME in ${NAMES} ; do
    echo "${OTHERNAMES}" | grep " ${NAME} " >/dev/null && {
      message 2 ">${NAME}< already assigned to different IP in /etc/hosts - not changing."
      continue
      }
    HOSTSdata+=" ${NAME}"
    echo "${ALLNAMES}" | grep " ${NAME} " >/dev/null || {
      message 1 ">${NAME}< assigned to >${IP}< in /etc/hosts"
      CHANGES+=1
      }
    done

  [ "${CHANGES}" -gt 0 ] && {
    HOSTSdata="`echo ${HOSTSdata} |  tr ' ' '\n' | tail -n +2 | sort -ur | xargs echo -n`"
    echo "${IP}       ${HOSTSdata}" >>/tmp/hosts.tmp
    [ -e "/etc/hosts.${STAMP}" ] || cat /etc/hosts >"/etc/hosts.${STAMP}"
    cat /tmp/hosts.tmp >/etc/hosts
    }
  [ -f /tmp/hosts.tmp ] && rm -f /tmp/hosts.tmp
  }


function askifempty {
  VARNAME="${1}"
  USERTEXT="${2}"

  [ "${!VARNAME}" = "" ] && {
    echo "${USERTEXT}"
    read "${VARNAME}"
    }
  }


function exist_query {
  MYPOST="<query xmlns='http://exist.sourceforge.net/NS/exist'><text><![CDATA[`echo -n ${!1} | envsubst`]]></text></query>"
  MYUSER="${2:-admin}"
  MYPWD="${3:-${EXIST_PWD}}"
  MYPORT="${4:-${EXIST_PORT}}"
  vardebug MYPOST MYUSER MYPWD MYPORT
  declare -g RESPONSE
  RESPONSE="`curl -s -H "Content-Type: text/xml" -u "${MYUSER}:${MYPWD}" -w "%{http_code}" -d "${MYPOST}" "http://localhost:${MYPORT}/exist/rest/db"`"
  vardebug RESPONSE
  }

EXIST_DO_REPO_LIST='repo:list()'
EXIST_DO_REPO_UNDEPLOY='repo:undeploy("${EXIST_APPNAME}")'
EXIST_DO_REPO_REMOVE='repo:remove("${EXIST_APPNAME}")'
EXIST_DO_REPO_INSTALL='repo:install-and-deploy("${EXIST_APPNAME}","${SOURCE_URL}")'

