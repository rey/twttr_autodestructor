#!/bin/bash

# # 45 23 * * 0 source twttr_autodestruct.sh
# SHELL=/bin/bash
# */5 * * * * source /home/vagrant/twttr_autodestruct.sh



# Add user
USER=hello_ebooks

# Make workspace directory
mkdir /tmp/twttr_autodestruct && cd /tmp/twttr_autodestruct

# Create archive
/usr/local/bin/t timeline @${USER} --csv --number 1000 --decode-uris > ${USER}_$(date +%d%m%y).csv

# Remove columns headers
sed -i '1d' ${USER}*.csv

# Copy archive
cp ${USER}*.csv ~/archive_${USER}/.

# Get IDs only
awk -F"," '{print $1}' ${USER}*.csv > delete_me_column

# Put the IDs on one line for t
sed ':a;N;$!ba;s/\n/ /g' delete_me_column > delete_me_row

# Delete!
/usr/local/bin/t delete status -f `cat delete_me_row`

# Delete workspace directory
cd ~ && rm -rf /tmp/twttr_autodestruct