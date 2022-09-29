#!/bin/bash

# This has been tested on the current version of filemaker server which is 19.5.4.400 
# This version of FM server can be installed on either Ubuntu 18.04 or 20.04

# If you're installing a new FM server, why do it on an older version of Ubuntu than you have to,
# so this script assumes and requires Ubuntu 20.04

# Set the download location for Filemaker server
DOWNLOAD = "https://downloads.claris.com/esd/fms_19.5.4.400_Ubuntu20.zip"
CERTBOT_HOSTNAME = "fm.testes.works"
HOSTNAME = "filemaker19"
TIMEZONE = "Australia/Melbourne"
GLANCES = "Yes"
ASSISTED_INSTALL = "Yes"
ASSISTED_PATH = "/home/ubuntu/fminstall/Assisted Install.txt"
FM_ADMIN = "admin"
FM_PASSWORD = "mnbmnb"
FM_PIN = "7176"


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
if [ -f .apt-upgrade ]; then
  sudo apt update && sudo apt upgrade -y
  if [ -f /var/run/reboot-required ]; then
    echo "Reboot is required. Reboot then rerun this script"
    exit 1
  fi
fi
touch .apt-update

if [ ! -f .timezone-set ]; then 
  if [ sudo timedatectl set-timezone $TIMEZONE ]; then
    timedatectl
  else    
    echo "Error setting timezone"
    exit 9
  fi
fi
touch .timezone-set

if [ ! -f .hostname-set ]; then
  if [ ! sudo hostnamectl set-hostname $HOSTNAME ]; then
    echo "Problem setting hostname"
    exit 9
  fi
fi
touch .hostname-set

#Install unzip if it's not installed.
type unzip > /dev/null 2>&1 || sudo apt install unzip -y

if [ "$GLANCES" = "Yes" ]; then
  type glances > /dev/null 2>&1 || sudo apt install glances -y
fi

if [ ! -f .filemaker-downloaded ]; then
  if [ mkdir ~/fminstall ]; then
    cd ~/fminstall
    if [ wget $DOWNLOAD ]; then
      unzip ./fms*
    else
      echo "Error downloading filemaker"
      exit 9
    fi
  else
    echo "Error creating Filemaker install directory"
    exit 9
  fi
fi
touch .filemaker-downloaded

if [ ! -f .filemaker-installed ]; then
  if [ "$ASSISTED_INSTALL" = "Yes" ]; then
    if [ ! sudo FM_ASSISTED_INSTALL=$ASSISTED_PATH apt install ./filemaker-server*.deb ]; then
      echo "Error installing Filemaker"
      exit 9
  else
    if [ ! sudo apt install ./filemaker-server*.deb ]; then
      echo "Error installing Filemaker"
      exit 9
    fi
   fi
fi
touch .filemaker-installed

if [ ! sudo snap install --classic certbot ]; then
  echo "Error installing Certbot"
  exit 9
fi
sudo ln -s /snap/bin/certbot /usr/bin/certbot
touch .certbot-installed

if [ ! -f .certbot-cert ]; then
  if [ ! sudo certbot certonly --webroot -w "/opt/FileMaker/FileMaker Server/NginxServer/htdocs/httpsRoot" -d $CERTBOT_HOSTNAME ]; then
    echo "Error getting certbot certificate"
    exit 9
  fi
fi
touch .certbot-cert

#fmsadmin doesn't seem to like getting the cert files from the letsencrypt directory, so copy them to /tmp first.
if [ ! -f .filemaker-cert ]; then
  $tmpcert = "/tmp/fm-cert"
  $letsencrypt = "/etc/letsencrypt/live/$CERTBOT_HOSTNAME"
  sudo mkdir -p $tmpcert
  sudo cp $letsencrypt/cert.pem $tmpcert
  sudo cp $letsencrypt/privkey.pem $tmpcert
  sudo cp $letsencrypt/fullchain.pem $tmpcert

  if [ ! sudo fmsadmin certificate import $tmpcert/cert.pem --keyfile $tmpcert/privkey.pem --intermediateCA $tmpcert/fullchain.pem -u $FM_ADMIN -p $FM_PASSWORD ]; then
    echo "Error installing filemaker certificate"
    exit 9
  fi
fi
touch .filemaker-cert


if [ ! -f .filemaker-installed-reboot ]; then
  echo "Reboot Server and then rerun this script"
  touch .filemaker-installed-reboot
  exit 0
fi





    
  
