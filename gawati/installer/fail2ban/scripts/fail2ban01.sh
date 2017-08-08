function install {
  VERSION="${2}"
  installer_init "${1}" "" ""

  OSinstall iptables 1
  OSinstall fail2ban 1

  export EMAILsender="`iniget \"${INSTANCE}\" mailsender`"
  export EMAILrecipient="`iniget \"${INSTANCE}\" mailrecipient`"

  CFGFOLDER="${INSTALLER_HOME}/01"
  cfgwrite "${CFGFOLDER}/jail.local" "/etc/fail2ban"

  systemctl enable fail2ban || message 3 "Failed to enable fail2ban service"
  systemctl start fail2ban || message 3 "Failed to start fail2ban service"

  FILE="/usr/local/bin/offenders"
  [ -f "${FILE}" ] || {
    cat "${CFGFOLDER}/offenders" >"${FILE}"
    chcon -u system_u "${FILE}"
    chmod 755 "${FILE}"
    }
  }

