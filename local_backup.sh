#!/usr/local/bin/bash
# Backup script for BSD web-servers by itJunkie

LHOST="ara"                     # Local Host
RHOST="lucky.example.com"       # Rmote Host
DATE=`date +%Y-%m-%d`           # Current date

function create_bac()
{       # Creating files backup
        FILENAME="${DATE}-files.tar.gz"
        tar -czf /usr/backup/${LHOST}/${FILENAME} /www/*
        # Executing MySQL backup function
        mysql_bac 
}

function mysql_bac()
{       # MySQL backup
        mkdir /usr/backup/${LHOST}/db   # make temporary dir
        FILENAME="${DATE}-db.tar.gz"    # Name of archive file

        for dtb in `mysqlshow | grep -vE 'information_schema|Databases|----' | awk '{print $2}'`
        do      # Dump databas by turn
                echo "Dumping $dtb"
                mysqldump ${dtb} > /usr/backup/${LHOST}/db/${dtb}.sql
        done

        #ls -l /usr/backup/${LHOST}/db/ # DEBUG
        tar -czf /usr/backup/${LHOST}/${FILENAME} /usr/backup/${LHOST}/db
        echo "Removing temporary files"
        rm /usr/backup/${LHOST}/db/*.sql
}

function sync_bac()
{       # copying backup to remote server
        PATH_TO_BACKUP=/usr/backup/${LHOST}
        LATEST_FILES=`find $PATH_TO_BACKUP -type f -name "*" -print0 | xargs -0 ls -t`
        ARRAY_FILES=($LATEST_FILES)
        #echo ${ARRAY_FILES[*]}         # DEBUG
        sudo -u backup scp `echo ${ARRAY_FILES[0]} ` backup@${RHOST}:$PATH_TO_BACKUP
        sudo -u backup scp `echo ${ARRAY_FILES[1]} ` backup@${RHOST}:$PATH_TO_BACKUP
}

### MAIN ###

create_bac
#mysql_bac
sync_bac
