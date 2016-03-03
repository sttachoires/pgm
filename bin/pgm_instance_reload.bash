#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires		20/02/2016	Initial version
#
#set -xv

# CONSTANTS
PRGNAME=$(basename $0 2> /dev/null)
if [ $? -ne 0 ]; then
  PRGNAME="Unknown"
fi

options=""

# INCLUDE
. @CONFDIR@/pgm.conf
. @LIBDIR@/pgm_util.include
. @LIBDIR@/pgm_server.include
. @LIBDIR@/pgm_pg.include


USAGE="${PRGNAME} VERSION SID : Signal instance for reloading without restarting\nwhere:\n\tVERSION : Server full version\n\tSID : database identifier\n"

if [ $# -ne 2 ]; then
  printInfo "${USAGE}\n"
  exit 1
fi

pgm_version=$1
egrep -qo "_:_:${pgm_version}" ${PGM_PG_TAB}
if [ $? -ne 0 ]; then
  exitError "Unmanaged version pf PostgreSQM ${pgm_version}\n"
fi


pgm_instance=$2
egrep -qo "_:${pgm_instance}:${version}" ${PGM_PG_TAB}
if [ $? -ne 0 ]; then
  exitError "Unmanaged SID ${pgm_instance}\n"
fi

setInstance ${pgm_version} ${pgm_instance}
if [ $? -ne 0 ]; then
  exitError "Cannot set instance ${pgm_instance} of ${pgm_version} server\n"
fi

reloadInstance ${pgm_version} ${pgm_sid}
pgm_messages=$(tail ${PGM_PG_LOG} | grep "PG-55P02" 2>&1)
if [ $? -eq 0 ]; then
  printInfo "Instance ${pgm_sid} need restart to set new parameters.\n${pgm_message} Please issue:\n\t${PRGMNAME} ${pgm_version} ${pgm_sid} restart\n"
fi
