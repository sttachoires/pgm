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
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_database.include


USAGE="${PRGNAME}\n"


declareFunction pgm_list $*

pgm_server_list="$(getServers)"
for pgm_server in ${pgm_server_list}
do
  printf "\nPostgreSQL server \"${pgm_server}\"\n"
  setServer ${pgm_server}
  if [[ $? -ne 0 ]]; then
    printf "   problem to set up\n"
  else
    pgm_report="$(checkEnvironment)"
    if [[ $? -ne 0 ]]; then
      printf "   environment problem:\n${pgm_reports// /$'\n'}"
    else
      pgm_instance_list="$(getInstancesFromServer ${pgm_server})"
      for pgm_instance in ${pgm_instance_list}
      do
        setInstance ${pgm_server} ${pgm_instance}
        if [[ $? -ne 0 ]]; then
          printf "  ${pgm_instance} problem to set up\n"
        else
          pgm_report=$(checkEnvironment)
          if [[ $? -ne 0 ]]; then
            printf "    ${pgm_instance} environment problem:\n${pgm_reports// /$'\n'}"
          else
            pgm_database_list="$(getDatabasesFromInstance ${pgm_server} ${pgm_instance})"
            printf "   ${pgm_instance} (${pgm_database_list})\n"
          fi
        fi
      done
    fi
  fi
  printf "\n"
done
