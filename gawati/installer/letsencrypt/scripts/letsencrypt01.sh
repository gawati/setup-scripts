function install {
  VERSION="${2}"
  installer_init "${1}" "letsencrypt.pem" "https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem"

  OSinstall epel-release 1
  OSinstall acme-tiny 1

  SRCFOLDER="${INSTALLER_HOME}/01"

  [ -e /var/www/challenges/.well-known ] || {
    mkdir -p /var/www/challenges/.well-known
    chcon -R -u system_u /var/www/challenges
    }

  [ -e /var/www/challenges/.well-known/acme-challenge ] || {
    ln -s /var/www/challenges /var/www/challenges/.well-known/acme-challenge
    chcon -h -u system_u /var/www/challenges/.well-known/acme-challenge
    }

  [ -e /etc/pki/tls/letsencrypt ] || {
    mkdir /etc/pki/tls/letsencrypt
    chcon -u system_u /etc/pki/tls/letsencrypt
    }
  [ -e /etc/ssl/letsencrypt ] || {
    ln -s /etc/pki/tls/letsencrypt /etc/ssl/letsencrypt
    chcon -h -u system_u /etc/ssl/letsencrypt
    }

  [ -e /etc/ssl/letsencrypt/identrust.pem ] || {
    cp "${SRCFOLDER}/identrust.pem" /etc/ssl/letsencrypt/
    chcon -u system_u /etc/ssl/letsencrypt/identrust.pem
    }

  [ -e /etc/ssl/letsencrypt/letsencrypt.pem ] || {
    cp "${DOWNLOADFOLDER}/letsencrypt.pem" /etc/ssl/letsencrypt/
    chcon -u system_u /etc/ssl/letsencrypt/letsencrypt.pem
    }

  [ -e /etc/ssl/letsencrypt/chain.pem ] || {
    cat /etc/ssl/letsencrypt/identrust.pem /etc/ssl/letsencrypt/letsencrypt.pem > /etc/ssl/letsencrypt/chain.pem
    chcon -u system_u /etc/ssl/letsencrypt/chain.pem
    }

  [ -e /etc/ssl/letsencrypt/account.key ] || {
    openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:4096 -out /etc/ssl/letsencrypt/account.key
    chcon -u system_u /etc/ssl/letsencrypt/account.key
    chmod 640 /etc/ssl/letsencrypt/account.key
    }

  [ -e /etc/logrotate.d/acme ] || {
    cp "${SRCFOLDER}/acme.logrotate" /etc/logrotate.d/acme
    chcon -u system_u /etc/logrotate.d/acme
    }

  }

