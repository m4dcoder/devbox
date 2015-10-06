#!/usr/bin/env bash

if [ `uname` != "Linux" ]; then
    echo "ERROR: bootstrap.sh is only supported on a Linux system."
    exit 1
fi

DEVKIT="python-pip build-essential python-virtualenv python-dev git make"
TOOLS="htop man manpages screen realpath"

apt-get -y update
apt-get -y dist-upgrade
apt-get -y install ${DEVKIT} ${TOOLS}
apt-get clean all
apt-get autoremove
