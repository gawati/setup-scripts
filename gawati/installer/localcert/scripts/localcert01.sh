OSinstall openssl 1

function install {
  VERSION="${2}"
  installer_init "${1}" "" ""

  CERTS="`iniget \"${INSTANCE}\" certs`"

  for CERT in ${CERTS} ; do
    CERT_="`echo ${CERT} | tr '.' '_'`"
    vardebug CERT CERT_
    [ -e "/etc/pki/tls/private/${CERT_}.key" ] || {
      openssl req -x509 -nodes -days 365 -subj "/C=CH/ST=Zug/L=Zug/CN=${CERT}" -newkey rsa:2048 -keyout "/etc/pki/tls/private/${CERT_}.key" -out "/etc/pki/tls/certs/${CERT_}.crt"
      }
    done

  pushd /etc/pki/tls/certs >/dev/null
  [ -e "chain.pem" ] || ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem chain.pem
  popd >/dev/null
  }

