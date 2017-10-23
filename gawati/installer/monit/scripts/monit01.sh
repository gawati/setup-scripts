function install {
  VERSION="${2}"
  installer_init "${1}" "" ""

  touch /var/www/html/monit_token
  chcon -u system_u /var/www/html/monit_token
  mkdir -p /var/lib/monit/events
  chcon -R -u system_u /var/lib/monit

  OSinstall monit

  SRCFOLDER="${INSTALLER_HOME}/01"
  MODULES="`iniget \"${INSTANCE}\" options`"
  export MAILRECIPIENT="`iniget \"${INSTANCE}\" mailrecipient`"
  export MONITPWD="`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`"
  vardebug SRCFOLDER MODULES MAILRECIPIENT MONITPWD

  cfgwrite "${SRCFOLDER}/monitrc" "/etc"
  chmod 600 /etc/monitrc

  for FILE in `echo ${MODULES} | tr ',' ' '`; do
    [ -e "/etc/monit.d/${FILE}" ] || cfgwrite "${SRCFOLDER}/${FILE}" "/etc/monit.d"
    chmod 600 "/etc/monit.d/${FILE}"
    done

  FSCONFIG="/etc/monit.d/filesystems"
  [ -e "${FSCONFIG}" ] || {
    echo -n "" > "${FSCONFIG}"
    for FSMOUNT in `df -l --output=target -x tmpfs -x devtmpfs | tail -n +2` ; do
      FSNAME="`echo ${FSMOUNT} | sed 's%^.*/\(.*\)$%\1%g'`"
      FSNAME="${FSNAME:-root}"
      echo "check filesystem ${FSNAME} with path ${FSMOUNT}" >> "${FSCONFIG}"
      echo "	if space usage > 80% then alert" >> "${FSCONFIG}"
      echo "" >> "${FSCONFIG}"
      done
    }

  addsummary "Admin Password for user >admin< on monit webinterface: >${MONITPWD}<"

  systemctl enable monit
  systemctl restart monit
  }

