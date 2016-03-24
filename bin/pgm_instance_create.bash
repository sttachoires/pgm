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
. ${PGM_LIB_DIR}/pgm_instance.include

USAGE="Usage: ${PRGNAME} PGVERSION PGSID PGPORT PGLISTENER\nwhere:\n\tPGVERSION is the major version of PostgreSQL to use (ie: 9.3)\n\tPGSID stands for the cluster name (Oracle SID equivalent)\n\tPGPORT is the port the server is listening from\n\tPGLISTENER  is the hostname/ip listening on the PGPORT (default wil be 'uname --node')\n"



function checkParameters ()
{
  declareFunction "checkParameters " "$*"

  analyzeParameters $*
  case $# in
    0 | 1 )
       exitError "${USAGE}\n"
       ;;

    2 )
       pgm_server=$1
       pgm_instance=$2
       pgm_port=5432
       pgm_listener=$(uname --node)
       shift 2
       ;;

    3 )
       pgm_server=$1
       pgm_instance=$2
       pgm_port=$3
       pgm_listener=$(uname --node)
       shift 3
       ;;

     * )
       pgm_server=$1
       pgm_instance=$2
       pgm_port=$3
       pgm_listener=$4
       shift 4
       ;;
  esac


  isServerUnknown ${pgm_server}
  if [[ $? -ne 0 ]]; then
    exitError "Unmanaged version ${pgm_server}\n"
  fi

  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot set ${pgm_instance} version ${pgm_server} \n"
  fi

  export PGM_LOG="${PGM_LOG_DIR}/create_instance.log"
  printInfo "\nINSTANCE CREATION ON $(date)\n  INSTANCE : '${pgm_instance}'\n  VERSION : '${pgm_server}'\n  LISTENER(S) : '${pgm_listener}'\n  PORT : '${pgm_port}'\n\n"
}

#
# M A I N
#

checkParameters $*

addInstance ${pgm_server} ${pgm_instance}
createInstance ${pgm_server} ${pgm_instance} ${pgm_port} ${pgm_listener}
if [[ $? -ne 0 ]]; then
  printError "Error creating instance ${pgm_server} ${pgm_instance} ${pgm_port} ${pgm_listener}, please check ${PGM_LOG}\n"
else
  printInfo "Instance ${PGM_PGINSTANCE} has been created. You have to create a database in it\n"
fi
