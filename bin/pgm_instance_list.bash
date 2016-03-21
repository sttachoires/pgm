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
. ${PGM_LIB_DIR}/pgm_database.include


USAGE="${PRGNAME}\n"

getInstances pgm_instance_list
if [[ $? -ne 0 ]]; then
  exitError "Error getting instance list"
fi

for pgm_instance in ${pgm_instance_list}
do
  printf " PostgreSQL Instance \"${pgm_instance}\""
  getServersFromInstance ${pgm_instance} pgm_instance_list
  for pgm_server in ${pgm_instance_list}
  do
    setInstance ${pgm_server} ${pgm_instance}
    checkEnvironment pgm_errors
    if [[ $? -ne 0 ]]; then
      printf "  Problem setting PostgreSQL ${pgm_server} Instance \"${pgm_instance}\" : ${pgm_errors}"
    else
      getDatabasesFromInstance ${pgm_server} ${pgm_instance} pgm_database_list
      printf "  ${pgm_server} (${pgm_database_list})\n"
    fi
  done
done
