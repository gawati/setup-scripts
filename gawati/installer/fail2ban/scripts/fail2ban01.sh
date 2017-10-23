function install {
  VERSION="${2}"
  installer_init "${1}" "" ""

  OSinstall iptables 1
  OSinstall fail2ban 1

  export EMAILsender="`iniget \"${INSTANCE}\" mailsender`"
  export EMAILrecipient="`iniget \"${INSTANCE}\" mailrecipient`"

  CFGFOLDER="${INSTALLER_HOME}/01"

  [ -e /etc/fail2ban/jail.local ] || cfgwrite "${CFGFOLDER}/jail.local" "/etc/fail2ban"

  touch /var/log/fail2ban.log
  chcon -u system_u /var/log/fail2ban.log

  systemctl enable fail2ban || message 3 "Failed to enable fail2ban service"
  systemctl restart fail2ban || message 3 "Failed to start fail2ban service"

  FILE="/usr/local/bin/offenders"
  [ -e "${FILE}" ] || {
    cat "${CFGFOLDER}/offenders" >"${FILE}"
    chcon -u system_u "${FILE}"
    chmod 755 "${FILE}"
    }
  }

