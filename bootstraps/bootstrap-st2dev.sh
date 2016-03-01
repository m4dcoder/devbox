#!/usr/bin/env bash

if [ `uname` != "Linux" ]; then
    echo "ERROR: bootstrap.sh is only supported on a Linux system."
    exit 1
fi

GITKIT="git git-review"
DEVKIT="python-pip build-essential python-virtualenv python-dev make vim"
ST2KIT="libffi-dev libssl-dev"
TOOLS="htop man manpages screen realpath"
SERVICES="rabbitmq-server postgresql apache2-utils nginx"

apt-get -y update
apt-get -y dist-upgrade
apt-get -y install ${GITKIT} ${DEVKIT} ${ST2KIT} ${TOOLS} ${SERVICES}
apt-get clean all
apt-get autoremove

# MongoDB 3.x
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
apt-get -y update
apt-get install -y mongodb-org
