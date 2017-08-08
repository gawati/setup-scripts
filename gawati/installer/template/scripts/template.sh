function install {
  VERSION="${2}"
  installer_init "${1}" "examplefile.png" "http://africaninnovation.org/img/logo.png"

  # The file downloaded is stored as
  #ls ${DOWNLOADFOLDER}/examplefile.png

  # Download an additional file into same folder
  #download "myfile.zip" "http://no.such.place/?download=uniqueidentifier"

  message 1 "This is a demo / template for writing installers, listing available predefined variables. It will not make any changes."
  message 1 "This template was invoked with instance name >${INSTANCE}<. This name might be used as a service name for starting at boot time."
  message 1 "This installer is called >${INSTALLER_NAME}<."
  message 1 "This installer is stored at >${INSTALLER_HOME}<."
  message 1 "If requested with installer_init(), it's installation file sits at >${INSTALLSRC}<."
  message 1 "Installation timestamp is >${STAMP}<."
  message 1 "If the package provides shared files, a global deployment folder was defined at >${DEPLOYMENTFOLDER}<".
  message 1 "The package is intended to be installed for or as user >${RUNAS_USER}< and if started on bootup, should run as that user. If missing, the user was created by installer_init()."
  message 1 "The package is to be installed into folder >${INSTANCE_PATH}<."
  message 1 "If custom options were specified, these are the ones: >${OPTIONS}<"

  # Fetch a custom configiration item from ini file
  #MYITEM="`iniget \"${INSTANCE}\" myitem`"

  # Make silently sure, that bash is installed. Give up, cancelling entire run if it isn't
  #OSinstall bash 1 || bail_out 1 "No bash, no dash."

  # Configure current users JAVA environment variables in shell rc file
  #set_environment_java

  # Write a config file from source template applying expansion on contained shell environment variables, optionally using new destination filename
  # Source templates we take from subfolder "01" of installerscript. Write variable info to console if in debug mode. Use "arrdebug" if it was an array.
  #SRCFOLDER="${INSTALLER_HOME}/01"
  #vardebug SRCFOLDER
  #cfgwrite "${SRCFOLDER}/${SRC_FILENAME}" "${DSTFOLDER}" "${OPTIONAL_DSTFILENAME}"

  # We can do a batch of files from there in one go
  #for FILE in ${CFGFILES} ; do
  #  cfgwrite "${SRCFOLDER}/${FILE}" "${DSTFOLDER}"
  #  done

  # Make sure that "myhost.mydomain.local" and "myhost" are assigned to 10.9.8.7 in /etc/hosts
  #addtohosts "10.9.8.7" "myhost.mydomain.local" "myhost"
  }

