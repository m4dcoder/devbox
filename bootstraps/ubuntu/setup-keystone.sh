#!/bin/bash

set -e

INSTALL_DIR=/opt/openstack
INSTALL_PATH=/opt/openstack/keystone
CLIENT_INSTALL_PATH=/opt/openstack/python-openstackclient
VENV_PATH=${INSTALL_PATH}/.venv
ADMIN_PASSWORD=secrete

sudo mkdir -p ${INSTALL_DIR}
sudo chown -R vagrant:vagrant ${INSTALL_DIR}

sudo service apache2 stop || true
sudo service postgresql restart

# Download client source.
if [[ ! -d ${CLIENT_INSTALL_PATH} && ! -h ${CLIENT_INSTALL_PATH} ]]; then
    git clone https://github.com/openstack/python-openstackclient.git ${INSTALL_DIR}
fi

# Install client.
cd ${CLIENT_INSTALL_PATH}
sudo pip install -r requirements.txt
sudo python setup.py develop

# Download source.
if [[ ! -d ${INSTALL_PATH} && ! -h ${INSTALL_PATH} ]]; then
    git clone https://github.com/openstack/keystone.git ${INSTALL_DIR}
fi

# Setup virtualenv.
cd ${INSTALL_PATH}

if [[ ! -d ${VENV_PATH} ]]; then
    virtualenv --no-site-packages .venv
fi

. ${VENV_PATH}/bin/activate
pip install psycopg2
pip install -r requirements.txt
pip install -r test-requirements.txt
python setup.py develop
deactivate

# Initialize configuration values.
ADMIN_TOKEN=`openssl rand -hex 10`
DB_NAME="keystone"
DB_USER="keystone"
DB_PASSWORD=`openssl rand -hex 10`
DB_CONN_STR="postgresql:\/\/keystone:${DB_PASSWORD}@localhost\/keystone"

# Update keystone configuration file.
CONFIG_DIR=/etc/keystone
SAMPLE_CONFIG_FILE="${CONFIG_DIR}/keystone.conf.sample"
CONFIG_FILE="${CONFIG_DIR}/keystone.conf"
sudo mkdir -p ${CONFIG_DIR}
sudo cp ${INSTALL_PATH}/etc/* ${CONFIG_DIR}
sudo cp ${SAMPLE_CONFIG_FILE} ${CONFIG_FILE}
sudo chown -R keystone:keystone ${CONFIG_FILE}
sudo sed -i -e "s/#admin_token = <None>/admin_token = ${ADMIN_TOKEN}/g" ${CONFIG_FILE}
sudo sed -i -e "s/#connection = <None>/connection = ${DB_CONN_STR}/g" ${CONFIG_FILE}

# Setup database.
sudo rm -f /var/lib/keystone/keystone.db
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${DB_NAME};"
sudo -u postgres psql -c "DROP USER IF EXISTS ${DB_USER};"
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';"
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
sudo ${INSTALL_PATH}/.venv/bin/keystone-manage --config-file ${CONFIG_FILE} db_sync

# Setup keys.
sudo rm -rf /etc/keystone/fernet-keys
sudo rm -rf /etc/keystone/credential-keys
sudo ${INSTALL_PATH}/.venv/bin/keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo ${INSTALL_PATH}/.venv/bin/keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap credentials.
sudo ${INSTALL_PATH}/.venv/bin/keystone-manage bootstrap --bootstrap-password ${ADMIN_PASSWORD} --bootstrap-admin-url http://localhost:35357/v3/ --bootstrap-internal-url http://localhost:5000/v3/ --bootstrap-public-url http://localhost:5000/v3/ --bootstrap-region-id RegionOne

# Configure apache.
sudo apt-get -y install apache2 libapache2-mod-wsgi
echo "manual" | sudo tee /etc/init/apache2.override > /dev/null
sudo a2enmod ssl

sudo rm /etc/apache2/sites-enabled/000-default.conf || true 

APACHE_PORTS_CONFIG=/etc/apache2/ports.conf
cat <<APACHE_PORTS_CONFIG | sudo tee ${APACHE_PORTS_CONFIG}
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

#Listen 80

#<IfModule ssl_module>
#   Listen 443
#</IfModule>

#<IfModule mod_gnutls.c>
#   Listen 443
#</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
APACHE_PORTS_CONFIG

APACHE_KEYSTONE_SITE=/etc/apache2/sites-available/keystone.conf
cat <<APACHE_KEYSTONE_SITE | sudo tee ${APACHE_KEYSTONE_SITE}
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP} python-path=${INSTALL_PATH}:${INSTALL_PATH}/.venv/local/lib/python2.7/site-packages
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / ${INSTALL_PATH}/.venv/local/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688

    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory ${INSTALL_PATH}/.venv/local/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP} python-path=${INSTALL_PATH}:${INSTALL_PATH}/.venv/local/lib/python2.7/site-packages
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / ${INSTALL_PATH}/.venv/local/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688

    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory ${INSTALL_PATH}/.venv/local/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

Alias /identity ${INSTALL_PATH}/.venv/local/bin/keystone-wsgi-public
<Location /identity>
    SetHandler wsgi-script
    Options +ExecCGI

    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
</Location>

Alias /identity_admin ${INSTALL_PATH}/.venv/local/bin/keystone-wsgi-admin
<Location /identity_admin>
    SetHandler wsgi-script
    Options +ExecCGI

    WSGIProcessGroup keystone-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
</Location>
APACHE_KEYSTONE_SITE

sudo rm /etc/apache2/sites-enabled/keystone.conf || true
sudo ln -s ${APACHE_KEYSTONE_SITE}  /etc/apache2/sites-enabled/keystone.conf
sudo service apache2 restart

# Setup client environment.
KEYSTONERC=${CONFIG_DIR}/keystonerc
cat <<KEYSTONERC | sudo tee ${KEYSTONERC}
# openstack client
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=http://localhost:5000/v3
export OS_DEFAULT_DOMAIN=default
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASSWORD}
export OS_PROJECT_NAME=admin
KEYSTONERC

# Setup mistral.
sudo cp ${KEYSTONERC} /tmp/keystonerc
sudo chown vagrant:vagrant /tmp/keystonerc
source /tmp/keystonerc
openstack service create --name=mistral --description="Mistral Workflow Service" workflow
openstack endpoint create --region RegionOne workflow public "http://localhost:8989"
openstack endpoint create --region RegionOne workflow admin "http://localhost:8989"
openstack endpoint create --region RegionOne workflow internal "http://localhost:8989"
openstack user create mistral --project st2 --password "m1stral"
openstack role add --user mistral --project st2 admin
