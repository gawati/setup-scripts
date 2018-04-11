function postinstall {
  MAINJS="${EDITROOT}/static/keycloak.json"
  vardebug MAINJS
  [ -f "${MAINJS}" ] || bail_out "File >${MAINJS}< missing."
  sed -i'' "s%realm\([ \"]*\): *\"\([^\"]*\)\"%realm\1:\"${KC_REALM}\"%g" "${MAINJS}"
  sed -i'' "s%url\([ \"]*\): *\"\([^\"]*\)\"%url\1:\"${KC_URL}\"%g" "${MAINJS}"
  sed -i'' "s%secret\([ \"]*\): *\"\([^\"]*\)\"%secret\1:\"${KC_SECRET}\"%g" "${MAINJS}"
  }

