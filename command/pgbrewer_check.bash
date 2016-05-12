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

export PGB_LOG="${PGB_LOG_DIR}/check.log"

# INCLUDE
. @CONFDIR@/pgbrewer.conf
if [[ $? -ne 0 ]]; then
  printf "Error loading configuration file\n"
  exit 1
fi
. @LIBDIR@/util.include
if [[ $? -ne 0 ]]; then
  printf "Error loading utility library\n"
  exit 2
fi

USAGE="${PRGNAME}\n"
analyzeParameters $*

checkEnvironment pgb_missing_envs
if [[ $? -ne 0 ]]; then
  printf "Configuration Error:\n\n${pgb_missing_envs// /$'\n'}\n"
else
  printf "Environment OK\n"
fi

