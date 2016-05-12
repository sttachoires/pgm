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

# INCLUDE
. @CONFDIR@/pgbrewer.conf
if [[ $? -ne 0 ]]; then
  printf "Error loading configuration file\n"
  exit 1
fi
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/inventory.include
. ${PGB_LIB_DIR}/database.include


USAGE="${PRGNAME}\n"

analyzeParameters $*

getInstances pgb_instance_list
if [[ $? -ne 0 ]]; then
  exitError "Error getting instance list"
fi

for pgb_instance in ${pgb_instance_list}
do
  printf " PostgreSQL Instance \"${pgb_instance}\"\n"
  getServersFromInstance ${pgb_instance} pgb_server_list
  if [[ $? -ne 0 ]]; then
    printf " No server !\n"
  else
    for pgb_server in ${pgb_server_list}
    do
      getDatabasesFromInstance ${pgb_server} ${pgb_instance} pgb_database_list
      if [[ $? -eq 0 ]]; then
        printf "  ${pgb_server} (${pgb_database_list})\n"
      else
        printf "  ${pgb_server} No databases (?)\n"
      fi
    done
  fi
done
