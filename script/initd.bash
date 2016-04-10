
#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

# CONSTANTS
local PRGNAME=$(basename $0 2> /dev/null)
if [[ $? -ne 0 ]]; then
  local PRGNAME="Unknown"
fi

export USAGE="${PRGNAME}\n"

local pgm_current_user=$(/usr/bin/whoami)
if [ "${pgm_current_user}" != "root" ]; then
  printf "${PRGNAME} should be launch as 'root' not '${pgm_current_user}'\n"
  exit 1
fi

if [[ $# -ne 1 ]]; then
  printf "${USAGE}\n"
  exit 1
fi

local pgm_var_lock=/var/lock/${PRGNAME}

local pgm_instance_line_list=$(egrep --only-matching "_:[^: ]*:[^: ]*:y" @INVENTORYDIR@/autostart)
for pgm_instance_line in "${pgm_instance_line_list}"
do
  local pgm_instance=$(echo "${pgm_instance_line}" | cut --delimiter ':' --fields 2)
  local pgm_server=$(echo "${pgm_instance_line}" | cut --delimiter ':' --fields 3)
  case "$1" in
    "stop" )
      su - @USER@ -c "@COMMANDDIR@/instance stop ${pgm_server} ${pgm_instance}"
      rm -f ${pgm_var_lock}
      ;;
   
    "start" )
      su - @USER@ -c "@COMMANDDIR@/instance start ${pgm_server} ${pgm_instance}"
      touch ${pgm_var_lock}
      ;;

    "restart" | "force-reload" )
      su - @USER@ -c "@COMMANDDIR@/instance stop ${pgm_server} ${pgm_instance}"
      su - @USER@ -c "@COMMANDDIR@/instance start ${pgm_server} ${pgm_instance}"
      touch ${pgm_var_lock}
      ;;

    "reload" )
      su - @USER@ -c "@COMMANDDIR@/instance reload ${pgm_server} ${pgm_instance}"
      touch ${pgm_var_lock}
      ;;

    "force-stop" )
      su - @USER@ -c "@COMMANDDIR@/instance kill ${pgm_server} ${pgm_instance}"
      rm ${pgm_var_lock}
      ;;
   
    "status" )
      su - @USER@ -c "@COMMANDDIR@/instance status ${pgm_server} ${pgm_instance}"
      ;;

    * )
      printf "Unknown option $1\n"
      exit 1
  esac
done

