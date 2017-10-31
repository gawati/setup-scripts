OSinstall openssl 1

function install {
  VERSION="${2}"
  installer_init "${1}" "" ""

  CFGFOLDER="${INSTALLER_HOME}/01"

  orginfo_init
  CERTS="`iniget \"${INSTANCE}\" certs`"
  PCD=/etc/pki/CA
  PTD=/etc/pki/tls
  export PCD PTD
  vardebug PCD PTD

  NEWCA=FALSE
  [ -e "${PCD}/newcerts/ca.conf" ] || {
    cfgwrite "${CFGFOLDER}/ca.conf" "${PCD}/newcerts"
    NEWCA=TRUE
    }

  [ -e "${PCD}/private/cacert.pem" ] || {
    openssl req -x509 -batch -config "${PCD}/newcerts/ca.conf" -days 3650 -newkey rsa:2048 -sha256 -nodes -out "${PCD}/private/cacert.pem" -outform PEM
    openssl x509 -in "${PCD}/private/cacert.pem" -out "${PCD}/certs/ca.crt"
    }

  [ "${NEWCA}" = "TRUE" ] && cat "${CFGFOLDER}/caextension.conf" | envsubst >> "${PCD}/newcerts/ca.conf"

  ANCH="/etc/pki/ca-trust/source/anchors"
  [ -d "${ANCH}" ] && {
    [ -e "${ANCH}/localca.pem" ] || ln -s "${PCD}/certs/ca.crt" "${ANCH}/localca.pem" && update-ca-trust
    }

  pushd "${PCD}/newcerts" >/dev/null
  [ -e "index.txt" ] || touch "index.txt"
  [ -e "serial.txt" ] || echo "01" > "serial.txt"
  
  for CERT in ${CERTS} ; do
    CERT_="`echo ${CERT} | tr '.' '_'`"
    export CERT CERT_
    vardebug CERT CERT_
    export CERTMAIL="postmaster@`echo ${CERT} | cut -d '.' -f 2-`"

    [ -e "${PTD}/${CERT_}.conf" ] || cfgwrite "${CFGFOLDER}/server.conf" "${PTD}" "${CERT_}.conf"

    [ -e "${PTD}/private/${CERT_}.key" -o -h "${PTD}/private/${CERT_}.key" ] || {
      openssl req -batch -config "${PTD}/${CERT_}.conf" -newkey rsa:2048 -sha256 -nodes -out "${PTD}/${CERT_}.csr" -outform PEM
      }

    [ -e "${PTD}/certs/${CERT_}.crt" -o -h "${PTD}/certs/${CERT_}.crt" ] || {
      openssl ca -batch -config "${PCD}/newcerts/ca.conf" -policy signing_policy -extensions signing_req -out "${PTD}/certs/${CERT_}.crt" -infiles "${PTD}/${CERT_}.csr"
      }

    done
  popd >/dev/null

  pushd "${PTD}/certs" >/dev/null
  [ -e "chain.pem" ] || ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem chain.pem
  popd >/dev/null
  }

