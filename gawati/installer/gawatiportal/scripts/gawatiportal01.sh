#!/bin/bash

function install {
  VERSION="${2}"
  installer_init "${1}" "" ""
  
  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/httpd/conf.d"

  export GAWATI_URL_ROOT="`iniget \"${INSTANCE}\" GAWATI_URL_ROOT`"
  export GAWATI_URL_ROOT_="`echo ${GAWATI_URL_ROOT} | tr . _`"
  export EXIST_BE_URL="`iniget \"${INSTANCE}\" EXIST_BE_URL`"

  addtohosts "${MainIP}" "${GAWATI_URL_ROOT}"

  cfgwrite "${CFGSRC}/10-gawati.conf" "${CFGDST}" "10-${GAWATI_URL_ROOT}.conf"

  DSTOBJ="/var/www/html/${GAWATI_URL_ROOT}"
  [ -e "${DSTOBJ}" ] || {
    mkdir -p "${DSTOBJ}"
    chown root:apache "${DSTOBJ}"
    }

  DSTOBJ="/etc/httpd/logs/${GAWATI_URL_ROOT}"
  [ -e "${DSTOBJ}" ] || {
    mkdir -p "${DSTOBJ}"
    chown root:apache "${DSTOBJ}"
    chmod 770 "${DSTOBJ}"
    }

  false && {
  OSinstall fabric

  pushd "${DOWNLOADFOLDER}" >/dev/null
  [ -d "gawati" ] &&  {
    cd gawati
    svn update >/dev/null
    message 1 "Updated gawati installers..."
    } ||  {
    message 1 "Fetching gawati installers..."
    svn checkout "https://github.com/gawati/setup-scripts.git/trunk/gawati/fabric" gawati >/dev/null
    }
  popd >/dev/null

  XSTBE="`iniget \"${INSTANCE}\" existbe`"
  XSTST="`iniget \"${INSTANCE}\" existst`"

  BEPWD="`getvar adminPasswd ${XSTBE}`"
  STPWD="`getvar adminPasswd ${XSTST}`"

  BUILDUSER="`iniget \"${INSTANCE}\" builduser`"
  export BEPWD STPWD BUILDUSER

  ensureuser "${BUILDUSER}"

  [ -e ~/.ssh/id_rsa.pub ] || {
    [ -e ~/.ssh/id_rsa ] || {
      ssh-keygen -f "${HOME}/.ssh/id_rsa" -t rsa -N ''
      } || {
      message 3 "The installer needs to provide the root user with ssh access to the builduser by using ssh keys."
      bail_out "Please store your public key as ~/.ssh/id_rsa.pub"
      }
    }

  sudo -u "${BUILDUSER}" MYKEY="`bash -c 'cat ~/.ssh/id_rsa.pub'`" bash -s "" <<'EndOfScriptAsRUNAS_USER'
  [ -d ~/.ssh ] || {
    mkdir ~/.ssh
    chmod 700 ~/.ssh
    }

  [ -f ~/.ssh/authorized_keys ] || {
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    }

  grep "${MYKEY}" ~/.ssh/authorized_keys >/dev/null || echo "${MYKEY}" >>~/.ssh/authorized_keys
EndOfScriptAsRUNAS_USER


  [ "${BEPWD}" = "" ] && {
    echo "Please provide the administrator password for eXist instance >${XSTBE}<."
    read BEPWD
    }

  [ "${STPWD}" = "" ] && {
    echo "Please provide the administrator password for eXist instance >${XSTST}<."
    read STPWD
    }

  cat "${CFGSRC}/deployment.ini" | envsubst | "${DOWNLOADFOLDER}/gawati/setup_fabric.sh"
  }

  }

