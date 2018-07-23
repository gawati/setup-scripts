function postinstall {
  INDEXHTML="${WWWROOT}/index.html"
  vardebug INDEXHTML
  [ -f "${INDEXHTML}" ] || bail_out "File >${INDEXHTML}< missing."
  sed -i'' "s%GAWATI_PROXY:\"[^\"]*\"%GAWATI_PROXY:\"https://data.${GAWATI_URL_ROOT}\"%g" "${INDEXHTML}"
  }

