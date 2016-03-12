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

for pgm_instance in $(getInstances)
do
  printf " PostgreSQL Instance \"${pgm_instance}\""
  for pgm_server in $(getServersFromInstance ${pgm_instance})
  do
    setInstance ${pgm_server} ${pgm_instance}
    pgm_errors=$(checkEnvironment)
    if [[ $? -ne 0 ]]; then
      printf "Problem setting PostgreSQL ${pgm_server} Instance \"${pgm_instance}\" : ${pgm_errors}"
    else
      printf " ${pgm_server} ("
      for pgm_database in $(getDatabasesFromInstance ${pgm_server} ${pgm_instance})
      do
        printf "'${pgm_database}'"
      done
      printf ")\n"
    fi
    printf "\n"
  done
done
