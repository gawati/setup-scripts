#!/bin/bash

function readconfig {
  VERSION="${2}"
  ZIP_PORTAL="portal-v${VERSION}.zip"

  installer_init "${1}" "${ZIP_PORTAL}" "https://github.com/gawati/gawati-portal-ui/releases/download/${VERSION}/${ZIP_PORTAL}"
  
  export GAWATI_URL_ROOT="`iniget \"${INSTANCE}\" GAWATI_URL_ROOT`"
  export GAWATI_URL_ROOT_="`echo ${GAWATI_URL_ROOT} | tr . _`"
  export EXIST_ST_URL="`iniget \"${INSTANCE}\" EXIST_ST_URL`"

  setvars GAWATI_URL_ROOT GAWATI_URL_ROOT_ EXIST_ST_URL
  }

function install {
  VERSION_TEMPLATE="`iniget \"${INSTANCE}\" templateVersion`"
  ZIP_TEMPLATE="gawati-templates-${VERSION_TEMPLATE}.zip"
  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/httpd/conf.d"
  vardebug ZIP_TEMPLATE CFGSRC CFGDST

  download "${DOWNLOADFOLDER}/${ZIP_TEMPLATE}" "https://github.com/gawati/gawati-templates/releases/download/${VERSION_TEMPLATE}/${ZIP_TEMPLATE}"

  addtohosts "${MainIP}" "${GAWATI_URL_ROOT}"

  cfgwrite "${CFGSRC}/10-gawati.conf" "${CFGDST}" "10-${GAWATI_URL_ROOT}.conf"

  WWWROOT="/var/www/html/${GAWATI_URL_ROOT}"
  vardebug WWWROOT
  [ -e "${WWWROOT}" ] || {
    mkdir -p "${WWWROOT}"
    chown root:apache "${WWWROOT}"
    }

  PORTALWEBFOLDER="${WWWROOT}/v2"
  vardebug PORTALWEBFOLDER
  [ -e "${PORTALWEBFOLDER}" ] || {
    mkdir -p "${PORTALWEBFOLDER}"
    chown root:apache "${PORTALWEBFOLDER}"
    }

  GWTEMPLATES="${WWWROOT}/gwtemplates"
  vardebug GWTEMPLATES
  [ -e "${GWTEMPLATES}" ] || {
    mkdir -p "${GWTEMPLATES}"
    chown root:apache "${GWTEMPLATES}"
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

  [ -f "${DOWNLOADFOLDER}/${ZIP_TEMPLATE}" ] || bail_out "Template package not available at >${DOWNLOADFOLDER}/${ZIP_TEMPLATE}<"
  unzip -q "${DOWNLOADFOLDER}/${ZIP_TEMPLATE}" -d "${GWTEMPLATES}"
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

