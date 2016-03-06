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
. @LIBDIR@/pgm_util.include
if [[ $? -ne 0 ]]; then
  printf "Error loading utility library\n"
  exit 2
fi
. @LIBDIR@/pgm_server.include
if [[ $? -ne 0 ]]; then
  printf "Error loading server library\n"
  exit 3
fi
. @LIBDIR@/pgm_pg.include
if [[ $? -ne 0 ]]; then
  printf "Error loading instance library\n"
  exit 4
fi
. @LIBDIR@/pgm_db.include
if [[ $? -ne 0 ]]; then
  printf "Error loading instance library\n"
  exit 4
fi


USAGE="${PRGNAME}\n"

for pgm_instance in $(allInstancesList)
do
  printf "\n -----------------\n"
  printf " PostgreSQL Instance \"${pgm_instance}\""
  setInstance ${pgm_srv}
  pgm_errors=$(checkEnvironment)
  if [[ $? -ne 0 ]]; then
    printf "Problem setting PostgreSQL server \"${pgm_srv}\"\n -----------------\n"
  else
    for pgm_instance in $(instanceList ${pgm_srv})
    do
      setInstance ${pgm_srv} ${pgm_instance}
      pgm_report=$(checkEnvironment)
      if [[ $? -ne 0 ]]; then
        printError " (Error)"
      else
        printf "${pgm_instance}("
        for pgm_database in $(databaseList ${pgm_srv} ${pgm_instance})
        do
          printf "'${pgm_database}'"
        done
        printf ")"
      fi
    done
    printf "\n -----------------\n"
  fi
done
