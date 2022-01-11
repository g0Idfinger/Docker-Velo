#!/bin/sh
if [ `whoami` = root ]; then
	echo Please do not run this script as root or using sudo
	exit
fi
#updates ubuntu
sudo apt update && sudo apt upgrade -y
#installs prerequisites
sudo apt install apt-transport-https ca-certificates curl software-properties-common jq ruby-dev -y
sudo gem install xkpassword
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce -y
#install docker compose v2
# create the docker plugins directory if it doesn't exist yet
mkdir -p /home/$USER/.docker/cli-plugins
# download the CLI into the plugins directory
curl -sSL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o /home/$USER/.docker/cli-plugins/docker-compose
# make the CLI executable
chmod +x /home/$USER/.docker/cli-plugins/docker-compose
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
read -p 'Domain Root,example mydomain.com: ' domainroot
echo "DOMAINNAME=$domainroot" >> ../.env
read -p 'Cloudflare Email:' cfemail
echo "CLOUDFLARE_EMAIL=$cfemail" >> ../.env
read -p 'CLOUDFLARE TOKEN:' cftoken
echo "CLOUDFLARE_TOKEN=$cftoken" >> ../.env
read -p 'CLOUDFLARE API KEY: ' cfapi
echo "CLOUDFLARE_API_KEY=$cfapi" >> ../.env
#add user to docker group
sudo usermod -aG docker ${USER}
sudo chmod 666 /var/run/docker.sock
#create folder structure
mkdir ../containers/traefik2/acme
touch ../containers/traefik2/acme/acme.json
chmod 600 ../containers/traefik2/acme/acme.json
touch ../containers/traefik2/traefik.log
docker network create --gateway 192.168.90.1 --subnet 192.168.90.0/24 t2_proxy
cd ..
docker compose up -d
