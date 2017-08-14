#!/bin/bash

# name of the python virtual-env for fabric
FABVENV=venv_fabric

# python pip and fab relative paths
FABPY=./$FABVENV/bin/python
FABPIP=./$FABVENV/bin/pip
FAB=./$FABVENV/bin/fabric

# install pip
curl -z  -"get-pip.py"  "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py && rm -rf get-pip.py

# install virtualenv
pip install virtualenv

# install the fabric virtual python
virtualenv $FABVENV

# install fabric in the virtual env, we dont
# want to mess with the system python
$FABPIP install fabric
echo "$FAB \$*" > ./fab && chmod ug+x ./fab

