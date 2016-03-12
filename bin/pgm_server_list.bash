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
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_database.include


USAGE="${PRGNAME}\n"

for pgm_srv in $(getServers)
do
  printf "\n -----------------\n"
  printf " PostgreSQL server \"${pgm_srv}\":"
  setServer ${pgm_srv}
  pgm_errors=$(checkEnvironment)
  if [[ $? -ne 0 ]]; then
    printError "Problem setting PostgreSQL server \"${pgm_srv}\"\n -----------------\n"
  else
    for pgm_instance in $(getInstancesFromServer ${pgm_srv})
    do
      setInstance ${pgm_srv} ${pgm_instance}
      pgm_report=$(checkEnvironment)
      if [[ $? -ne 0 ]]; then
        printError " (Error)"
      else
        printf "${pgm_instance} ("
        for pgm_database in $(getDatabasesFromInstance ${pgm_srv} ${pgm_instance})
        do
          printf "'${pgm_instance}'"
        done
      fi
    done
    printf "\n -----------------\n"
  fi
done
