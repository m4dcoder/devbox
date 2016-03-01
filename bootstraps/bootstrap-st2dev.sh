#!/usr/bin/env bash

if [ `uname` != "Linux" ]; then
    echo "ERROR: bootstrap.sh is only supported on a Linux system."
    exit 1
fi

GITKIT="git git-review"
DEVKIT="python-pip build-essential python-virtualenv python-dev make vim"
TOOLS="htop man manpages screen realpath"
SERVICES="mongodb-server rabbitmq-server postgresql apache2-utils nginx"

apt-get -y update
apt-get -y dist-upgrade
apt-get -y install ${GITKIT} ${DEVKIT} ${TOOLS} ${SERVICES}
apt-get clean all
apt-get autoremove
