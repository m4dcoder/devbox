#!/usr/bin/env bash
set -e

if [ `uname` != "Linux" ]; then
    echo "ERROR: bootstrap.sh is only supported on a Linux system."
    exit 1
fi

USERNAME=admin
PASSWORD=StackSt0rm

# Assume BWC_LICENSE_KEY already exported to the environment.

cd /tmp
curl -sSL -O https://brocade.com/bwc/install/install.sh && chmod +x install.sh
./install.sh --staging --stable --user=${USERNAME} --password=${PASSWORD} --license=${BWC_LICENSE_KEY}
usermod -a -G st2packs vagrant
