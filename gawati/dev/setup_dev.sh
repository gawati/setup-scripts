#!/bin/bash
# download and build code from git and add it to server

git clone https://github.com/gawati/gawati-data.git 49e9493  
git clone https://github.com/gawati/gawati-portal.git a3144df 

cd gawati-data && ant xar && cd ..
cd gawati-portal && ant xar && cd ..

#
# cp -p "`ls -dtr1 ./gawati-data/build/*.xar | tail -1`" ~/apps/autodeploy 
# cp -p "`ls -dtr1 ./gawati-portal/build/*.xar | tail -1`" ~/apps/autodeploy 
# service eXist-db restart
#
#


