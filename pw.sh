#!/bin/bash

sed -i -e 's/username:password/'"${C9_USER}"':'"${C9_PASSWORD}"'/g' /etc/supervisor/conf.d/cloud9.conf
