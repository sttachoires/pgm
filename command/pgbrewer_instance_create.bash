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
. @CONFDIR@/pgbrewer.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/inventory.include
. ${PGB_LIB_DIR}/instance.include

USAGE="Usage: ${PRGNAME} PGVERSION PGSID PGPORT PGLISTENER\nwhere:\n\tPGVERSION is the major version of PostgreSQL to use (ie: 9.3)\n\tPGSID stands for the cluster name (Oracle SID equivalent)\n\tPGPORT is the port the server is listening from\n\tPGLISTENER  is the hostname/ip listening on the PGPORT (default wil be 'uname --node')\n"



declare -xf checkParameters
function checkParameters() ()
{
  declareFunction "checkParameters " "$*"

  analyzeParameters $*
  case $# in
    0 | 1 )
       exitError "${USAGE}\n"
       ;;

    2 )
       pgb_server=$1
       pgb_instance=$2
       pgb_port=5432
       pgb_listener=$(uname --node)
       shift 2
       ;;

    3 )
       pgb_server=$1
       pgb_instance=$2
       pgb_port=$3
       pgb_listener=$(uname --node)
       shift 3
       ;;

     * )
       pgb_server=$1
       pgb_instance=$2
       pgb_port=$3
       pgb_listener=$4
       shift 4
       ;;
  esac


  isServerUnknown ${pgb_server}
  if [[ $? -ne 0 ]]; then
    exitError "Unmanaged version ${pgb_server}\n"
  fi

  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot set ${pgb_instance} version ${pgb_server} \n"
  fi

  export PGB_LOG="${PGB_LOG_DIR}/create_instance.log"
  printInfo "\nINSTANCE CREATION ON $(date)\n  INSTANCE : '${pgb_instance}'\n  VERSION : '${pgb_server}'\n  LISTENER(S) : '${pgb_listener}'\n  PORT : '${pgb_port}'\n\n"
}

#
# M A I N
#

checkParameters $*

addInstance ${pgb_server} ${pgb_instance}
createInstance ${pgb_server} ${pgb_instance} ${pgb_port} ${pgb_listener}
if [[ $? -ne 0 ]]; then
  printError "Error creating instance ${pgb_server} ${pgb_instance} ${pgb_port} ${pgb_listener}, please check ${PGB_LOG}\n"
else
  printInfo "Instance ${PGB_PGINSTANCE} has been created. You have to create a database in it\n"
fi
