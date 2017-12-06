function postinstall {
  URLTEMPLATE="http://localhost"
  cat "${PORTALWEBFOLDER}/index.html" | sed "s%${URLTEMPLATE}%https://${GAWATI_URL_ROOT}%g" >/tmp/tempfile
  cat /tmp/tempfile > "${PORTALWEBFOLDER}/index.html"
  rm /tmp/tempfile
  }

