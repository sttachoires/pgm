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
. ${PGM_LIB_DIR}/pgm_db.include


USAGE="${PRGNAME}\n"

for pgm_srv in $(getServers)
do
  printf "\n -----------------\n"
  printf " PostgreSQL server \"${pgm_srv}\""
  setServer ${pgm_srv}
  if [[ $? -ne 0 ]]; then
    printf " problem to set up\n -----------------\n"
  else
    pgm_report=$(checkEnvironment)
    if [[ $? -ne 0 ]]; then
      printf " environment problem:\n${pgm_reports// /$'\n'}"
    else
      for pgm_instance in $(getInstancesFromServer ${pgm_srv})
      do
        setInstance ${pgm_srv} ${pgm_instance}
        if [[ $? -ne 0 ]]; then
          printf " (Error)"
        else
          pgm_report=$(checkEnvironment)
          if [[ $? -ne 0 ]]; then
            printf " (Env error)"
          else
            printf "${pgm_instance} ("
            for pgm_database in $(databaseList ${pgm_srv} ${pgm_instance})
            do
              printf "'${pgm_database}'"
            done
          fi
        fi
      done
    fi
    printf "\n -----------------\n"
  fi
done
