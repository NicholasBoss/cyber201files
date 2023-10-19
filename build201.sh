#!/bin/bash
# Installs terraform, creates a folder, and deploys an EC2 AWS Linux Mate server, juice shop on an internal ip, and deploys it
# Give execute permissions to this file and run it:
#  curl -O https://byui-cloud.github.io/cyber-201-materials/aws-terraform/build201.sh && chmod a+x build201.sh && ./build201.sh
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
mkdir ~/bin
ln -s ~/.tfenv/bin/* ~/bin/
tfenv install
tfenv use

# Next get the terminate.sh file to delete everything when done
# Give execute permissions to this file: chmod a+x terminate.sh
curl -O https://byui-cloud.github.io/cyber-201-materials/aws-terraform/terminate.sh && chmod a+x terminate.sh

mkdir byuieast
cd byuieast

curl -O https://byui-cloud.github.io/cyber-201-materials/aws-terraform/mainbastionjuiceboxnateip.tf
terraform init
terraform apply -auto-approve

cd ..

# Download the script to connect via ssh and give execute permissions to this file: chmod a+x run.sh
curl -O https://byui-cloud.github.io/cyber-201-materials/aws-terraform/run201.sh && chmod a+x run201.sh

echo "Run ./terminate.sh when you are done to save your budget." 
echo "If you have trouble connecting, wait a minute and try ./run.sh again."
read -n 1 -s -r -p $'\nPress any key to connect to the instance/VM (./run201.sh) or CTRL + C to stop...'

# Next run the run.sh file to connect to the servers
./run201.sh
