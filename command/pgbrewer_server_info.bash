#! @BASH@
#
# Check configuration of PGBrewer.
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
. @CONFDIR@/pgbrewer.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/inventory.include
. ${PGB_LIB_DIR}/server.include

USAGE="${PRGNAME} [VERSION]\nDisplay server configuration. All if no VERSION\nwhere:\n\tVERSION the server version to check"
pgb_server_list=""
if [[ $# -gt 0 ]]; then
  pgb_server_list=$1
  shift
fi

analyzeParameters $*

if [ "${pgb_server_list}x" == "x" ]; then
  pgb_server_list=$(getServers)
fi

for pgb_server in ${pgb_server_list}
do
  printf "PostgreSQL server ${pgb_server}\n"
  setServer ${pgb_server}
  if [[ $? -ne 0 ]]; then
    printf " cannot be set\n"
  else
    serverInfo ${pgb_server} pgb_info
    if [[ $? -ne 0 ]]; then
      checkEnvironment pgb_missing_envs
      if [[ $? -ne 0 ]]; then
        printf " configuration error:\n  ${pgb_missing_envs// /$'\n'  }\n"
      else
        printf " environment OK\n"
      fi
    else
      printf "${pgb_info}\n"
    fi
  fi
done
