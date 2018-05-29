#!/bin/bash

apt-get install -y python-setuptools
easy_install pip
pip install -U pip
pip install -U virtualenv
virtualenv --python=python2 /workspace/.c9/python2
source /workspace/.c9/python2/bin/activate
apt-get install -y python-dev
mkdir /tmp/codeintel
pip download -d /tmp/codeintel codeintel==0.9.3
cd /tmp/codeintel
tar xf CodeIntel-0.9.3.tar.gz
mv CodeIntel-0.9.3/SilverCity CodeIntel-0.9.3/silvercity
tar czf CodeIntel-0.9.3.tar.gz CodeIntel-0.9.3
pip install -U --no-index --find-links=/tmp/codeintel codeintel                                                              
