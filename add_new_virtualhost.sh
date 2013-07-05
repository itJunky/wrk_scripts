#!/bin/bash
# Script for autoconfigure new virtual hosts

NH=new_host

### Checking parameters
if [ -z $1 ]; then
    echo Need parameters like this:
    echo add_new_vh.sh domain password
    exit
fi

### Cheking for exist
if [ -d /www/$1 ];then
    echo WARNING!!! This site already exist
    exit
fi

### Adding system user and catalog
useradd -c "WebSite User" -d /www/$1 --inactive 100 -m -U $1 
mkdir /www/$1/htdocs

### Setting DB Pass
if [ -z $2 ]
then
	PASS=`pwgen -1`
	echo -n "Password is: " 
	echo $PASS
else
	PASS=$2
fi

### Adding mysql user and database
mysql -e "CREATE USER '${1}'@'localhost' IDENTIFIED BY '${PASS}'"
DB=`echo $1 | sed "s/\./_/"`
mysql -e "CREATE DATABASE $DB"
mysql -e "GRANT ALL PRIVILEGES ON $DB.* TO '${1}'@'localhost'"
echo $1:$PASS | chpasswd 

### Creating virthost for Apache
cd /etc/apache2/vhosts.d/
cp new_host.conf_template $1.conf
replace "$NH" "$1" -- $1.conf

### Creating virthost for Nginx
cd /etc/nginx/vh/
cp new_host.conf_template $1.conf
replace "$NH" "$1" -- $1.conf

### Reloading web-servers
apache2ctl graceful
nginx -s reload 

