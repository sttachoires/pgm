#! @BASH@
# 
# Wrap psql to fit PGM
#
# S. Tachoires		24/02/2016	Initial version
#
#set -xv

# CONSTANTS
PRGNAME=$(basename $0 2> /dev/null)
if [ $? -ne 0 ]; then
  PRGNAME="Unknown"
fi

# INCLUDE
. @CONFDIR@/pgm.conf
. @LIBDIR@/pgm_util.include
. @LIBDIR@/pgm_server.include
. @LIBDIR@/pgm_pg.include

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

egrep --quiet --only-matching "\*:\*:${pgm_version}" ${PGM_PGTAB}
if [ $? -ne 0 ]; then
  exitError "Unmanaged version pf PostgreSQL ${pgm_version}\n"
fi


egrep --quiet --only-matching "\*:${pgm_instance}:${pgm_version}" ${PGM_PGTAB}
if [ $? -ne 0 ]; then
  exitError "Unmanaged SID ${pgm_instance} with version ${pgm_version}\n"
fi

setDatabase ${pgm_version} ${pgm_instance} ${pgm_database}
if [ $? -ne 0 ]; then
  exitError "Cannot set database ${pgm_database} of instance ${pgm_instance} with ${pgm_version} server\n"
fi


${PGM_PGBIN_DIR}/psql --host=${PGM_PGDATA_DIR} --port=${PGM_PGPORT} ${PGM_PGDATABASE}
