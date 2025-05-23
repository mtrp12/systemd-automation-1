#!/usr/bin/env bash

log(){
  echo -e "\e[95mTEARDOWN: $1\e[0m"
}

log "Stopping services..."
systemctl stop mysql
systemctl stop node

log "Disabling services..."
systemctl disable mysql
systemctl disable mysql-check
systemctl disable node

log "Removing packages..."
apt purge mysql-* git nodejs -y
apt autoremove -y

log "Removing files..."
rm /usr/local/bin/mysql-check.sh 
rm /etc/systemd/system/node.service 
rm /etc/systemd/system/mysql-check.service 
rm -rf /home/nodejs/app/
rm -rf /etc/mysql /var/lib/mysql
rm -rf /var/lib/mysql*

log "Removing users..."
userdel mysql
groupdel mysql
userdel -r nodejs

log "Teardown complete"