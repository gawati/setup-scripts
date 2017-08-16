function install {
  VERSION="${2}"
  installer_init "${1}" "letsencrypt.pem" "https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem"

  OSinstall epel-release 1
  OSinstall acme-tiny 1

  SRCFOLDER="${INSTALLER_HOME}/01"

  DST=/var/www/challenges/.well-known
  [ -e "${DST}" ] || {
    mkdir -p "${DST}"
    chcon -R -u system_u /var/www/challenges
    }

  DST=/var/www/challenges/.well-known/acme-challenge
  [ -e "${DST}" ] || {
    ln -s /var/www/challenges "${DST}"
    chcon -h -u system_u "${DST}"
    }

  DST=/etc/pki/tls/letsencrypt
  [ -e "${DST}" ] || {
    mkdir "${DST}"
    chcon -u system_u "${DST}"
    }

  DST=/etc/ssl/letsencrypt
  [ -e "${DST}" ] || {
    ln -s /etc/pki/tls/letsencrypt "${DST}"
    chcon -h -u system_u "${DST}"
    }

  DST=/etc/ssl/letsencrypt/identrust.pem
  [ -e "${DST}" ] || {
    cat "${SRCFOLDER}/identrust.pem" > "${DST}"
    chcon -u system_u "${DST}"
    }

  DST=/etc/ssl/letsencrypt/letsencrypt.pem
  [ -e "${DST}" ] || {
    cat "${DOWNLOADFOLDER}/letsencrypt.pem" > "${DST}"
    chcon -u system_u "${DST}"
    }

  DST=/etc/ssl/letsencrypt/chain.pem
  [ -e "${DST}" ] || {
    cat /etc/ssl/letsencrypt/identrust.pem /etc/ssl/letsencrypt/letsencrypt.pem > "${DST}"
    chcon -u system_u "${DST}"
    }

  DST=/etc/ssl/letsencrypt/account.key
  [ -e "${DST}" ] || {
    openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:4096 -out "${DST}"
    chcon -u system_u "${DST}"
    chmod 640 "${DST}"
    }

  DST=/etc/logrotate.d/acme
  [ -e "${DST}" ] || {
    cat "${SRCFOLDER}/acme.logrotate" > "${DST}"
    chcon -u system_u "${DST}"
    }

  DST=/usr/local/bin/ssl-cert-check
  [ -e "${DST}" ] || {
    cat "${SRCFOLDER}/ssl-cert-check" > "${DST}"
    chcon -u system_u "${DST}"
    chmod 755 "${DST}"
    }

  DST=/usr/local/bin/acme_setup
  [ -e "${DST}" ] || {
    cat "${SRCFOLDER}/ssl-cert-check" > "${DST}"
    chcon -u system_u "${DST}"
    chmod 755 "${DST}"
    }

  DST=/usr/local/bin/acme_renew
  [ -e "${DST}" ] || {
    cat "${SRCFOLDER}/ssl-cert-check" > "${DST}"
    chcon -u system_u "${DST}"
    chmod 755 "${DST}"
    }
  }

