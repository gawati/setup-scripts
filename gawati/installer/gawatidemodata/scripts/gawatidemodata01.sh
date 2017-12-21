#!/bin/bash

function install {
  VERSION="${2}"

  installer_init "${1}" "" ""

  PDFZIP="${DOWNLOADFOLDER}/akn_pdf_sample-${VERSION}.zip"
  XMLZIP="${DOWNLOADFOLDER}/akn_xml_sample-${VERSION}.zip"
  vardebug PDFZIP XMLZIP

  download "${PDFZIP}" "http://dl.gawati.org/demodata/akn_pdf_sample-${VERSION}.zip"
  download "${XMLZIP}" "http://dl.gawati.org/demodata/akn_xml_sample-${VERSION}.zip"

  OSinstall unzip 1

  GAWATI_URL_ROOT="`getvar GAWATI_URL_ROOT gawatifrontend`"
  askifempty GAWATI_URL_ROOT "Please provide the full public DNS hostname for your Gawati server."
  WWWROOT="/var/www/html/${GAWATI_URL_ROOT}"
  vardebug GAWATI_URL_ROOT WWWROOT

  [ -f "${PDFZIP}" ] || bail_out "Demodata documents package not available at >${PDFZIP}<"
  unzip -q "${PDFZIP}" -d "${WWWROOT}"
  [ -d "${WWWROOT}/akn" ] || bail_out "Failed to deploy documents."
  chown -R root:apache "${WWWROOT}/akn"

  STIMPORT="`iniget \"${INSTANCE}\" importFolder`"
  [ -e "${STIMPORT}" ] || mkdir -p "${STIMPORT}"

  [ -f "${XMLZIP}" ] || bail_out "XML demodata package not available at >${XMLZIP}<"
  unzip -q "${XMLZIP}" -d "${STIMPORT}"
  [ -d "${STIMPORT}/akn" ] || bail_out "Failed to deploy documents."
  chown -R root:apache "${STIMPORT}/akn"

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
    RESULT="`${STHOME}/bin/client.sh -ouri=xmldb:exist://localhost:${STPORT}/exist/xmlrpc -u gwdata -P """${STDATAPWD}""" -d -m /db/apps/gw-data/akn -p """${STIMPORT}/akn""" 2>/dev/null | tail -1`"
    message 1 "${RESULT}"
    }
  }

