#!/bin/bash

logfile="/home/panadmin/install-log.txt"
exec &>> $logfile
printf "***** START *****" >> $logfile

# This script will pre-install all the required tools on the management host
# Currently installed tools
# - Ansible
# - Terraform

# Curl mod, add newline characater after output
sudo -u panadmin echo '-w "\n"' >> /home/panadmin/.curlrc

# Install Ansible
printf "***** apt update *****" >> $logfile
apt-get update >> $logfile
printf "***** cd *****" >> $logfile
cd /usr/bin >> $logfile
printf "***** python link *****" >> $logfile
ln -sf ./python3 ./python >> $logfile
printf "***** apt installs *****" >> $logfile
apt-get install build-essential libssl-dev libffi-dev python-dev python3-pip software-properties-common -y >> $logfile
printf "***** install Ansible *****" >> $logfile
pip3 install ansible >> $logfile
# Install dependencies for PAN-OS Ansible
printf "***** download list of PAN-OS Ansible dependencies *****" >> $logfile
wget https://raw.githubusercontent.com/PaloAltoNetworks/pan-os-ansible/develop/requirements.txt >> $logfile
printf "***** install PAN-OS Ansible dependencies *****" >> $logfile
pip install -r requirements.txt >> $logfile

# Install PAN-OS Ansible Collection
printf "***** install PAN-OS Ansible Collection *****" >> $logfile
sudo -u panadmin ansible-galaxy collection install paloaltonetworks.panos >> $logfile

# Install Terraform
printf "***** download Terraform *****" >> $logfile
wget https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip -O /tmp/terraform.zip >> $logfile
printf "***** apt installs *****" >> $logfile
apt-get install unzip libxml2-utils -y >> $logfile
printf "***** unzip Terraform *****" >> $logfile
sudo unzip /tmp/terraform.zip -d /usr/local/bin >> $logfile
printf "***** make Terraform executable *****" >> $logfile
sudo chmod +x /usr/local/bin/terraform >> $logfile

printf "***** DONE *****" >> $logfile
