#!/bin/bash

# Add user
USER=hello_ebooks

# Make workspace directory
mkdir /tmp/twttr_autodestruct && cd /tmp/twttr_autodestruct

# Create archive
t timeline @${USER} --csv --number 1000 --decode-uris > archive_${USER}_$(date +%d%m%y).csv

# Remove columns headers
sed -i '1d' archive*.csv

# Copy archive
cp archive*.csv ~/archive_${USER}/.

# Get IDs only
awk -F"," '{print $1}' archive*.csv > delete_me_column

# Put the IDs on one line for t
sed ':a;N;$!ba;s/\n/ /g' delete_me_column > delete_me_row

# Delete!
t delete status -f `cat delete_me_row`

# Delete workspace directory
rm -rf /tmp/twttr_autodestruct