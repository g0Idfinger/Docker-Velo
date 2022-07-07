#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo ""
   echo ""
   echo "${green}Creates new instance of Velociraptor."
   echo
   echo "Syntax: ./addnew.sh [-c CUSTOMERNAME] [-g] [-p PASSWORD OF 30 CHARACTERS OR MORE]"
   echo "options:"
   echo "-c     name of customer"
   echo "-g     Generates password"
   echo "-p     Provide a password manually(must be 30 characters or more)"
   echo
   echo "./addnew.sh -c CUSTOMERNAME -p PASSWORD"
   echo "or"
   echo "./addnew.sh -c CUSTOMERNAME -g${reset}"
}
#checks for arguments
g_used=false p_used=false
while getopts ":h:c:gp:" option; do
        case $option in
                h) # display help
                        Help
                        exit;;
                c) # customer name
                        custname=${OPTARG,,};;
                g) # generate password
                        g_used=true
                        val1=`shuf -i 10-99 -n1`
                        val2=`shuf -i 10-99 -n1`
                        xkpass=`xkpassword`
                        passwd="$val1.$xkpass.$val2";;
                        #echo "$passwd";;
                p) # User input password
                        p_used=true
                        if [[ ${#OPTARG} -lt 30 ]]; then
                                echo "${red}Password needs to be 30 characters or longer${reset}"
                                exit
                        else
                                passwd=$OPTARG
                        fi;;
                \?) # invalid Option
                        echo "${red}Error: invlaid option${reset}"
                        exit;;
        esac
done
if "$g_used" && "$p_used"; then
        echo "${red}Use ether -g or -p  not both${reset}"
        exit
fi
# Mandatory Arguments
if [ ! "$custname" ] || [ ! "$passwd" ]; then
        echo "${red}Arguments -c and -g or arguments -c and -p must be provided${reset}"
        Help
        exit 1
fi

if [ `whoami` = root ]; then
	echo Please do not run this script as root or using sudo
	exit
fi
# import .env variables
set -o allexport; source ../.env; set +o allexport
#copies config to cust.txt
mkdir $DOCKERDIR/containers/$custname-velo
cp $DOCKERDIR/staging/newvelo.txt DOCKERDIR/staging/$custname-velo.txt
# replaces txt in file to complete config
sed -i "s/CUSTOMER/$custname-velo/g" $DOCKERDIR/staging/$custname-velo.txt
# copies dockerfile and entrypoint to customer config
cp $DOCKERDIR/staging/Dockerfile $DOCKERDIR/containers/$custname-velo/
cp $DOCKERDIR/staging/entrypoint $DOCKERDIR/containers/$custname-velo/
#adds the config file to the docker compose file
cat $DOCKERDIR/staging/$custname-velo.txt >> $DOCKERDIR/docker-compose.yml
#brings up the new container to stage files
cd $DOCKERDIR
docker compose up -d
#stop script while new container builds
echo "${red} __     __     __ __           ___       "
echo "${red}|__)|  |_  /\ (_ |_   |  | /\ | |        "
echo "${red}|   |__|__/--\__)|__  |/\|/--\| |        "
echo "${reset}                                       "
sleep 60
#stops new container
docker stop $custname-velo
#customizes velo config for customer info
sed -i 's/bind_port: 8889/bind_port: 8889\n  use_plain_http: true/g' $DOCKERDIR/containers/$custname-velo/server.config.yaml
sed -i 's/bind_port: 8000/bind_port: 8889\n  use_plain_http: true/g' $DOCKERDIR/containers/$custname-velo/server.config.yaml
sed -i 's/use_self_signed_ssl: true/use_self_signed_ssl: false/g' $DOCKERDIR/containers/$custname-velo/server.config.yaml
sed -i 's/use_self_signed_ssl: true/use_self_signed_ssl: false/g' $DOCKERDIR/containers/$custname-velo/client.config.yaml
#starts new container
docker compose up -d
rm staging/$custname-velo.txt
#Create username
read -p 'Velociraptor Admin username: ' velouser
#sets username and password in velo DB
docker exec -it $custname-velo ./velociraptor --config server.config.yaml user add $velouser $passwd --role administrator
#prints username and password
echo "Open browser and go to ${red}https://$custname-velo.$DOMAINNAME${reset}, username is ${red}$velouser ${reset}password is ${red}$passwd${reset}"
