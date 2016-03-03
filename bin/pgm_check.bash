#! @BASH@
#
# Check configuration of PGM.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

# CONSTANTS
PRGNAME=$(basename $0 2> /dev/null)
if [ $? -ne 0 ]; then
  PRGNAME="Unknown"
fi

options=""

# INCLUDE
. @CONFDIR@/pgm.conf
if [ $? -ne 0 ]; then
  printt "Error loading configuration file\n"
  exit 1
fi
. @LIBDIR@/pgm_util.include
if [ $? -ne 0 ]; then
  printt "Error loading utility library\n"
  exit 2
fi
. @LIBDIR@/pgm_server.include
if [ $? -ne 0 ]; then
  printt "Error loading server library\n"
  exit 3
fi
. @LIBDIR@/pgm_pg.include
if [ $? -ne 0 ]; then
  printt "Error loading instance library\n"
  exit 4
fi


USAGE="${PRGNAME}\n"

pgm_missing_envs=$(checkEnvironment)
if [ $? -ne 0 ]; then
  printf "Configuration Error:\n\n${pgm_missing_envs// /$'\n'}\n"
else
  printf "Environment OK\n"
fi

