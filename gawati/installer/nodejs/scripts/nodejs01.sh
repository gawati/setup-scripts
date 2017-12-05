function install {
  VERSION="${2}"
  installer_init "${1}" "nodesource-release-el7-1.noarch.rpm" "https://rpm.nodesource.com/pub_${VERSION}.x/el/7/x86_64/nodesource-release-el7-1.noarch.rpm"

  yes | rpm -Uvh ${DOWNLOADFOLDER}/nodesource-release-el7-1.noarch.rpm
  OSinstall nodejs 1
  }

