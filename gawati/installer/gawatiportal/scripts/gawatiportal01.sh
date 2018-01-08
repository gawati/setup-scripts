#!/bin/bash

function readconfig {
  VERSION="${2}"
  ZIPFILE="gawati-templates-${VERSION}.zip"

  installer_init "${1}" "${ZIPFILE}" "http://dl.gawati.org/${TARGET}/${ZIPFILE}"
  
  export GAWATI_URL_ROOT="`iniget \"${INSTANCE}\" GAWATI_URL_ROOT`"
  export GAWATI_URL_ROOT_="`echo ${GAWATI_URL_ROOT} | tr . _`"
  export EXIST_ST_URL="`iniget \"${INSTANCE}\" EXIST_ST_URL`"

  setvars GAWATI_URL_ROOT GAWATI_URL_ROOT_ EXIST_ST_URL
  }

function install {
  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/httpd/conf.d"

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

  OSinstall unzip 1

  [ -f "${DOWNLOADFOLDER}/${ZIPFILE}" ] || bail_out "Template package not available at >${DOWNLOADFOLDER}/${ZIPFILE}<"
  unzip -q "${DOWNLOADFOLDER}/${ZIPFILE}" -d "${GWTEMPLATES}"
  [ -d "${GWTEMPLATES}/themes" ] || bail_out "Failed to deploy themes."
  chown -R root:apache "${GWTEMPLATES}/themes"

  systemctl restart httpd
  setsebool -P httpd_can_network_connect true

  FILE="/usr/local/bin/fixthumbs"
  [ -e "${FILE}" ] || {
    cat "${CFGSRC}/fixthumbs" >"${FILE}"
    chcon -u system_u "${FILE}"
    chmod 755 "${FILE}"
    }

  [ -e "/usr/local/bin/uninstall" ] || ln -s "${DOWNLOADFOLDER}/uninstall.sh" "/usr/local/bin/uninstall"

  }

