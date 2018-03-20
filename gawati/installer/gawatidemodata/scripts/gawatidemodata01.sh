#!/bin/bash

function install {
  VERSION="${2}"

  installer_init "${1}" "" ""

  PDFZIP="${DOWNLOADFOLDER}/akn_pdf_sample-${VERSION}.zip"
  XMLZIP="${DOWNLOADFOLDER}/akn_xml_sample-${VERSION}.zip"
  FTZIP="${DOWNLOADFOLDER}/akn_xml_ft_sample-${VERSION}.zip"
  vardebug PDFZIP XMLZIP FTZIP

  download "${PDFZIP}" "http://dl.gawati.org/demodata/akn_pdf_sample-${VERSION}.zip"
  download "${XMLZIP}" "http://dl.gawati.org/demodata/akn_xml_sample-${VERSION}.zip"
  download "${FTZIP}" "http://dl.gawati.org/demodata/akn_xml_ft_sample-${VERSION}.zip"

  OSinstall unzip 1

  GAWATI_URL_ROOT="`getvar GAWATI_URL_ROOT gawatifrontend`"
  askifempty GAWATI_URL_ROOT "Please provide the full public DNS hostname for your Gawati server."
  WWWROOT="/var/www/html/${GAWATI_URL_ROOT}"
  MEDIAROOT="/var/www/html/media.${GAWATI_URL_ROOT}"
  vardebug GAWATI_URL_ROOT WWWROOT MEDIAROOT

  [ -f "${PDFZIP}" ] || bail_out "Demodata documents package not available at >${PDFZIP}<"
  unzip -q "${PDFZIP}" -d "${MEDIAROOT}"
  [ -d "${MEDIAROOT}/akn" ] || bail_out "Failed to deploy documents."
  chown -R root:apache "${MEDIAROOT}/akn"

  STIMPORT="`iniget \"${INSTANCE}\" importFolder`"
  [ -e "${STIMPORT}" ] || mkdir -p "${STIMPORT}"

  [ -f "${XMLZIP}" ] || bail_out "XML demodata package not available at >${XMLZIP}<"
  unzip -q "${XMLZIP}" -d "${STIMPORT}"
  [ -d "${STIMPORT}/akn" ] || bail_out "Failed to deploy documents."
  chown -R root:apache "${STIMPORT}/akn"

  [ -f "${FTZIP}" ] || bail_out "XML demodata package not available at >${FTZIP}<"
  unzip -q "${FTZIP}" -d "${STIMPORT}"
  [ -d "${STIMPORT}/akn_ft" ] || bail_out "Failed to deploy search index."
  chown -R root:apache "${STIMPORT}/akn_ft"

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

    message 1 "Importing Fulltext Search Data into exist instance >${XSTST}<. This can take a while."
    RESULT="`${STHOME}/bin/client.sh -ouri=xmldb:exist://localhost:${STPORT}/exist/xmlrpc -u gwdata -P """${STDATAPWD}""" -d -m /db/apps/gw-data/akn_ft -p """${STIMPORT}/akn_ft""" 2>/dev/null | tail -1`"
    message 1 "${RESULT}"
    }
  }

