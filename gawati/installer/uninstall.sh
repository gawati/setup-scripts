#!/bin/bash
service eXist-be stop
service eXist-st stop
service jetty-dev01 stop
yes | rm /etc/init.d/eXist-*
yes | rm /etc/init.d/jetty-dev01
yes | rm -rf /home/xstbe/apps
yes | rm -rf /home/xstst/apps
yes | rm -rf /home/dev01/apps
yes | rm -rf /var/www/html/alldev.gawati.org
yes | rm -rf /var/www/html/my.gawati.org
yes | rm -rf /root/import/*
yes | rm -rf /opt/Download/gawati-templates-*
yes | rm -rf /opt/Download/akn_*_sample-*
