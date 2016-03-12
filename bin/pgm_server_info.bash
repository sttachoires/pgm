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
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_server.include

USAGE="${PRGNAME} [VERSION]\nDisplay server configuration. All if no VERSION\nwhere:\n\tVERSION the server version to check"

if [[ $# -gt 0 ]]; then
  pgm_server_list=$*
else
  pgm_server_list=$(getServers)
fi

for pgm_version in ${pgm_server_list}
do
  printf "PostgreSQL server ${pgm_version}"
  setServer ${pgm_version}
  if [[ $? -ne 0 ]]; then
    printf " cannot be set\n"
  else
    pgm_info=$(serverInfo ${pgm_version})
    if [[ $? -ne 0 ]]; then
      pgm_missing_envs=$(checkEnvironment)
      if [[ $? -ne 0 ]]; then
        printf " configuration error:\n\n${pgm_missing_envs// /$'\n'}\n"
      else
        printf " environment OK\n"
      fi
    else
      printf "\n${pgm_info}\n\n\n"
    fi
  fi
done
