#!/bin/bash

function install {
  VERSION="${2}"
  ZIPFILE="gawati-templates-${VERSION}.zip"

  installer_init "${1}" "${ZIPFILE}" "https://github.com/gawati/gawati-templates/releases/download/${VERSION}/${ZIPFILE}"
  
  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/httpd/conf.d"

  export GAWATI_URL_ROOT="`iniget \"${INSTANCE}\" GAWATI_URL_ROOT`"
  export GAWATI_URL_ROOT_="`echo ${GAWATI_URL_ROOT} | tr . _`"
  export EXIST_BE_URL="`iniget \"${INSTANCE}\" EXIST_BE_URL`"

  addtohosts "${MainIP}" "${GAWATI_URL_ROOT}"

  cfgwrite "${CFGSRC}/10-gawati.conf" "${CFGDST}" "10-${GAWATI_URL_ROOT}.conf"

  WWWROOT="/var/www/html/${GAWATI_URL_ROOT}"
  [ -e "${WWWROOT}" ] || {
    mkdir -p "${WWWROOT}"
    chown root:apache "${WWWROOT}"
    }

  GWTEMPLATES="${WWWROOT}/gwtemplates"
  [ -e "${GWTEMPLATES}" ] || {
    mkdir -p "${GWTEMPLATES}"
    chown root:apache "${GWTEMPLATES}"
    }

  DSTOBJ="/etc/httpd/logs/${GAWATI_URL_ROOT}"
  [ -e "${DSTOBJ}" ] || {
    mkdir -p "${DSTOBJ}"
    chown root:apache "${DSTOBJ}"
    chmod 770 "${DSTOBJ}"
    }

  OSinstall unzip

  [ -f "${DOWNLOADFOLDER}/${ZIPFILE}" ] || bail_out "Template package not available at >${DOWNLOADFOLDER}/${ZIPFILE}<"
  unzip "${DOWNLOADFOLDER}/${ZIPFILE}" -d "${GWTEMPLATES}"
  [ -d "${GWTEMPLATES}/themes" ] || bail_out "Failed to deploy themes."
  chown -R root:apache "${GWTEMPLATES}/themes"


  #--------------------

  false && {
  XSTBE="`iniget \"${INSTANCE}\" existbe`"
  XSTST="`iniget \"${INSTANCE}\" existst`"

  BEPWD="`getvar adminPasswd ${XSTBE}`"
  STPWD="`getvar adminPasswd ${XSTST}`"

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
  }

  }

