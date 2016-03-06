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

for pgm_srv in $(serverList)
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
      for pgm_instance in $(instanceList ${pgm_srv})
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
