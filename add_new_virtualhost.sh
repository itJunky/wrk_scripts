#!/bin/bash
# Script for autoconfigure new virtual hosts
#
# https://raw.githubusercontent.com/itJunky/wrk_scripts/master/add_new_virtualhost.sh

set -e

BACKEND=fpm
NH=new_host

### Checking parameters
if [ -z $1 ]; then
    	echo Need parameters like this:
    	echo add_new_vh.sh domain password
    	exit
else
        DOMAIN=$1
fi

### Cheking for exist
if [ -d /www/$1 ];then
    	echo WARNING!!! This site already exist
    	exit
fi

### Setting Password ###
if [ -z $2 ]
then
        PASS=`pwgen -1`
        echo "Password is: ${PASS}" 
else
        PASS=$2
fi

function make_system_user {
        PASS_HASH=$(python -c "import crypt; print crypt.crypt(\"$2\", \"\$6\$$(pwgen -1)\")")
        ### Adding system user and catalog
        useradd -c "WebSite User" -d /www/$1 --inactive 100 -m -p ${PASS_HASH} -U $1
        mkdir /www/$1/htdocs
}

function make_db {
        ### Adding mysql user and database
        mysql -e "CREATE USER '$1'@'localhost' IDENTIFIED BY '$2'"
        DB=`echo $1 | sed "s/\./_/"`
        mysql -e "CREATE DATABASE ${DB}"
        mysql -e "GRANT ALL PRIVILEGES ON ${DB}.* TO '$1'@'localhost'"
        echo "Database user: $1"
        echo "Database is: ${DB}"
        #echo $1:$2 | chpasswd 
}

function make_nginx_vh {
        ### Creating virthost for Nginx
        pushd . > /dev/null
        cd /etc/nginx/vh/
        if [ $BACKEND = "fpm" ]
        then
                cp ${NH}.template_fpm ${1}.conf
        else
                cp ${NH}.template_apache ${1}.conf
        fi
        replace "$NH" "$1" -- ${1}.conf
        popd . > /dev/null
}

function make_backend {
        if [ $BACKEND = "fpm" ]
        then
                echo "using fpm"
                pushd . > /dev/null
                cd /etc/php/fpm-php5.5/fpm.d/
                cp ${NH}.template ${1}.conf
                replace "$NH" "$1" -- ${1}.conf
                popd > /dev/null
        else
                ### Creating virthost for Apache
                pushd . > /dev/null
                cd /etc/apache2/vhosts.d/
                cp new_host.conf_template ${1}.conf
                replace "$NH" "$1" -- ${1}.conf
                popd > /dev/null
        fi
}

function reload_services {
        ### Reloading web-servers
        if [ $BACKEND = "fpm" ]
        then
                /etc/init.d/php-fpm reload
        else
                apache2ctl graceful
        fi
        nginx -s reload
}

### Run Functions ###
make_system_user $DOMAIN $PASS
make_db $DOMAIN $PASS
make_nginx_vh $DOMAIN
make_backend $DOMAIN

reload_services
