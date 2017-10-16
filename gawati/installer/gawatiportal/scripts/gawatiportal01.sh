#!/bin/bash

function install {
  VERSION="${2}"
  ZIPFILE="gawati-templates-${VERSION}.zip"

  installer_init "${1}" "${ZIPFILE}" "https://github.com/gawati/gawati-templates/releases/download/${VERSION}/${ZIPFILE}"
  
  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/httpd/conf.d"

  export GAWATI_URL_ROOT="`iniget \"${INSTANCE}\" GAWATI_URL_ROOT`"
  export GAWATI_URL_ROOT_="`echo ${GAWATI_URL_ROOT} | tr . _`"
  export EXIST_ST_URL="`iniget \"${INSTANCE}\" EXIST_ST_URL`"

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
  unzip -q "${DOWNLOADFOLDER}/${ZIPFILE}" -d "${GWTEMPLATES}"
  [ -d "${GWTEMPLATES}/themes" ] || bail_out "Failed to deploy themes."
  chown -R root:apache "${GWTEMPLATES}/themes"

  STIMPORT="`iniget \"${INSTANCE}\" importFolder`"

  [ -d "${STIMPORT}" ] && {
    XSTST="`iniget \"${INSTANCE}\" existst`"

    STUSER="`getvar RUNAS_USER ${XSTST}`"
    STHOME="`getvar EXIST_HOME ${XSTST}`"
    STPORT="`getvar EXIST_PORT ${XSTST}`"
    STPWD="`getvar adminPasswd ${XSTST}`"

    askifempty STPWD "Please provide the administrator password for eXist instance >${XSTST}<."
    setvar adminPasswd "${STPWD}" "${XSTST}"

    STDATAPWD="`${STHOME}/bin/client.sh -ouri=xmldb:exist://localhost:${STPORT}/exist/xmlrpc -u admin -P """${STPWD}""" -x """data(doc('/db/apps/gw-data/_auth/_pw.xml')/users/user[@name = 'gwdata']/@pw)""" 2>/dev/null | tail -1`"

    vardebug XSTST STIMPORT STUSER STHOME STPORT STPWD STDATAPWD

    message 1 "Importing Data into exist instance >${XSTST}<. This can take a while."
    RESULT="`${STHOME}/bin/client.sh -ouri=xmldb:exist://localhost:${STPORT}/exist/xmlrpc -u gwdata -P """${STDATAPWD}""" -d -m /db/apps/gw-data/akn -p """${STIMPORT}""" 2>/dev/null | tail -1`"
    message 1 "${RESULT}"
    }
  }

