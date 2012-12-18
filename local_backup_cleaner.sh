#!/usr/local/bin/bash
# Backup cleaner script for BSD web-servers by itJunkie

REMOVE="rm"

#DATE=`date +%Y-%m-%d`
DAY=`date +%d`
MONTH=`date +%m`
YEAR=`date +%Y`
PREV_MONTH=`date -v-1m +%m`

HOST=`hostname`
if [ $HOST == "ara.example.com" ]; then
        echo "It's ara"
        PATH_TO_CLEAN="/dev/ad10s1f"
else
        echo "It's lucky"
        PATH_TO_CLEAN="/dev/ad4s1f"
fi

#==========================================
function free_space()
{
        echo -n "Free space on backup disk: "
        echo -n `df -h |grep "$PATH_TO_CLEAN" | awk '{print $5}' | sed -e s/%//g`
        echo "%"
}

function clean()
{
        PTH="/usr/backup/${1}"
        echo "Begin of cleaning: ${1}"
        # From 01 to 10 day of month
        if [ $DAY -gt 01 -a $DAY -lt 10 ] ; then
                # Backuping datas at first day of previus month for long time
                cp -n ${PTH}/${YEAR}-${PREV_MONTH}-01-* ${PTH}/old/ > /dev/null 2>&1

                $REMOVE $PTH/${YEAR}-${PREV_MONTH}-* > /dev/null 2>&1
                if [ $? -eq 2 ] ; then echo "Removing all datas at previus month"
                else echo "Datas at previus month is empty" ; fi
        else
                # From 10 to 20 day of month
                if [ $DAY -gt 10 -a $DAY -lt 20 ]; then
                        echo "Removing 1-10 DAYs of current month"
                        $REMOVE $PTH/${YEAR}-${MONTH}-0?-*
                else
                        # From 20 to 31 day of month
                        if [ $DAY -gt 19 -a $DAY -lt 32 ]; then
                                echo "Removing 10-20 DAYs of current month"
                                $REMOVE $PTH/${YEAR}-${MONTH}-1?-*
                        fi
                fi
        fi
}

clean "ara"
clean "lucky"

free_space
