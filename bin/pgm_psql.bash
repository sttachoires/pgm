#! @BASH@
# 
# Wrap psql to fit PGM
#
# S. Tachoires		24/02/2016	Initial version
#
#set -xv

# CONSTANTS
PRGNAME=$(basename $0 2> /dev/null)
if [[ $? -ne 0 ]]; then
  PRGNAME="Unknown"
fi

# INCLUDE
. @CONFDIR@/pgm.conf
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_database.include

USAGE="Usage: ${PRGNAME} VERSION SID \nwhere:\n\tVERSION is the full version of PostgreSQL to use (ie: 9.3.4)\n\tPGSID stands for the cluster name\n"

case $# in
  0 | 1 ) exitError "${USAGE}\n"
      ;;    

  2 ) pgm_server=$1
      pgm_instance=$2
      pgm_database="postgres"
      shift 2
      ;;

  * ) pgm_database=$3
      pgm_server=$1
      pgm_instance=$2
      shift 3
      ;;
esac

analyzeParameters $*

isServerUnknown ${pgm_server}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged version pg PostgreSQL ${pgm_server}\n"
fi

setServer ${pgm_server}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set PostgreSQL ${pgm_server}\n"
fi


isInstanceUnknownFromServer ${pgm_server} ${pgm_instance}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged instance ${pgm_instance} with version ${pgm_server}\n"
fi
setInstance ${pgm_server} ${pgm_instance}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set instance ${pgm_instance} with version ${pgm_server}\n"
fi


isDatabaseUnknownFromInstance ${pgm_server} ${pgm_instance} ${pgm_database}
if [[ $? -ne 0 ]] && [[ $pgm_instance =~ (${PGM_PGADMINISTRATIVE_DATABASES// /|}) ]]; then
  exitError "Unknown database ${pgm_database} of instance ${pgm_instance} with ${pgm_server} server\n"
fi

setDatabase ${pgm_server} ${pgm_instance} ${pgm_database}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set database ${pgm_database} of instance ${pgm_instance} with ${pgm_server} server\n"
fi

${PGM_PGBIN_DIR}/psql --host=${PGM_PGDATA_DIR} --port=${PGM_PGPORT} ${PGM_PGDATABASE}
