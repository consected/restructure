#########################################################################
# Sync Back Shared function defs
#########################################################################


check_and_notify_errors() {
  # Check for logged errors, notify by email
  if [ -f ${ERRORFILE} ]
  then
    if [ ! -z $(which mailx ) ]
    then
      echo "`date +%m%d%Y` ${SCRIPTNAME} - failures recorded... check ${LOGFILE}" | mailx -s "Sync Back Script Failure" fphsetl@hms.harvard.edu
    fi
    rm ${ERRORFILE}
  fi
}


log() {
  LEVEL=$1
  MSG=$2
  FULLMSG="`date +%m%d%Y%H%M` ($$) - ${SCRIPTNAME} ${STUDY} - ${LEVEL}: ${MSG}"
  echo ${FULLMSG} >> ${LOGFILE}

  if [ "${LEVEL}" == 'ERROR' ] || [ "${LEVEL}" == 'WARNING' ]
  then
    echo ${FULLMSG} >> ${ERRORFILE}
  fi
}

log_last_error_and_exit() {
  DATA=$(cat ${PSQLRESFL} 2> /dev/null)
  if [ ! -z "${DATA}" ]
  then
    log 'SQL' "${DATA}"
    if [[ "${DATA}" =~ 'ERROR: ' ]]
    then
      log ERROR "Exiting"
      exit 1
    fi
  fi
}

setup_process() {

  # Setup Credentials
  . ${SBPULLDIR}/sync_db_connections.sh
  cd ${SBROOT}

  rm -f ${ERRORFILE}

}


function cleanup {
  rm ${CURRENT_SQL_FILE} 2> /dev/null
  rm ${WORKINGDIR}/*.csv 2> /dev/null
}

on_exit() {
  check_and_notify_errors
  log INFO "##################################"
  echo 0
}

trap on_exit EXIT

############################################################################################
# Global vars
############################################################################################
export SCRIPTNAME=`basename "$0"`
export SBROOT=${BASEDIR}
export WORKINGDIR=${SBROOT}/tmp
export LOGDIR=${SBROOT}/log
export SCRDIR=${SBROOT}/scripts
export PSQLRESFL=${WORKINGDIR}/.last_psql_error
export ERRORFILE=${LOGDIR}/errors
export LOGFILE=${LOGDIR}/sync_back_data.log

echo ${LOGFILE}
