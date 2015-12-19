#!/bin/bash

# # 45 23 * * 0 source twttr_autodestruct.sh
# SHELL=/bin/bash
# */5 * * * * source /home/vagrant/twttr_autodestruct.sh



# Variables
BOX_USER=vagrant
TWITTER_USER=hello_ebooks
FILE=${TWITTER_USER}_$(date +%d%m%y).csv


# Make workspace directory
mkdir /tmp/twttr_autodestruct && cd /tmp/twttr_autodestruct

# Create archive
/usr/local/bin/t timeline @${TWITTER_USER} --csv --number 1000 --decode-uris > $FILE

if [[ -s $FILE ]] ; then
  # Remove columns headers
  sed -i '1d' $FILE

  # Copy archive
  cp $FILE /home/$BOX_USER/archive_${TWITTER_USER}/.

  # Get IDs only
  awk -F"," '{print $1}' $FILE > delete_me_column

  # Put the IDs on one line for t
  sed ':a;N;$!ba;s/\n/ /g' delete_me_column > delete_me_row

  # Delete!
  /usr/local/bin/t delete status -f `cat delete_me_row`

  # Delete workspace directory
  cd ~ && rm -rf /tmp/twttr_autodestruct
else
  echo "$FILE is empty" | mail -s "$FILE is empty" ${BOX_USER}@localhost
fi ;

