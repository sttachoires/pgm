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


USAGE="${PRGNAME} VERSION SID : Force stop of instance.\nwhere:\n\tVERSION : Server full version\n\tSID : database identifier\n"

if [ $# -ne 2 ]; then
  printInfo "${USAGE}\n"
  exit 1
fi

pgm_version=$1
egrep -qo "\*:\*:${pgm_version}" ${PGM_PGTAB}
if [ $? -ne 0 ]; then
  exitError "Unmanaged version pf PostgreSQM ${pgm_version}\n"
fi


pgm_instance=$2
egrep -qo "\*:${pgm_instance}:${version}" ${PGM_PGTAB}
if [ $? -ne 0 ]; then
  exitError "Unmanaged SID ${pgm_instance}\n"
fi

setInstance ${pgm_version} ${pgm_instance}
if [ $? -ne 0 ]; then
  exitError "Cannot set instance ${pgm_instance} of ${pgm_version} server\n"
fi

killInstance ${pgm_version} ${pgm_sid}
