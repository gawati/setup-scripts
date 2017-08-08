function install {
  VERSION="${2}"
  installer_init "${1}" "examplefile.png" "http://africaninnovation.org/img/logo.png"

  message 1 "This is a demo / template for writing installers, listing available predefined variables. It will not make any changes."
  message 1 "This template was invoked with instance name >${INSTANCE}<. This name might be used as a service name for starting at boot time."
  message 1 "This installer is called >${INSTALLER_NAME}<."
  message 1 "If requested with installer_init(), it's installation file sits at >${INSTALLSRC}<."
  message 1 "If the package provides shared files, a global deployment folder was defined at >${DEPLOYMENTFOLDER}<".
  message 1 "The package is intended to be installed for or as user >${RUNAS_USER}< and if started on bootup, should run as that user. If missing, the user was created by installer_init()."
  message 1 "The package is to be installed into folder >${INSTANCE_PATH}<."
  message 1 "If custom options were specified, these are the ones: >${OPTIONS}<"

  # Fetch a custom configiration item from ini file
  #MYITEM="`iniget \"${INSTANCE}\" myitem`"

  # Make silently sure, that bash is installed
  #OSinstall bash 1

  # Write a config file from source template applying expansion on contained shell environment variables, optionally using new destination filename
  #cfgwrite "${SRCFOLDER}/${SRC_FILENAME}" "${DSTFOLDER}" "${OPTIONAL_DSTFILENAME}"

  }
