#!/bin/bash

function readconfig {
  VERSION="${2}"
  ZIP_PORTAL="portal-ui-${VERSION}.zip"

  installer_init "${1}" "${ZIP_PORTAL}" "http://dl.gawati.org/${PKGSRC}/${ZIP_PORTAL}"
  
  export GAWATI_URL_ROOT="`iniget \"${INSTANCE}\" GAWATI_URL_ROOT`"
  export GAWATI_URL_ROOT_="`echo ${GAWATI_URL_ROOT} | tr . _`"
  export GAWATI_URL_ROOT_ESC="`echo ${GAWATI_URL_ROOT} | sed 's%\.%\\\.%g'`"
  export EXIST_ST="`iniget \"${INSTANCE}\" existst | tr '-' '_'`"

  VARNAME="${EXIST_ST}_EXIST_PORT"
  export EXIST_ST_URL="http://localhost:${VARNAME}/exist"

  vardebug GAWATI_URL_ROOT GAWATI_URL_ROOT_ GAWATI_URL_ROOT_ESC EXIST_ST EXIST_ST_URL
  setvars GAWATI_URL_ROOT GAWATI_URL_ROOT_ GAWATI_URL_ROOT_ESC EXIST_ST
  }

function install {
  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/httpd/conf.d"
  vardebug CFGSRC CFGDST

  addtohosts "${MainIP}" "${GAWATI_URL_ROOT}"
  addtohosts "${MainIP}" "data.${GAWATI_URL_ROOT}"
  addtohosts "${MainIP}" "media.${GAWATI_URL_ROOT}"

  cfgwrite "${CFGSRC}/10-gawati.conf" "${CFGDST}" "10-${GAWATI_URL_ROOT}.conf"
  cfgwrite "${CFGSRC}/10-data.gawati.conf" "${CFGDST}" "10-data.${GAWATI_URL_ROOT}.conf"
  cfgwrite "${CFGSRC}/10-media.gawati.conf" "${CFGDST}" "10-media.${GAWATI_URL_ROOT}.conf"

  WWWROOT="/var/www/html/${GAWATI_URL_ROOT}"
  vardebug WWWROOT
  [ -e "${WWWROOT}" ] || {
    mkdir -p "${WWWROOT}"
    chown root:apache "${WWWROOT}"
    }

  DATAROOT="/var/www/html/data.${GAWATI_URL_ROOT}"
  vardebug DATAROOT
  [ -e "${DATAROOT}" ] || {
    mkdir -p "${DATAROOT}"
    chown root:apache "${DATAROOT}"
    }

  MEDIAROOT="/var/www/html/media.${GAWATI_URL_ROOT}"
  vardebug MEDIAROOT
  [ -e "${MEDIAROOT}" ] || {
    mkdir -p "${MEDIAROOT}"
    chown root:apache "${MEDIAROOT}"
    }

  PORTALWEBFOLDER="${WWWROOT}"
  vardebug PORTALWEBFOLDER
  [ -e "${PORTALWEBFOLDER}" ] || {
    mkdir -p "${PORTALWEBFOLDER}"
    chown root:apache "${PORTALWEBFOLDER}"
    }

  DSTOBJ="/etc/httpd/logs/${GAWATI_URL_ROOT}"
  vardebug DSTOBJ
  [ -e "${DSTOBJ}" ] || {
    mkdir -p "${DSTOBJ}"
    chown root:apache "${DSTOBJ}"
    chmod 770 "${DSTOBJ}"
    }

  OSinstall unzip 1

  [ -f "${DOWNLOADFOLDER}/${ZIP_PORTAL}" ] || bail_out "Portal package not available at >${DOWNLOADFOLDER}/${ZIP_PORTAL}<"
  unzip -q "${DOWNLOADFOLDER}/${ZIP_PORTAL}" -d "${PORTALWEBFOLDER}"

  systemctl restart httpd
  setsebool -P httpd_can_network_connect true

  for FILE in "fixthumbs" "gawaticheck"; do
    DSTFILE="/usr/local/bin/${FILE}"
    [ -e "${DSTFILE}" ] || {
      cat "${CFGSRC}/${FILE}" >"${DSTFILE}"
      chcon -u system_u "${DSTFILE}"
      chmod 755 "${DSTFILE}"
      }
    done

  [ -e "/usr/local/bin/uninstall" ] || ln -s "${DOWNLOADFOLDER}/installer/uninstall.sh" "/usr/local/bin/uninstall"

  }

