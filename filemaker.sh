#!/bin/bash

# This has been tested on the current version of filemaker server which is 19.5.4.400 
# This version of FM server can be installed on either Ubuntu 18.04 or 20.04

# If you're installing a new FM server, why do it on an older version of Ubuntu than you have to,
# so this script assumes and requires Ubuntu 20.04

# Set the download location for Filemaker server
DOWNLOAD = "https://downloads.claris.com/esd/fms_19.5.4.400_Ubuntu20.zip"
HOSTNAME = "filemaker19"
TIMEZONE = "Australia/Melbourne"
GLANCES = "Yes"


#Check we are on the correct version of Ubuntu
if [ -f /etc/os-release ]; then
  . /etc/os-release
  VER=$VERSION_ID
fi

if [ "$VER" != "22.04" ]; then
  echo "Wrong version of Ubuntu. Must be 20.04"
  echo "You are running" $VER 
  exit 9
fi

#Make sure system is up to date and reboot if necessary
sudo apt update && sudo apt upgrade -y

if [ -f /var/run/reboot-required ]; then
        echo "Reboot is required. Reboot then rerun this script"
        exit 1
fi

if [ sudo timedatectl set-timezone $TIMEZONE ]; then
        timedatectl
else    
        echo "Error setting timezone"
        exit 9
fi      

sudo hostnamectl set-hostname $HOSTNAME
