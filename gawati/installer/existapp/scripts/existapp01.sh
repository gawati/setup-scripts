#!/bin/bash

function install {
  VERSION="${2}"
  installer_init "${1}"

  SOURCE_URL="`iniget \"${INSTANCE}\" source_url`"
  EXIST_INSTANCE="`iniget \"${INSTANCE}\" exist_instance`"
  EXIST_PATH="`iniget \"${INSTANCE}\" exist_path`"
  TEMP_XML="/tmp/gawatideploy.xml"
  PORT="`getvar EXIST_PORT ${EXIST_INSTANCE}`"
  EXISTPWD="`getvar adminPasswd ${EXIST_INSTANCE}`"

  [ "${EXISTPWD}" = "" ] && {
    echo "Please provide the administrator password for eXist instance >${EXIST_INSTANCE}<."
    read EXISTPWD
    INSTANCE="${EXIST_INSTANCE}"
    setvar adminPasswd "${EXISTPWD}"
    }


  QUERY="repo:install-and-deploy('http://localhost/${INSTANCE}','${SOURCE_URL}')"
  POST="<query xmlns='http://exist.sourceforge.net/NS/exist'><text><![CDATA[${QUERY}]]></text></query>"
  vardebug SOURCE_URL EXIST_INSTANCE EXIST_PATH TEMP_XML PORT EXISTPWD POST

  RESPONSE="`curl -s -H "Content-Type: text/xml" -u "admin:${EXISTPWD}" -o "${TEMP_XML}" -w "%{http_code}" -d "${POST}" "http://localhost:${PORT}/exist/rest/db"`"
  vardebug RESPONSE

  message 4 "`cat ${TEMP_XML}`"
  [ -f "${TEMP_XML}" ] && rm "${TEMP_XML}"
  }

