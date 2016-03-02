#!/usr/bin/env bash

if [ `uname` != "Linux" ]; then
    echo "ERROR: bootstrap.sh is only supported on a Linux system."
    exit 1
fi

DEVKIT="git git-review build-essential make vim"
PYDEVKIT="python-pip python-virtualenv python-dev python3-dev python-tox"
ST2KIT="libffi-dev libssl-dev"
TOOLS="htop man manpages screen realpath"
SERVICES="rabbitmq-server postgresql apache2-utils nginx"

apt-get -y update
apt-get -y dist-upgrade
apt-get -y install ${DEVKIT} ${PYDEVKIT} ${ST2KIT}
apt-get -y install ${TOOLS} ${SERVICES}
apt-get clean all
apt-get autoremove

# MongoDB 3.x
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
apt-get -y update
apt-get install -y mongodb-org

# StackStorm SSH system user
useradd stanley
mkdir -p /home/stanley/.ssh
chmod 0700 /home/stanley/.ssh
ssh-keygen -f /home/stanley/.ssh/stanley_rsa -P ""
sh -c 'cat /home/stanley/.ssh/stanley_rsa.pub >> /home/stanley/.ssh/authorized_keys'
chmod 0600 /home/stanley/.ssh/authorized_keys
chown -R stanley:stanley /home/stanley
sh -c 'echo "stanley    ALL=(ALL)       NOPASSWD: SETENV: ALL" >> /etc/sudoers.d/st2'
chmod 0440 /etc/sudoers.d/st2
cp /home/stanley/.ssh/stanley_rsa /home/vagrant/.ssh/stanley_rsa
chown vagrant:vagrant /home/vagrant/.ssh/stanley_rsa
