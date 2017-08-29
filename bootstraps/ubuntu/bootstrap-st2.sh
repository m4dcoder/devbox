#!/usr/bin/env bash
set -e

if [ `uname` != "Linux" ]; then
    echo "ERROR: bootstrap.sh is only supported on a Linux system."
    exit 1
fi

ST2_BOOTSTRAP="/tmp/st2_bootstrap.sh"

wget -O ${ST2_BOOTSTRAP} https://raw.githubusercontent.com/StackStorm/st2-packages/master/scripts/st2_bootstrap.sh
chmod +x ${ST2_BOOTSTRAP}
bash ${ST2_BOOTSTRAP} --staging --stable --user=admin --password=StackSt0rm
usermod -a -G st2packs vagrant
