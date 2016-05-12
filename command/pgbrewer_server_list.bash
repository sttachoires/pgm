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

options=""

# INCLUDE
. @CONFDIR@/pgbrewer.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/inventory.include
. ${PGB_LIB_DIR}/database.include


USAGE="${PRGNAME}\n"

analyzeParameters $*

getServers pgb_server_list
for pgb_server in ${pgb_server_list}
do
  printf "PostgreSQL server '${pgb_server}'\n"
  setServer ${pgb_server}
  checkEnvironment pgb_errors
  if [[ $? -ne 0 ]]; then
    printError "Problem setting PostgreSQL server '${pgb_server}'\n"
  else
    getInstancesFromServer ${pgb_server} pgb_instance_list
    for pgb_instance in ${pgb_instance_list}
    do
      setInstance ${pgb_srv} ${pgb_instance}
      checkEnvironment pgb_report
      if [[ $? -ne 0 ]]; then
        printError " (Error)\n"
      else
        getDatabasesFromInstance ${pgb_srv} ${pgb_instance} pgb_database_list
        printf " ${pgb_instance} (${pgb_database_list})\n"
      fi
    done
  fi
done
