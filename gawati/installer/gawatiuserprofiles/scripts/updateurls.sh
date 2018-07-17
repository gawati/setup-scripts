function postinstall {
  INDEXHTML="${WWWROOT}/profiles/index.html"
  vardebug INDEXHTML
  [ -f "${INDEXHTML}" ] || bail_out "File >${INDEXHTML}< missing."
  sed -i'' "s%GAWATI_PROXY:\"[^\"]*\"%GAWATI_PROXY:\"https://data.${GAWATI_URL_ROOT}\"%g" "${INDEXHTML}"
  sed -i'' "s%GAWATI_DOCUMENT_SERVER:\"[^\"]*\"%GAWATI_DOCUMENT_SERVER:\"https://media.${GAWATI_URL_ROOT}\"%g" "${INDEXHTML}"
  }

