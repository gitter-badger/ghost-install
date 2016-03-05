#!/bin/bash

#####################################
# Tested with CentOS 7 and systemd. #
#####################################

# Name        :ghost-install.sh
# Description :This script will install Ghost with a systemd controlled init
# Author      :Diogo Ferreira (uzantonomon)
# Date        :04/03/2016
# Version     :0.1
# Usage       :sudo ./ghost-install.sh

######################################################################################
# TODO: Improve input checks; Support more distributions; Support more init methods; #
#       Check if folders and files already exist; Add NGINX to the mix               #
######################################################################################

# Check for root
if [[ $EUID -ne 0 ]]; then
        echo "You need to be root to run this script..." 1>&2
        exit
fi

echo "Where do you want to install Ghost? (ex. /var/www)"
read GHOST_HOME

echo "Ghost will run under which user? (ex. ghost)"
read GHOST_USER

echo "Ghost will run under which group? (ex. ghost)"
read GHOST_GROUP

echo "Ghost will run on which port? (ex. 8080)"
read GHOST_PORT

echo "What's the name of the systemd service? (ex. ghost)"
read GHOST_SERVICE

# Check for dependencies

yum -y install epel-release
yum -y install nodejs npm

# Download and install Ghost
cd ~
curl -LOk https://ghost.org/zip/ghost-latest.zip
unzip ghost-latest.zip -d ghost

if [ ! -d "$GHOST_HOME" ]; then
        mkdir $GHOST_HOME
fi

yes | cp -r ghost $GHOST_HOME/ && rm -rf ghost
cd $GHOST_HOME/ghost
npm install --production
chown -R $GHOST_USER:$GHOST_GROUP $GHOST_HOME/ghost

# Configure Ghost
cd $GHOST_HOME/ghost
sed -e "s/127.0.0.1/0.0.0.0/" -e "s/2368/$GHOST_PORT/" < config.example.js > config.js

# Configure systemd
cat << SYSTEMD >> /etc/systemd/system/"$GHOST_SERVICE".service
[Unit]
Description=$GHOST_SERVICE
After=network.target

[Service]
Type=simple
WorkingDirectory=$GHOST_HOME/ghost/
User=$GHOST_USER
Group=$GHOST_GROUP
ExecStart=/usr/bin/npm start --production
ExecStop=/usr/bin/npm stop --production
Restart=always
SyslogIdentifier=$GHOST_SERVICE

[Install]
WantedBy=multi-user.target
SYSTEMD

# Add to boot and start the service
systemctl enable "$GHOST_SERVICE".service
systemctl start "$GHOST_SERVICE".service

echo "Ghost is now running on http://localhost:$GHOST_PORT"
echo "Go to http://localhost:$GHOST_PORT/ghost to create your account!"
