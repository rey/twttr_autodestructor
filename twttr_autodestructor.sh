#!/bin/bash

# INSTALL
# =======
#
# Assuming you're running Ubuntu
#
# ```
# sudo apt-get install ruby ruby-dev gcc g++ make
# sudo gem install t
# ```
#
# Then you'll want to add something like the following to your crontab
#
# ```
# SHELLL=/bin/bash
# # Run at 23:45 every Sunday
# 45 23 * * 0 source /home/vagrant/twttr_autodestruct.sh
# ```
#
#
# VARIABLES
# =========
#
# The user you're running the script as
BOX_USER=rey
# The Twitter account that you want to backup
TWITTER_USER=reyhan
# The location of the backup folder
BACKUP_FOLDER=/home/${BOX_USER}/archive_${TWITTER_USER}/
# The archive file
ARCHIVE_FILE=${TWITTER_USER}_$(date +%d%m%y).csv
# The location of the folder where all the magic happens
WORKSPACE_FOLDER=/tmp/twttr_autodestructor
#
#
# HERE BE DRAGONS
# ===============
#
# Make workspace directory
mkdir ${WORKSPACE_FOLDER} && cd ${WORKSPACE_FOLDER}

# Get tweets from Twitter
/usr/local/bin/t timeline @${TWITTER_USER} --csv --number 1000 --decode-uris > dump_file

# If the dump_file has contents (ie. twttr updates to backup)
if [ -s dump_file ] ; then

  # replace endofline characters in multiple line tweets
  awk -v RS='"[^"]*"' -v ORS= '{gsub(/\n/, " ", RT); print $0 RT}' dump_file > ${ARCHIVE_FILE}

  # Copy archive to ${BACKUP_FOLDER} location
  cp ${ARCHIVE_FILE} ${BACKUP_FOLDER}

  # Add to git
  cd ${BACKUP_FOLDER} && git add . && git commit -m "Latest twttr updates"

  # Move back to ${WORKSPACE_FOLDER}
  cd ${WORKSPACE_FOLDER}

  # Remove columns headers
  sed -i '1d' ${ARCHIVE_FILE}

  # Get IDs only
  awk -F "," '{print $1}' ${ARCHIVE_FILE} > to_delete

  # Put the IDs on one line for t
  sed -i ':a;N;$!ba;s/\n/ /g' to_delete

  # Delete!
  /usr/local/bin/t delete status -f `cat to_delete`

  # Report!
  mail -s "twttr_autodestructor report" ${BOX_USER}@localhost < to_delete

else

  # Send an email saying there were no twttr updates to backup
  echo "dump_file was empty" | mail -s "No tweets to archive" ${BOX_USER}@localhost

fi ;

# Delete workspace directory
cd ~ && rm -rf ${WORKSPACE_FOLDER}