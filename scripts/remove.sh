#!/bin/bash
#i import variables from .env
set -o allexport; source ../.env; set +o allexport
# set customer name to a var
read -p 'Deployment name to be removed: ' custname
# stop docker container
docker stop $custname-velo
# find the line in docker-compose.yml where config starts
linestart=$(($(grep -n -m 1 $custname-velo: ../docker-compose.yml |cut -d ':' -f1)-1))
# find where the config ends
lineend=$(($linestart+35))
# remove the config from docker-compose.yml
sed -i "$linestart,$lineend d" ../docker-compose.yml
# Cloudflare zone is the zone which holds the record
dnsrecord=$custname-velo.$DOMAINNAME
echo $dnsrecord
# Cloudflare authentication details
## keep these private
cloudflare_auth_key=$CLOUDFLARE_TOKEN

# get the dns zone id
zoneid=$(curl -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" | jq -r  '{"result"}[] | .[0] | .id')

#get dns record id
recordid=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=CNAME&name=$dnsrecord&match=all" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" | jq -r  '{"result"}[] | .[0] | .id')

# delete the record
curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$recordid" \
  -H "Authorization: Bearer $cloudflare_auth_key" \
  -H "Content-Type: application/json" | jq
# cleanup files and folders
sudo rm -rf ../containers/$custname-velo
#rm $custname-velo.*
#rm Dockerfile-$custname-velo
#rm entrypoint-$custname-velo

# cleanup up docker images
cd ..
docker compose up -d --remove-orphans
