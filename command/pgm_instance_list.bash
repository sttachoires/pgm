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
. ${PGM_LIB_DIR}/util.include
. ${PGM_LIB_DIR}/inventory.include
. ${PGM_LIB_DIR}/database.include


USAGE="${PRGNAME}\n"

analyzeParameters $*

getInstances pgm_instance_list
if [[ $? -ne 0 ]]; then
  exitError "Error getting instance list"
fi

for pgm_instance in ${pgm_instance_list}
do
  printf " PostgreSQL Instance \"${pgm_instance}\"\n"
  getServersFromInstance ${pgm_instance} pgm_server_list
  if [[ $? -ne 0 ]]; then
    printf " No server !\n"
  else
    for pgm_server in ${pgm_server_list}
    do
      getDatabasesFromInstance ${pgm_server} ${pgm_instance} pgm_database_list
      if [[ $? -eq 0 ]]; then
        printf "  ${pgm_server} (${pgm_database_list})\n"
      else
        printf "  ${pgm_server} No databases (?)\n"
      fi
    done
  fi
done
