# The Twitter account that you want to backup
TWITTER_USER=reyhan
# The location of the backup folder
BACKUP_FOLDER=${HOME}/archive_${TWITTER_USER}
# The archive file
ARCHIVE_FILE=${TWITTER_USER}_$(date +%d%m%y_%H%M%S).csv
# The location of the folder where all the magic happens
WORKSPACE_FOLDER=/tmp/twttr_autodestructor


debug() {
  echo
  echo "******* DEBUG *******"
  echo
  echo "REPORTED RUBY VERSION"
  echo "`ruby --version`"
  echo
  echo "REPORTED T VERSION"
  echo "`t version`"
  echo
  echo "REPORTED T USER"
  echo "`t whoami`"
  echo
  echo "*********************"
  echo
}

createWorkspace() {
  # if ${WORKSPACE_FOLDER} does not exist
  if [ ! -d "${WORKSPACE_FOLDER}" ]; then

    mkdir ${WORKSPACE_FOLDER}
    if [ $? -eq 0 ]; then
      echo "${WORKSPACE_FOLDER} created"
    else
      echo "ERROR at ${FUNCNAME}: ${WORKSPACE_FOLDER} unable to be created"
      exit
    fi

  else

    echo "ERROR at ${FUNCNAME}: ${WORKSPACE_FOLDER} already exists"
    exit

  fi
}

destroyWorkspace() {
  # if ${WORKSPACE_FOLDER} does exist
  if [ -d "${WORKSPACE_FOLDER}" ]; then

    rm -rf ${WORKSPACE_FOLDER}
    if [ $? -eq 0 ]; then
      echo "${WORKSPACE_FOLDER} destroyed"
    else
      echo "ERROR at ${FUNCNAME}: ${WORKSPACE_FOLDER} unable to be destroyed"
    fi

  else

    echo "ERROR at ${FUNCNAME}: ${WORKSPACE_FOLDER} does not exist"

  fi
}

createDumpfile() {
  /usr/local/bin/t timeline @${TWITTER_USER} --csv --number 1000 --decode-uris > ${WORKSPACE_FOLDER}/dumpfile
  if [ $? -eq 0 ]; then

    echo "dumpfile created"
    if [ ! -s ${WORKSPACE_FOLDER}/dumpfile ]; then
      echo "ERROR at ${FUNCNAME}: dumpfile is empty"
      exit
    fi

  else

    echo "ERROR at ${FUNCNAME}: Unable to create dumpfile"
    exit

  fi
}

createBackup() {
  # if dumpfile exists
  if [ -f ${WORKSPACE_FOLDER}/dumpfile ]; then

    # Replace endofline chars
    awk -v RS='"[^"]*"' -v ORS= '{gsub(/\n/, " ", RT); print $0 RT}' ${WORKSPACE_FOLDER}/dumpfile > ${WORKSPACE_FOLDER}/${ARCHIVE_FILE}

    # if ${ARCHIVE_FILE} exists
    if [ -f "${WORKSPACE_FOLDER}/${ARCHIVE_FILE}" ]; then

      cp ${WORKSPACE_FOLDER}/${ARCHIVE_FILE} ${BACKUP_FOLDER}
      # If copy was successful
      if [ $? -eq 0 ]; then
        echo "Copy was successful, doing git stuff"
        # Add to git repo
        cd ${BACKUP_FOLDER}
        if [ ! -d "${BACKUP_FOLDER}/.git" ]; then
          git init
        fi
        git add . && git commit -m "Add twitter updates from ${ARCHIVE_FILE}" && cd ${WORKSPACE_FOLDER}
      else
        echo "ERROR at ${FUNCNAME}: Copy was not successful"
        exit
      fi

    else

      echo "ERROR at ${FUNCNAME}: ${ARCHIVE_FILE} does not exist"
      exit

    fi

  else

    echo "ERROR at ${FUNCNAME}: dumpfile does not exist"
    exit

  fi
}


destroyTweets() {
  # Remove columns headers
  sed -i '1d' ${WORKSPACE_FOLDER}/${ARCHIVE_FILE}

  # Get IDs only
  awk -F "," '{print $1}' ${WORKSPACE_FOLDER}/${ARCHIVE_FILE} > ${WORKSPACE_FOLDER}/to_delete

  # Put the IDs on one line for t
  sed -i ':a;N;$!ba;s/\n/ /g' ${WORKSPACE_FOLDER}/to_delete
 
  /usr/local/bin/t delete status -f `cat ${WORKSPACE_FOLDER}/to_delete`
  if [ $? -eq 0 ]; then
    echo "Tweets deleted"
  else

    echo "ERROR at ${FUNCNAME}: Unable to delete tweets"
    cp ${WORKSPACE_FOLDER}/to_delete ${HOME}/twttr_autodestructor_FAILED_DELETE_$(date +%d%m%y)
    exit

  fi
}


trap destroyWorkspace EXIT

mkdir -p ${BACKUP_FOLDER}
debug
createWorkspace
createDumpfile
createBackup
destroyTweets
