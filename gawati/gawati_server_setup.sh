#!/bin/bash
trap "exit 1" TERM

[ '0' -eq "`id -ur`" ] || {
  echo 'This installer must be run as root.'
  exit 1
  }

COLOR_OFF='\033[0m'
COLOR_0='\033[0m'
COLOR_1='\033[0;32m'
COLOR_2='\033[0;33m'
COLOR_3='\033[0;31m'
COLOR_4='\033[0;96m'

DEBUG=1

function timestamp {
  date +"%Y%m%d_%H%M%S"
  }

function message {
  [ "$#" -gt 2 ] && {
    [ "${3}" -ge "${DEBUG}" ] && return 0
    }
  COLOR_ON="`eval echo \$\{COLOR_${1}\}`"
  echo -e "${COLOR_ON}${2}${COLOR_OFF}"
  }

function bail_out {
  message 3 "${2}"
  kill -s TERM ${MYPID}
  }

function vardebug {
  for VARIABLE in $* ; do
    message 4 "${VARIABLE}: >${!VARIABLE}<" 2
    done
  }

function arrdebug {
  for VARIABLE in $* ; do
    LISTNAME="${VARIABLE}[@]"
    i=0
    for ELEMENT in ${!LISTNAME} ; do
      ((i+=1))
      message 4 "${VARIABLE}[${i}]: >${ELEMENT}<" 2
      done
    done
  }

function ensureFolder {
  [ -d "${1}" ] && return 0
  [ -e "${1}" ] && bail_out 1 "Destination >${1}< in use, but not a folder."
  mkdir -p "${1}"
  }

function iniget {
  crudini --get "${INIFILE}" "${1}" "${2}" || bail_out 1 "Parameter >${2}< not defined for >${1}< in >${INIFILE}<."
  }

function download {
  message 1 "Starting download of >${1}<. This may take a moment."
  wget -nv -c "${2}" -O "${1}" || {
    rm "${1}"
    return 1
    }
  }

function OSinstall {
  PACKAGE="${1}"
  QUIESCE="${2:-0}"
  vardebug PACKAGE QUIESCE
  rpm -q "${PACKAGE}" >/dev/null 2>&1 && {
    [ "${QUIESCE}" -lt "1" ] && message 1 ">${PACKAGE}< already installed."
    return 0
    }
  message 4 "Installing >${PACKAGE}<..." 1
  yum -q -y install "${PACKAGE}" || bail_out 1 "Failed to install package >${PACKAGE}<."
  message 1 "Installed package >${PACKAGE}<."
  }

MYPID=$$
STAMP="`timestamp`"
TARGET="${1:-dev}"

OSinstall wget 1
OSinstall crudini 1
OSinstall subversion 1

INIFILE="${HOME}/${TARGET}.ini"
vardebug INIFILE

[ -f "${INIFILE}" ] || {
  download "${INIFILE}" "https://github.com/gawati/setup-scripts/raw/master/gawati/ini/${TARGET}.ini" || message 2 "Failed to download an installation template for >${TARGET}< at Gawati."
  message 1 "Please verify installation parameters in >${INIFILE}<."
  message 1 "Then rerun ${0} to install."
  exit 0
  }

[ -f "${INIFILE}" ] || bail_out 1 "No installation template file at >${INIFILE}<."
message 1 "Reading installation instructions from >${INIFILE}<."

TEMP="`crudini --get \"${INIFILE}\" options debug 2>/dev/null`" && DEBUG="${TEMP}"
#PACKAGES="`crudini --get \"${INIFILE}\" options installPackages`"
PACKAGES="`iniget options installPackages`"
vardebug DEBUG PACKAGES

for PACKAGE in `echo ${PACKAGES}` ; do
  OSinstall "${PACKAGE}"
  done


DOWNLOADFOLDER="`iniget options downloadFolder`"
DEPLOYMENTFOLDER="`iniget options deploymentFolder`"
ensureFolder "${DOWNLOADFOLDER}"
ensureFolder "${DEPLOYMENTFOLDER}"

pushd "${DOWNLOADFOLDER}" >/dev/null
[ -d "installer" ] &&  {
  cd installer
  svn update >/dev/null
  message 1 "Updated installers..."
  } ||  {
  message 1 "Fetching installers..."
  svn checkout "https://github.com/gawati/setup-scripts.git/trunk/gawati/installer" installer >/dev/null
  }
popd >/dev/null


TASKS="`crudini --get \"${INIFILE}\" | grep -v options`"
declare -A RESOURCES
declare -A INSTALLS
declare -A COLLECTION
declare -a NEEDED_RESOURCES

for TASK in ${TASKS} ; do
  vardebug TASK
  TYPE="`iniget "${TASK}" type`"
  vardebug TYPE
  #[ "${TYPE}" = "resource" ] && RESOURCES+=(["${TASK}"]="`iniget \"${TASK}\" download`")
  [ "${TYPE}" = "install" ] && { 
    INSTALLS+=(["${TASK}"]="`iniget \"${TASK}\" installer`")
    #for TEMP in `iniget "${TASK}" resources`; do
    #  COLLECTION[${TEMP}]=1
    #  done
    }
  done

for TEMP in ${!COLLECTION[@]} ; do
  NEEDED_RESOURCES+=(${TEMP})
  done

arrdebug NEEDED_RESOURCES

pushd "${DOWNLOADFOLDER}" >/dev/null || bail_out 1 "Failed to enter folder >${DOWNLOADFOLDER}<."

for RESOURCE in ${NEEDED_RESOURCES[@]} ; do
  vardebug RESOURCE
  OUTFILE="`echo ${RESOURCES[$RESOURCE]} | cut -d ' ' -f 1`"
  URL="`echo ${RESOURCES[$RESOURCE]} | cut -d ' ' -f 2-`"
  vardebug OUTFILE URL
  [ -f "${OUTFILE}" ] || {
    download "${OUTFILE}" "${URL}" || bail_out 2 "Failed to download >${OUTFILE}< for resource >${RESOURCE}< from >${URL}<."
    }
  done

popd >/dev/null


# Installer section

LIBRARY="${DOWNLOADFOLDER}/installer/include.sh"
[ -f "${LIBRARY}" ] || bail_out 2 "Installer library missing in repository at >${LIBRARY}<."
source "${LIBRARY}"

set_environment_java

for INSTANCE in ${!INSTALLS[@]} ; do
  [ "${INSTANCE}" = "" ] && bail_out 1 "Installer instance name empty."
  vardebug INSTANCE
  unset install
  INSTALLER_NAME="${INSTALLS[$INSTANCE]}"
  vardebug INSTALLER_NAME
  #VERSION="`crudini --get \"${INIFILE}\" \"${INSTANCE}\" version`"
  VERSION="`iniget \"${INSTANCE}\" version`"
  vardebug VERSION
  INSTALLER_FILE="${DOWNLOADFOLDER}/installer/${INSTALLER_NAME}/${VERSION}"
  vardebug INSTALLER_FILE
  [ -f "${INSTALLER_FILE}" ] || bail_out 1 "No installer available at >${INSTALLER_FILE}<."
  . "${INSTALLER_FILE}"
  [ "`type -t install`" != function ] && bail_out 1 "No installer function defined."
  message 4 "Calling installer in >${INSTALLER_FILE}<." 2
  install "${INSTANCE}" "${VERSION}"
  done

