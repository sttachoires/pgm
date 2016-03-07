#! @BASH@
#
# Create a PostgreSQL instance.
#
# 21.02.2016	S. Tachoires	Initial version
#
#set -xv

# Constants
PRGNAME=$(basename $0 2> /dev/null)
if [[ $? -ne 0 ]]; then
  PRGNAME="Unknown"
fi

# INCLUDE
. @CONFDIR@/pgm.conf
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_pg.include

USAGE="Usage: ${PRGNAME} PGVERSION PGSID PGPORT PGLISTENER\nwhere:\n\tPGVERSION is the major version of PostgreSQL to use (ie: 9.3)\n\tPGSID stands for the cluster name (Oracle SID equivalent)\n\tPGPORT is the port the server is listening from\n\tPGLISTENER  is the hostname/ip listening on the PGPORT (default wil be 'uname --node')\n"


export pgm_version=""
export pgm_sid=""
export pgm_port=5432
export pgm_listener=$(uname --node)

function checkParameters ()
{
  case $# in
    4 )
       pgm_version=$1
       pgm_sid=$2
       pgm_port=$3
       pgm_listener=$4
       ;;

    3 )
       pgm_version=$1
       pgm_sid=$2
       pgm_port=$3
       ;;

    2 )
       pgm_version=$1
       pgm_sid=$2
       ;;

    * ) exitError "${USAGE}\n"
  esac

  isServerUnknown ${pgm_version}
  if [[ $? -ne 0 ]]; then
    exitError "Unmanaged version ${pgm_version}\n"
  fi

  setInstance ${pgm_version} ${pgm_sid}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot set ${pgm_sid} version ${pgm_version} \n"
  fi

  export PGM_LOG="${PGM_LOG_DIR}/create_instance.log"
  printInfo "\nINSTANCE CREATION ON $(date)\n  INSTANCE : '${pgm_sid}'\n  VERSION : '${pgm_version}'\n  LISTENER(S) : '${pgm_listener}'\n  PORT : '${pgm_port}'\n\n"
}

#
# M A I N
#
checkParameters $*

createInstance ${pgm_version} ${pgm_instance} ${pgm_port} ${pgm_listener}

printInfo "Instance ${PGM_PGINSTANCE} has been created. You have to create a database in it\n"
