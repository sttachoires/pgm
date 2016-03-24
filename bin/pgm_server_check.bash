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
if [[ $? -ne 0 ]]; then
  printf "Error loading configuration file\n"
  exit 1
fi
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_server.include

USAGE="${PRGNAME} [VERSION]\nCheck server configuration. All if no VERSION\nwhere:\n\tVERSION the server version to check"

pgm_server_list=""

if [[ $# -gt 0 ]]; then
  pgm_server_list=$1
  shift
fi

analyzeParameters $*

if [ "${pgm_server_list}x" == "x" ]; then
  getServers pgm_server_list
fi

for pgm_server in ${pgm_server_list}
do
  printf "PostgreSQL server ${pgm_server}\n"
  setServer ${pgm_server}
  if [[ $? -eq 0 ]]; then
    checkEnvironment pgm_missing_envs
    if [[ $? -ne 0 ]]; then
      pgm_missing_envs="${pgm_missing_envs//[ ]+/ }"
      pgm_missing_envs="${pgm_missing_envs/ /$'\t'}"
      printf " configuration error:${pgm_missing_envs// /$'\n'$'\t'}\n\n"
    else
      printf " environment OK\n\n"
    fi
  else
    printf " cannot be set\n\n"
  fi
done

