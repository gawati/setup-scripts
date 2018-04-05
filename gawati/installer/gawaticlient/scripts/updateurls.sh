function postinstall {
  cat "${EDITROOT}/index.html" | sed "s%GAWATI_PROXY:\"[^\"]*\"%GAWATI_PROXY:\"https://${GAWATI_URL_ROOT}\"%g" >/tmp/tempfile
  cat /tmp/tempfile | sed "s%GAWATI_DOCUMENT_SERVER:\"[^\"]*\"%GAWATI_DOCUMENT_SERVER:\"https://media.${GAWATI_URL_ROOT}\"%g" > "${EDITROOT}/index.html"
  rm /tmp/tempfile
  }

