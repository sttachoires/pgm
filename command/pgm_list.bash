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

PGM_LOG="${PGM_LOG_DIR}/pgm_list.log"

analyzeParameters $*

getServers pgm_server_list
if [[ $? -ne 0 ]]; then
  printError "Error getting servers"
  exit 2
fi

for pgm_server in ${pgm_server_list}
do
  printf "PostgreSQL server \"${pgm_server}\"\n"
  setServer ${pgm_server}
  if [[ $? -ne 0 ]]; then
    printf "   problem to set up\n"
  else
    checkEnvironment pgm_report
    if [[ $? -ne 0 ]]; then
      printf "   environment problem:\n${pgm_reports// /$'\n'}"
    else
      getInstancesFromServer ${pgm_server} pgm_instance_list
      for pgm_instance in ${pgm_instance_list}
      do
        setInstance ${pgm_server} ${pgm_instance}
        if [[ $? -ne 0 ]]; then
          printf "  ${pgm_instance} problem to set up\n"
        else
          checkEnvironment pgm_report
          if [[ $? -ne 0 ]]; then
            printf "   ${pgm_instance} environment problem:\n${pgm_report// /$'\n'}"
          else
            getDatabasesFromInstance ${pgm_server} ${pgm_instance} pgm_database_list
            printf "   ${pgm_instance} (${pgm_database_list})\n"
          fi
        fi
      done
    fi
  fi
done
