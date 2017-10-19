#!/bin/bash

function install {
  VERSION="${2}"
  installer_init "${1}"

  EXIST_APPNAME="`iniget \"${INSTANCE}\" appname`"
  SOURCE_URL="`iniget \"${INSTANCE}\" source_url`"
  EXIST_INSTANCE="`iniget \"${INSTANCE}\" exist_instance`"
  EXIST_PATH="`iniget \"${INSTANCE}\" exist_path`"
  EXIST_PORT="`getvar EXIST_PORT ${EXIST_INSTANCE}`"
  EXIST_PWD="`getvar adminPasswd ${EXIST_INSTANCE}`"

  askifempty EXIST_PWD "Please provide the administrator password for eXist instance >${EXIST_INSTANCE}<."
  setvar adminPasswd "${EXIST_PWD}" "${EXIST_INSTANCE}"

  vardebug SOURCE_URL EXIST_INSTANCE EXIST_PATH EXIST_PORT EXIST_PWD EXIST_APPNAME

  export EXIST_APPNAME
  export SOURCE_URL

  EXIST_DO_LIST='<query xmlns="http://exist.sourceforge.net/NS/exist"><text><![CDATA[repo:list()]]></text></query>'
  EXIST_DO_UNDEPLOY='<query xmlns="http://exist.sourceforge.net/NS/exist"><text><![CDATA[repo:undeploy("${EXIST_APPNAME}")]]></text></query>'
  EXIST_DO_REMOVE='<query xmlns="http://exist.sourceforge.net/NS/exist"><text><![CDATA[repo:remove("${EXIST_APPNAME}")]]></text></query>'
  EXIST_DO_INSTALL='<query xmlns="http://exist.sourceforge.net/NS/exist"><text><![CDATA[repo:install-and-deploy("${EXIST_APPNAME}","${SOURCE_URL}")]]></text></query>'

  #exist_query "`echo ${EXIST_DO_LIST} | envsubst`"
  #EXIST_APPS="`echo "${RESPONSE}" | grep 'exist:value' | sed 's%.*<exist:value exist:type="xs:string">\(.*\)</exist:value>%\1%g'`"
  #vardebug EXIST_APPS

  exist_query EXIST_DO_REPO_LIST
  EXIST_APPS="`echo "${RESPONSE}" | grep 'exist:value' | sed 's%.*<exist:value exist:type="xs:string">\(.*\)</exist:value>%\1%g'`"
  vardebug EXIST_APPS

  echo "${EXIST_APPS}" | grep "^${EXIST_APPNAME}$" >/dev/null && {
    message 4 ">${EXIST_APPNAME}< already deployed in >${EXIST_INSTANCE}<. Will remove it first."
    exist_query EXIST_DO_REPO_UNDEPLOY
    exist_query EXIST_DO_REPO_REMOVE
    }

  exist_query EXIST_DO_REPO_INSTALL
  }

