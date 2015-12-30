# twttr_autodestructor.sh
# Version 1.0
# Rey Dhuny
#
#
# ABOUT
# =====
#
# `twttr_autodestructor.sh` is a bash script which you can run on a daily/weekly basis to:
# 1. Create a local backup of your twitter updates 
# 2. Delete your twitter updates from Twitter's servers
#
#
# INSTALL
# =======
#
# This is assuming you're using Ubuntu 15.10.
#
# 1. Install Ruby (I'm using 2.1.5)
# 2. Install Git
# 3. Install Twurl (https://github.com/twitter/twurl)
# 4. Install jq (https://stedolan.github.io/jq)
# 5. Register an OAuth application to get a consumer key and secret (https://apps.twitter.com/app/new)
# 6. `twurl authorize --consumer-key key --consumer-secret secret`


# The Twitter account that you want to backup
TWITTER_USER=reyhan
# The location of the backup folder
BACKUP_FOLDER=${HOME}/archive_${TWITTER_USER}
# The archive file
ARCHIVE_FILE=${TWITTER_USER}_$(date +%d%m%y_%H%M%S).json
# The location of the folder where all the magic happens
WORKSPACE_FOLDER=/tmp/twttr_autodestructor


debug() {
  echo
  echo "******* DEBUG *******"
  echo
  echo "REPORTED RUBY VERSION"
  echo "`ruby --version`"
  echo
  echo "REPORTED TWURL VERSION"
  echo "`twurl --version`"
  echo
  echo "*********************"
  echo
}

createWorkspace() {
  # if ${WORKSPACE_FOLDER} does not exist
  if [ ! -d "${WORKSPACE_FOLDER}" ]; then

    mkdir ${WORKSPACE_FOLDER}
    if [ $? -eq 0 ]; then
      echo "SUCCESS: ${WORKSPACE_FOLDER} created"
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
      echo "SUCCESS: ${WORKSPACE_FOLDER} destroyed"
    else
      echo "ERROR at ${FUNCNAME}: ${WORKSPACE_FOLDER} unable to be destroyed"
    fi

  else

    echo "ERROR at ${FUNCNAME}: ${WORKSPACE_FOLDER} does not exist"

  fi
}

createDumpfile() {
  /usr/local/bin/twurl "/1.1/statuses/user_timeline.json?screen_name=${TWITTER_USER}&count=200" > ${WORKSPACE_FOLDER}/dumpfile
  if [ $? -eq 0 ]; then
    echo "SUCCESS: dumpfile created"
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

    cat ${WORKSPACE_FOLDER}/dumpfile | jq ".[] | {id: .id_str, text: .text, created: .created_at}" > ${WORKSPACE_FOLDER}/${ARCHIVE_FILE}

    # if ${ARCHIVE_FILE} exists
    if [ -f "${WORKSPACE_FOLDER}/${ARCHIVE_FILE}" ]; then

      cp ${WORKSPACE_FOLDER}/${ARCHIVE_FILE} ${BACKUP_FOLDER}
      # If copy was successful
      if [ $? -eq 0 ]; then
        echo "SUCCESS: Copy was successful"
        # Add to git repo
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

  cat ${WORKSPACE_FOLDER}/dumpfile | jq ".[] | .id_str" | sed 's/\"//g' > ${WORKSPACE_FOLDER}/to_delete

  while read tweet_id; do
    echo
    echo $tweet_id
    /usr/local/bin/twurl --request-method POST /1.1/statuses/destroy/${tweet_id}.json
    echo
  done < ${WORKSPACE_FOLDER}/to_delete

  if [ $? -eq 0 ]; then
    echo "SUCCESS: Tweets deleted"
    NO_OF_TWEETS=`cat ${WORKSPACE_FOLDER}/to_delete | wc -l`
    /usr/local/bin/twurl --data "description=${NO_OF_TWEETS} twttr updates evaporated on $(date +"%A %d %B %Y")" /1.1/account/update_profile.json
  else
    echo "ERROR at ${FUNCNAME}: Unable to delete tweets"
    cp ${WORKSPACE_FOLDER}/to_delete ${HOME}/twttr_autodestructor_FAILED_DELETE_$(date +%d%m%y_%H%M%S)
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