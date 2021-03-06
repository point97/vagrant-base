#!/bin/bash

# Script to set up dependencies for Django on Vagrant.

PGSQL_VERSION=9.3
PGIS_VERSION=2.1

# Need to fix locale so that Postgres creates databases in UTF-8
cp -p /vagrant_data/etc-bash.bashrc /etc/bash.bashrc
locale-gen en_US.UTF-8
dpkg-reconfigure locales

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

apt-get update -y

# Useful tools
apt-get install -y vim git curl gettext

# Python dev packages
apt-get install -y build-essential python python-dev python-setuptools

# Dependencies for image processing with Pillow (drop-in replacement for PIL)
# supporting: jpeg, tiff, png, freetype, littlecms
apt-get install -y libjpeg-dev libtiff-dev zlib1g-dev libfreetype6-dev liblcms2-dev

# Geo
apt-get install -y python-gdal

# Node
apt-get install -y nodejs npm

# Redis
apt-get install -y redis-server

# Postgresql
if ! command -v psql; then
    apt-get install -y postgresql-$PGSQL_VERSION libpq-dev postgresql-client-common postgresql-contrib-$PGSQL_VERSION postgresql-$PGSQL_VERSION-postgis-$PGIS_VERSION
    cp /vagrant_data/pg_hba.conf /etc/postgresql/$PGSQL_VERSION/main/
    /etc/init.d/postgresql reload
fi

apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION" "postgresql-9.3-postgis-2.1"
# virtualenv global setup
if ! command -v pip; then
    easy_install -U pip
fi
if [[ ! -f /usr/local/bin/virtualenv ]]; then
    pip install virtualenv virtualenvwrapper
fi

# bash environment global setup
cp -p /vagrant_data/bashrc /home/vagrant/.bashrc

# standard django provisioning script
cp /vagrant_data/provision_django_17 /usr/local/bin/


# install our common Python packages in a temporary virtual env so that they'll get cached
if [[ ! -e /home/vagrant/.pip_download_cache ]]; then
    su - vagrant -c "mkdir -p /home/vagrant/.pip_download_cache && \
        virtualenv /home/vagrant/yayforcaching && \
        PIP_DOWNLOAD_CACHE=/home/vagrant/.pip_download_cache /home/vagrant/yayforcaching/bin/pip install -r /vagrant_data/common_requirements.txt && \
        rm -rf /home/vagrant/yayforcaching"
fi

# ElasticSearch
if ! command -v /usr/share/elasticsearch/bin/elasticsearch; then
    apt-get install -y openjdk-7-jre-headless
    echo "Downloading ElasticSearch..."
    wget -q https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.deb
    dpkg -i elasticsearch-1.3.2.deb
    update-rc.d elasticsearch defaults 95 10
    service elasticsearch start
    rm elasticsearch-1.3.2.deb
fi

# Cleanup
apt-get clean

echo "Zeroing free space to improve compression..."
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
