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
. ${PGM_LIB_DIR}/util.include
. ${PGM_LIB_DIR}/inventory.include
. ${PGM_LIB_DIR}/database.include


USAGE="${PRGNAME}\n"

analyzeParameters $*

getServers pgm_server_list
for pgm_server in ${pgm_server_list}
do
  printf "PostgreSQL server '${pgm_server}'\n"
  setServer ${pgm_server}
  checkEnvironment pgm_errors
  if [[ $? -ne 0 ]]; then
    printError "Problem setting PostgreSQL server '${pgm_server}'\n"
  else
    getInstancesFromServer ${pgm_server} pgm_instance_list
    for pgm_instance in ${pgm_instance_list}
    do
      setInstance ${pgm_srv} ${pgm_instance}
      checkEnvironment pgm_report
      if [[ $? -ne 0 ]]; then
        printError " (Error)\n"
      else
        getDatabasesFromInstance ${pgm_srv} ${pgm_instance} pgm_database_list
        printf " ${pgm_instance} (${pgm_database_list})\n"
      fi
    done
  fi
done
