#! @BASH@
# 
# Wrap psql to fit PGBrewer
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
. @CONFDIR@/pgbrewer.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/inventory.include
. ${PGB_LIB_DIR}/database.include

USAGE="Usage: ${PRGNAME} VERSION SID \nwhere:\n\tVERSION is the full version of PostgreSQL to use (ie: 9.3.4)\n\tPGSID stands for the cluster name\n"

case $# in
  0 | 1 ) exitError "${USAGE}\n"
      ;;    

  2 ) pgb_server=$1
      pgb_instance=$2
      pgb_database="postgres"
      shift 2
      ;;

  * ) pgb_database=$3
      pgb_server=$1
      pgb_instance=$2
      shift 3
      ;;
esac

analyzeParameters $*

isServerUnknown ${pgb_server}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged version pg PostgreSQL ${pgb_server}\n"
fi

setServer ${pgb_server}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set PostgreSQL ${pgb_server}\n"
fi


isInstanceUnknownFromServer ${pgb_server} ${pgb_instance}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged instance ${pgb_instance} with version ${pgb_server}\n"
fi
setInstance ${pgb_server} ${pgb_instance}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set instance ${pgb_instance} with version ${pgb_server}\n"
fi


isDatabaseUnknownFromInstance ${pgb_server} ${pgb_instance} ${pgb_database}
if [[ $? -ne 0 ]] && [[ $pgb_instance =~ (${PGB_PGADMINISTRATIVE_DATABASES// /|}) ]]; then
  exitError "Unknown database ${pgb_database} of instance ${pgb_instance} with ${pgb_server} server\n"
fi

setDatabase ${pgb_server} ${pgb_instance} ${pgb_database}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set database ${pgb_database} of instance ${pgb_instance} with ${pgb_server} server\n"
fi

${PGB_PGBIN_DIR}/psql --host=${PGB_PGDATA_DIR} --port=${PGB_PGPORT} ${PGB_PGDATABASE}
