#!/bin/sh
if [ `whoami` = root ]; then
	echo Please do not run this script as root or using sudo
	exit
fi
#updates ubuntu

sudo apt update && sudo apt upgrade -y
#installs prerequisites
sudo apt install apt-transport-https ca-certificates curl software-properties-common ftp-upload ruby-dev gnupg lsb-release -y
sudo gem install xkpassword
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
#Build out .env file
puid=$(id -u)
echo $puid
echo PUID=$puid >> ../.env
dockerid=`awk -F\: '/docker/ {print $3}' /etc/group`
echo "PGID=$dockerid" >> ../.env
echo 'TZ="America/Phoenix"' >> ../.env
echo "USERDIR=$HOME" >> ../.env
dir=${PWD%/*}
echo "DOCKERDIR=$dir" >> ../.env
echo "VELOX_ROLE=administrator" >> ../.env
read -p 'Domain Root,example example.com: ' domainroot
echo "DOMAINNAME=$domainroot" >> ../.env
read -p 'Cloudflare Email:' cfemail
echo "CLOUDFLARE_EMAIL=$cfemail" >> ../.env
read -p 'CLOUDFLARE TOKEN:' cftoken
echo "CLOUDFLARE_TOKEN=$cftoken" >> ../.env
read -p 'CLOUDFLARE API KEY: ' cfapi
echo "CLOUDFLARE_API_KEY=$cfapi" >> ../.env
#read -p 'Velo Username:' veloun
#echo "VELOX_USER=$veloun" >> ../.env
#read -p 'Velo Password: ' velopw
#echo "VELOX_PASSWORD=$velopw" >> ../.env
#add user to docker group
sudo usermod -aG docker ${USER}
sudo chmod 666 /var/run/docker.sock
#create folder structure
mkdir ../appdata/traefik2/acme
touch ../appdata/traefik2/acme/acme.json
chmod 600 ../appdata/traefik2/acme/acme.json
touch ../appdata/traefik2/traefik.log
#docker network create --gateway 192.168.90.1 --subnet 192.168.90.0/24 t2_proxy
cd ..
mkdir velo-staging/output/
cd $dir
cp docker-compose.yml.bak docker-compose.yml
docker compose up -d
