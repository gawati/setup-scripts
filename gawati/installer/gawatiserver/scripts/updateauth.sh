function postinstall {
  AUTHJS="${SERVER_HOME}/configs/auth.json"
  vardebug AUTHJS
  [ -f "${AUTHJS}" ] || bail_out "File >${AUTHJS}< missing."
  sed -i'' "s%realm\([ \"]*\): *\"\([^\"]*\)\"%realm\1:\"${KC_REALM}\"%g" "${AUTHJS}"
  sed -i'' "s%url\([ \"]*\): *\"\([^\"]*\)\"%url\1:\"${KC_URL}\"%g" "${AUTHJS}"
  sed -i'' "s%secret\([ \"]*\): *\"\([^\"]*\)\"%secret\1:\"${KC_SECRET_PORTAL}\"%g" "${AUTHJS}"
  }

