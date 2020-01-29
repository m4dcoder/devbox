#!/usr/bin/env bash

if [ `uname` != "Linux" ]; then
    echo "ERROR: bootstrap.sh is only supported on a Linux system."
    exit 1
fi

DISTRO=`lsb_release -a 2>&1 | grep Codename | grep -v "LSB" | awk '{print $2}'`
ST2KIT="libffi-dev libssl-dev libpq-dev"
SERVICES="rabbitmq-server postgresql apache2-utils nginx"

MONGODB_PASSWORD="StackSt0rm"
RABBITMQ_PASSOWRD="StackSt0rm"


# Install programs and services
apt-get -y install ${ST2KIT} ${SERVICES}


# Setup rabbitmqadmin
rabbitmq-plugins enable rabbitmq_management
service rabbitmq-server restart
curl -sS -o /usr/bin/rabbitmqadmin http://127.0.0.1:15672/cli/rabbitmqadmin
chmod 755 /usr/bin/rabbitmqadmin
rabbitmqctl add_user stackstorm ${RABBITMQ_PASSOWRD}
rabbitmqctl authenticate_user stackstorm ${RABBITMQ_PASSOWRD}
rabbitmqctl delete_user guest
rabbitmqctl set_permissions -p / stackstorm ".*" ".*" ".*"

# MongoDB 3.4
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu ${DISTRO}/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
apt-get -y update
apt-get install -y mongodb-org

if [[ "$DISTRO" == 'trusty' ]]; then
    sudo service mongod restart
else
    sudo systemctl enable mongod
    sudo systemctl start mongod
fi

sleep 5

mongo <<EOF
use admin;
db.createUser({
    user: "admin",
    pwd: "${MONGODB_PASSWORD}",
    roles: [
        { role: "userAdminAnyDatabase", db: "admin" }
    ]
});
quit();
EOF

mongo <<EOF
use st2;
db.createUser({user: "stackstorm", pwd: "${MONGODB_PASSWORD}", roles: [{ role: "readWrite", db: "st2" }]});
quit();
EOF

sudo sh -c 'echo "security:\n  authorization: enabled" >> /etc/mongod.conf'

if [[ "$DISTRO" == 'trusty' ]]; then
    sudo service mongod restart
else
    sudo systemctl restart mongod
fi


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
