#! @BASH@
#
# Check configuration of PGM.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

# CONSTANTS
PRGNAME=$(basename $0 2> /dev/null)
if [[ $? -ne 0 ]]; then
  PRGNAME="Unknown"
fi

# INCLUDE
. @CONFDIR@/pgm.conf
. ${PGM_LIB_DIR}/util.include
. ${PGM_LIB_DIR}/inventory.include
. ${PGM_LIB_DIR}/server.include

USAGE="${PRGNAME} [VERSION]\nDisplay server configuration. All if no VERSION\nwhere:\n\tVERSION the server version to check"
pgm_server_list=""
if [[ $# -gt 0 ]]; then
  pgm_server_list=$1
  shift
fi

analyzeParameters $*

if [ "${pgm_server_list}x" == "x" ]; then
  pgm_server_list=$(getServers)
fi

for pgm_server in ${pgm_server_list}
do
  printf "PostgreSQL server ${pgm_server}\n"
  setServer ${pgm_server}
  if [[ $? -ne 0 ]]; then
    printf " cannot be set\n"
  else
    serverInfo ${pgm_server} pgm_info
    if [[ $? -ne 0 ]]; then
      checkEnvironment pgm_missing_envs
      if [[ $? -ne 0 ]]; then
        printf " configuration error:\n  ${pgm_missing_envs// /$'\n'  }\n"
      else
        printf " environment OK\n"
      fi
    else
      printf "${pgm_info}\n"
    fi
  fi
done
