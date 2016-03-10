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
. ${PGM_LIB_DIR}/pgm_db.include

USAGE="Usage: ${PRGNAME} VERSION SID \nwhere:\n\tVERSION is the full version of PostgreSQL to use (ie: 9.3.4)\n\tPGSID stands for the cluster name\n"

case $# in
  3 ) pgm_database=$3
      pgm_version=$1
      pgm_instance=$2
      ;;

  2 ) pgm_version=$1
      pgm_instance=$2
      pgm_database="postgres"
      ;;

  *) exitError "${USAGE}\n"
esac

isServerUnknown ${pgm_version}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged version pg PostgreSQL ${pgm_version}\n"
fi

setServer ${pgm_version}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set PostgreSQL ${pgm_version}\n"
fi


isInstanceUnknownFromServer ${pgm_version} ${pgm_instance}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged instance ${pgm_instance} with version ${pgm_version}\n"
fi
setInstance ${pgm_version} ${pgm_instance}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set instance ${pgm_instance} with version ${pgm_version}\n"
fi


isDatabaseUnknownFromInstance ${pgm_version} ${pgm_instance} ${pgm_database}
if [[ $? -ne 0 ]] && [[ $pgm_instance =~ (${PGM_PGADMINISTRATIVE_DATABASES// /|}) ]]; then
  exitError "Unknown database ${pgm_database} of instance ${pgm_instance} with ${pgm_version} server\n"
fi

setDatabase ${pgm_version} ${pgm_instance} ${pgm_database}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set database ${pgm_database} of instance ${pgm_instance} with ${pgm_version} server\n"
fi

${PGM_PGBIN_DIR}/psql --host=${PGM_PGDATA_DIR} --port=${PGM_PGPORT} ${PGM_PGDATABASE}
