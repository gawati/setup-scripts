function install {
  VERSION="${2}"
  installer_init "${1}" "" ""

  OSversion="`rpm -q --queryformat '%{VERSION}' centos-release`"

  yum history summary | grep 'Last day\|Last week' >/dev/null | grep U || {
    message 2 "More than 1 week since last yum repository check. Fetching updates..."
    yum -y update
    }

  NrOfUpdates="`yum -q list updates | grep -v '^Updated Packages$' | wc -l`"
  [ "${NrOfUpdates}" -gt 0 ] && {
    message 2 "${NrOfUpdates} updates available. Applying."
    yum -y upgrade
    }

  CFGSRC="${DOWNLOADFOLDER}/installer/${INSTALLER_NAME}/scripts/01"
  vardebug CFGSRC

  cfgdeploy "10-loswap.conf 10-noipv6.conf" "/etc/sysctl.d" "${CFGSRC}"

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

