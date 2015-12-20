#!/bin/bash

# crontab
# SHELL=/bin/bash
# 45 23 * * 0 source /home/vagrant/twttr_autodestruct.sh

# Variables
BOX_USER=vagrant
TWITTER_USER=hello_ebooks

BACKUP_FOLDER=/home/${BOX_USER}/archive_${TWITTER_USER}/
FILE=${TWITTER_USER}_$(date +%d%m%y).csv

# Make workspace directory
mkdir /tmp/twttr_autodestruct && cd /tmp/twttr_autodestruct

# Create archive file
/usr/local/bin/t timeline @${TWITTER_USER} --csv --number 1000 --decode-uris > ${FILE}

# If the file has contents (twttr updates to backup)
if [ -s ${FILE} ] ; then

  # Copy archive
  cp ${FILE} ${BACKUP_FOLDER}

  # Remove columns headers		
  sed -i '1d' ${FILE}

  # Get IDs only
  awk -F"," '{print $1}' ${FILE} > delete_me_column

  # Put the IDs on one line for t
  sed ':a;N;$!ba;s/\n/ /g' delete_me_column > delete_me_row

  # Delete!
  /usr/local/bin/t delete status -f `cat delete_me_row`
 
else
  
  # Send an email saying there were no twttr updates to backup
  echo "${FILE} is empty" | mail -s "${FILE} is empty" ${BOX_USER}@localhost
    
fi ;

# Delete workspace directory
cd ~ && rm -rf /tmp/twttr_autodestruct