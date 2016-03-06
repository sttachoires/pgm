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

options=""

# INCLUDE
. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  printf "Error loading configuration file\n"
  exit 1
fi
. @LIBDIR@/pgm_util.include
if [[ $? -ne 0 ]]; then
  printf "Error loading utility library\n"
  exit 2
fi
. @LIBDIR@/pgm_server.include
if [[ $? -ne 0 ]]; then
  printf "Error loading server library\n"
  exit 2
fi

USAGE="${PRGNAME} [VERSION]\nCheck server configuration. All if no VERSION\nwhere:\n\tVERSION the server version to check"

if [[ $# -gt 0 ]]; then
  pgm_server_list=$*
else
  pgm_server_list=$(serverList)
fi

for pgm_version in ${pgm_server_list}
do
  printf "PostgreSQL server ${pgm_version}"
  setServer ${pgm_version}
  if [[ $? -eq 0 ]]; then
    pgm_missing_envs="$(checkEnvironment)"
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

