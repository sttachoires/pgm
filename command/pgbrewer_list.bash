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
. ${PGB_LIB_DIR}/database.include


USAGE="${PRGNAME}\n"

PGB_LOG="${PGB_LOG_DIR}/pgb_list.log"

analyzeParameters $*

getServers pgb_server_list
if [[ $? -ne 0 ]]; then
  printError "Error getting servers"
  exit 2
fi

for pgb_server in ${pgb_server_list}
do
  printf "PostgreSQL server \"${pgb_server}\"\n"
  setServer ${pgb_server}
  if [[ $? -ne 0 ]]; then
    printf "   problem to set up\n"
  else
    checkEnvironment pgb_report
    if [[ $? -ne 0 ]]; then
      printf "   environment problem:\n${pgb_reports// /$'\n'}"
    else
      getInstancesFromServer ${pgb_server} pgb_instance_list
      for pgb_instance in ${pgb_instance_list}
      do
        setInstance ${pgb_server} ${pgb_instance}
        if [[ $? -ne 0 ]]; then
          printf "  ${pgb_instance} problem to set up\n"
        else
          checkEnvironment pgb_report
          if [[ $? -ne 0 ]]; then
            printf "   ${pgb_instance} environment problem:\n${pgb_report// /$'\n'}"
          else
            getDatabasesFromInstance ${pgb_server} ${pgb_instance} pgb_database_list
            printf "   ${pgb_instance} (${pgb_database_list})\n"
          fi
        fi
      done
    fi
  fi
done
