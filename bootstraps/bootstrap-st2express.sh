#!/usr/bin/env bash

if [ `uname` != "Linux" ]; then
    echo "ERROR: bootstrap.sh is only supported on a Linux system."
    exit 1
fi

sudo rm -rf /opt/puppet

curl -sSL https://install.stackstorm.com/ | sudo sh
