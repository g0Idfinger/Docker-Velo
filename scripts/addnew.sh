#!/bin/bash
if [ `whoami` = root ]; then
	echo Please do not run this script as root or using sudo
	exit
fi
# import .env variables
set -o allexport; source ../.env; set +o allexport
# asks for customer name and puts into a var custname
read -p 'Deployment Name, used to be prefix to domain name: ' custnamel
custname=${custnamel,,}
#copies config to cust.txt
mkdir ../containers/$custname-velo
cp ../staging/newvelo.txt ../staging/$custname-velo.txt
# replaces txt in file to complete config
sed -i "s/CUSTOMER/$custname-velo/g" ../staging/$custname-velo.txt
# copies dockerfile and entrypoint to customer config
cp ../staging/Dockerfile ../containers/$custname-velo/
cp ../staging/entrypoint ../containers/$custname-velo/
#adds the config file to the docker compose file
cat ../staging/$custname-velo.txt >> ../docker-compose.yml
#configures dns
dnsrecord=$custname-velo.$DOMAINNAME
cloudflare_auth_key=$CLOUDFLARE_TOKEN
zoneid=$(curl -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" | jq -r  '{"result"}[] | .[0] | .id')
# update the record
curl -s PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
  -H "Authorization: Bearer $cloudflare_auth_key" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"CNAME\",\"name\":\"$dnsrecord\",\"content\":\"$DOMAINNAME\",\"ttl\":1,\"proxied\":true}" | jq
#brings up the new container to stage files
cd ..
docker compose up -d
#allows time for velo to build
sleep 15
#stops new container
docker stop $custname-velo
#customizes velo config for customer info
sed -i 's/bind_port: 8889/bind_port: 8889\n  use_plain_http: true/g' containers/$custname-velo/server.config.yaml
sed -i 's/bind_port: 8000/bind_port: 8889\n  use_plain_http: true/g' containers/$custname-velo/server.config.yaml
sed -i 's/use_self_signed_ssl: true/use_self_signed_ssl: false/g' containers/$custname-velo/server.config.yaml
sed -i 's/use_self_signed_ssl: true/use_self_signed_ssl: false/g' containers/$custname-velo/client.config.yaml
#starts new container
docker compose up -d
#clean up files
rm staging/$custname-velo.txt
#Create username
read -p 'Velociraptor Admin username: ' velouser
# Generate Password
val1=`shuf -i 10-99 -n1`
val2=`shuf -i 10-99 -n1`
xkpass=`xkpassword`
passwd="$val1.$xkpass.$val2"
#sets username and password in velo DB
docker exec -it $custname-velo ./velociraptor --config server.config.yaml user add $velouser $passwd --role administrator
#prints username and password
echo -e "\e[1;42m open browser and go to https://$custname-velo.$DOMAINNAME, username is $velouser password is $passwd \e[0m"
