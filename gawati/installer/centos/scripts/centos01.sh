function install {
  VERSION="${2}"
  installer_init "${1}" "" ""

  OSversion="`rpm -q --queryformat '%{VERSION}' centos-release`"

  yum history summary | grep 'Last day\|Last week' | grep U >/dev/null || {
    message 2 "More than 1 week since last yum repository check. Fetching updates..."
    yum -y update
    }

  OSinstall deltarpm 1

  NrOfUpdates="`yum -q list updates | grep -v '^Updated Packages$' | wc -l`"
  [ "${NrOfUpdates}" -gt 0 ] && {
    message 2 "${NrOfUpdates} updates available. Applying."
    yum -y upgrade
    }

  CFGSRC="${DOWNLOADFOLDER}/installer/${INSTALLER_NAME}/scripts/01"
  vardebug CFGSRC

  cfgdeploy "10-loswap.conf 10-noipv6.conf" "/etc/sysctl.d" "${CFGSRC}"
  [ -f "/etc/sysctl.d/10-loswap.conf" ] && chcon -t system_conf_t "/etc/sysctl.d/10-loswap.conf"
  [ -f "/etc/sysctl.d/10-noipv6.conf" ] && chcon -t system_conf_t "/etc/sysctl.d/10-noipv6.conf"

  OSinstall yum-cron 1
  systemctl enable yum-cron

  OSinstall screen 1
  OSinstall net-tools 1
  OSinstall iptables-services 1

  SHOSTNAME="`iniget \"${INSTANCE}\" hostname`"
  DNSdomain="`iniget \"${INSTANCE}\" DNSdomain`"
  MainIP="`iniget \"${INSTANCE}\" mainIP`"

  [ "${MainIP}" = "detect" ] && {
    MainIP="`ip addr | grep 'inet ' | grep -v '127.0.0.1' | head -1 | xargs echo -n | cut -d ' ' -f 2 | cut -d '/' -f 1`"
    }

  vardebug SHOSTNAME DNSdomain MainIP


  hostnamectl --static set-hostname "${SHOSTNAME}"

  addtohosts "${MainIP}" "${SHOSTNAME}.${DNSdomain} ${SHOSTNAME}"

  }

