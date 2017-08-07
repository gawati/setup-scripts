function set_environment_java {
  echo 'JAVA_HOME="`readlink -f /usr/bin/java | sed "s:/bin/java::"`"' >~/.javarc
  echo 'export JAVA_HOME' >>~/.javarc
  grep '\.javarc' ~/.bash_profile >/dev/null || { echo >>~/.bash_profile ; echo '[ -f ~/.javarc ] && . ~/.javarc' >>~/.bash_profile ; }
  . ~/.javarc
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

  [ -f "${DSTFILE}" ] && {
    cp "${DSTFILE}" "${DSTFILE}.${STAMP}"
    }

  message 1 "Deploying template >${SRCFILE}< to >${DSTFILE}<."
  cat "${SRCFILE}" | envsubst > "${DSTFILE}"
  chcon -u system_u "${DSTFILE}"
  }

function installer_init {
  declare -g INSTANCE="${1}"
  declare -g OUTFILE="${2}"
  declare -g SRCURL="${3}"
  declare -g INSTALLER_NAME="${INSTALLS[$INSTANCE]}"
  declare -g INSTALLSRC="${DOWNLOADFOLDER}/${OUTFILE}"
  vardebug INSTANCE OUTFILE SRCURL INSTALLER_NAME INSTALLSRC

  declare -g RUNAS_USER="`iniget \"${INSTANCE}\" user`"
  [ "${RUNAS_USER}" = "" ] && declare -g RUNAS_USER="${USER}"
  vardebug RUNAS_USER
  grep "^${RUNAS_USER}:.*" /etc/passwd >/dev/null || useradd "${RUNAS_USER}" || bail_out 1 "Failed to add missing user >${RUNAS_USER}<."

  declare -g INSTANCE_FOLDER="`iniget \"${INSTANCE}\" instanceFolder`"
  vardebug INSTANCE_FOLDER
  declare -g INSTANCE_PATH="`echo eval echo ${INSTANCE_FOLDER} | sudo -u \"${RUNAS_USER}\" bash -s`" || bail_out 1 "Failed to determine instance folder for >${INSTANCE}<."
  vardebug INSTANCE_PATH
  declare -g OPTIONS="`crudini --get \"${INIFILE}\" \"${INSTANCE}\" options`"
  vardebug OPTIONS

  [ "${OUTFILE}" = "" ] || [ -f "${INSTALLSRC}" ] || {
    download "${INSTALLSRC}" "${SRCURL}" || bail_out 2 "Failed to download >${OUTFILE}< from >${URL}<."
    declare -g OUTFILE=""
    }
  }

