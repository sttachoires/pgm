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
if [[ $? -ne 0 ]]; then
  PRGNAME="Unknown"
fi

options=""

# INCLUDE
. @CONFDIR@/pgm.conf
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_server.include


USAGE="${PRGNAME} VERSION SID : Stop instance\nwhere:\n\tVERSION : Server full version\n\tSID : database identifier\n"

if [[ $# -ne 2 ]]; then
  printInfo "${USAGE}\n"
  exit 1
fi

pgm_version=$1
isServerUnknown ${pgm_version}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged version pf PostgreSQM ${pgm_version}\n"
fi


pgm_instance=$2
isInstanceUnknownFromServer ${pgm_version} ${pgm_instance}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged SID ${pgm_instance}\n"
fi

setInstance ${pgm_version} ${pgm_instance}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set instance ${pgm_instance} of ${pgm_version} server\n"
fi

stopInstance ${pgm_version} ${pgm_sid}
