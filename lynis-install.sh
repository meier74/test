#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then echo You are not running as the root user.  Please try again with root privileges.;
   logger -t You are not running as the root user.  Please try again with root privileges.;
   exit 1;
fi;

# Add repo keys
wget -O - https://packages.cisofy.com/keys/cisofy-software-public.key | sudo apt-key add -

# Add repo to apt
echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list

# Update apt local database
apt update

# Install Lynix
apt install lynis rkhunter
