function postinstall {
  URLTEMPLATE="http://alldev.gawati.org"
  cat "${PORTALWEBFOLDER}/static/js/main.a2e1ddf3.js" | sed "s%${URLTEMPLATE}%https://${GAWATI_URL_ROOT}%g" >/tmp/tempfile
  cat /tmp/tempfile > "${PORTALWEBFOLDER}/static/js/main.a2e1ddf3.js"
  cat "${PORTALWEBFOLDER}/static/js/main.a2e1ddf3.js.map" | sed "s%http://${URLTEMPLATE}%https://${GAWATI_URL_ROOT}%g" >/tmp/tempfile
  cat /tmp/tempfile > "${PORTALWEBFOLDER}/static/js/main.a2e1ddf3.js.map"
  rm /tmp/tempfile
  }

