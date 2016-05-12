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
if [[ $? -ne 0 ]]; then
  printf "Error loading configuration file\n"
  exit 1
fi
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/inventory.include
. ${PGB_LIB_DIR}/server.include

USAGE="${PRGNAME} [VERSION]\nCheck server configuration. All if no VERSION\nwhere:\n\tVERSION the server version to check"

pgb_server_list=""

if [[ $# -gt 0 ]]; then
  pgb_server_list=$1
  shift
fi

analyzeParameters $*

if [ "${pgb_server_list}x" == "x" ]; then
  getServers pgb_server_list
fi

for pgb_server in ${pgb_server_list}
do
  printf "PostgreSQL server ${pgb_server}\n"
  setServer ${pgb_server}
  if [[ $? -eq 0 ]]; then
    checkEnvironment pgb_missing_envs
    if [[ $? -ne 0 ]]; then
      pgb_missing_envs="${pgb_missing_envs//[ ]+/ }"
      pgb_missing_envs="${pgb_missing_envs/ /$'\t'}"
      printf " configuration error:${pgb_missing_envs// /$'\n'$'\t'}\n\n"
    else
      printf " environment OK\n\n"
    fi
  else
    printf " cannot be set\n\n"
  fi
done

