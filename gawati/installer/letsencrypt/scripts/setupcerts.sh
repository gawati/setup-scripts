function postinstall {

  orginfo_init
  CERTS="`iniget \"${INSTANCE}\" certs`"

  for CERT in ${CERTS} ; do
    CERT_="`echo ${CERT} | tr '.' '_'`"
    vardebug CERT CERT_

    [ -e "/etc/ssl/letsencrypt/${CERT_}.key" ] || {
      acme_setup "${CERT}" "${ORG}" "${COUNTRY}" "${STATE}" "${CITY}" && {
        crontab -l >"/tmp/cron.$$.${STAMP}"
        grep acme_renew "/tmp/cron.$$.${STAMP}" | grep "${CERT}" >/dev/null || {
          echo "0 5 * * * /usr/local/bin/acme_renew ${CERT}" >>"/tmp/cron.$$.${STAMP}"
          crontab "/tmp/cron.$$.${STAMP}"
          }
        [ -f "/tmp/cron.$$.${STAMP}" ] && rm -f "/tmp/cron.$$.${STAMP}"
        }
      }

    [ -e "/etc/pki/tls/private/${CERT_}.key" -o -h "/etc/pki/tls/private/${CERT_}.key" ] || {
      ln -s "/etc/ssl/letsencrypt/${CERT_}.key" "/etc/pki/tls/private/"
      }

    [ -e "/etc/pki/tls/certs/${CERT_}.crt" -o -h "/etc/pki/tls/certs/${CERT_}.crt" ] || {
      ln -s "/etc/ssl/letsencrypt/${CERT_}.crt" "/etc/pki/tls/certs/"
      }

    done

  }

