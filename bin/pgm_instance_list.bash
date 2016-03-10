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

for pgm_instance in $(getInstances)
do
  printf " PostgreSQL Instance \"${pgm_instance}\""
  setInstance ${pgm_srv}
  pgm_errors=$(checkEnvironment)
  if [[ $? -ne 0 ]]; then
    printf "Problem setting PostgreSQL Instance \"${pgm_instance}\""
  else
    for pgm_database in $(getDatabasesFromInstance ${pgm_srv} ${pgm_instance})
    do
      printf "'${pgm_database}'"
    done
  fi
  printf "\n"
done
