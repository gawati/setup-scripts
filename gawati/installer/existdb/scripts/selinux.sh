OSinstall policycoreutils-devel 1

function postinstall {

  for THISPORT in "${EXIST_PORT}" "${EXIST_SPORT}" ; do
    SEPORT="`sepolicy network -p ${THISPORT} | grep -v 'unreserved_port_t' | grep ' tcp ' | cut -d ' ' -f 3`"
    vardebug THISPORT SEPORT
    [ "${SEPORT}" = "" ] && continue
    [ "${SEPORT}" = "${INSTANCE}_port_t" ] && continue
    message 3 "TCP Port >${THISPORT}< for >${INSTANCE}< already assigned to >${SEPORT}<. Please choose a port not assigned in 'semanage port -l'."
    return
    done

  seinfo -t${INSTANCE}_t >/dev/null && message 1 "SElinux policy named >${INSTANCE}_t< already exists. Skipping." || {
    MYTEMPDIR="/tmp/$$.`timestamp`"
    mkdir -p "${MYTEMPDIR}"
    pushd "${MYTEMPDIR}" >/dev/null
    sepolicy generate --init -n "${INSTANCE}" "${INSTANCE_PATH}/tools/yajsw/wrapper.jar"
    echo "type ${INSTANCE}_port_t;" >> "${INSTANCE}.te"
    echo "corenet_port(${INSTANCE}_port_t)" >> "${INSTANCE}.te"
    ./${INSTANCE}.sh
    popd >/dev/null
    }

  semanage port -a -t "${INSTANCE}_port_t" -p tcp "${EXIST_PORT}"
  semanage port -a -t "${INSTANCE}_port_t" -p tcp "${EXIST_SPORT}"
  }

