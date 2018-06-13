#!/bin/bash

function install {
  VERSION="${2}"

  installer_init "${1}" "" ""

  CFGSRC="${INSTALLER_HOME}/01"
  CFGDST="/etc/yum.repos.d"

  cfgwrite "${CFGSRC}/bintray.repo" "${CFGDST}" "bintray-rabbitmq.repo"
  yes | yum -y update

  OSinstall rabbitmq-server 1

  systemctl enable rabbitmq-server
  systemctl restart rabbitmq-server
  }

