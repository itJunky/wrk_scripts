#!/usr/local/bin/bash
# Backup script for BSD web-servers by itJunkie

LHOST="arahost"                 # Local Host
RHOST="bkp.example.com"         # Rmote Host
DATE=`date +%Y-%m-%d`           # Current date
BACKUP_DIR="/backup"            # Directory for backups
PATH_TO_BACKUP=/${BACKUP_DIR}/${LHOST}

function create_backup()
{       # Creating files backup
        mkdir -p /${PATH_TO_BACKUP}
        FILENAME="${DATE}-files.tar.gz"
        tar -czf /${PATH_TO_BACKUP}/${FILENAME} /www/*
        
        ### Executing MySQL backup function ###
        mysql_backup
}

function mysql_backup()
{       # Creating MySQL databases backup 
        mkdir /${PATH_TO_BACKUP}/db     # make temporary dir
        FILENAME="${DATE}-db.tar.gz"    # Name of archive file

        for dtb in `mysqlshow | grep -vE 'information_schema|Databases|----' | awk '{print $2}'`
        do      # Dump databas by turn
                echo "Dumping $dtb"
                mysqldump ${dtb} > /${PATH_TO_BACKUP}/db/${dtb}.sql
        done

        #ls -l /${PATH_TO_BACKUP}/db/   # DEBUG
        tar -czf /${PATH_TO_BACKUP}/${FILENAME} /${PATH_TO_BACKUP}/db
        echo "Removing temporary files"
        rm /${PATH_TO_BACKUP}/db/*.sql
}

function sync_backup()
{       # copying backup to remote server
        LATEST_FILES=`find $PATH_TO_BACKUP -type f -name "*" -print0 | xargs -0 ls -t`
        ARRAY_FILES=($LATEST_FILES)
        #echo ${ARRAY_FILES[*]}         # DEBUG
        sudo -u backup scp `echo ${ARRAY_FILES[0]} ` backup@${RHOST}:$PATH_TO_BACKUP
        sudo -u backup scp `echo ${ARRAY_FILES[1]} ` backup@${RHOST}:$PATH_TO_BACKUP
}

### MAIN ###

create_backup
#mysql_backup  # Exec from create_backup()
sync_backup
