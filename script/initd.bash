
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

local pgb_current_user=$(/usr/bin/whoami)
if [ "${pgb_current_user}" != "root" ]; then
  printf "${PRGNAME} should be launch as 'root' not '${pgb_current_user}'\n"
  exit 1
fi

if [[ $# -ne 1 ]]; then
  printf "${USAGE}\n"
  exit 1
fi

local pgb_var_lock=/var/lock/${PRGNAME}

local pgb_instance_dir_list=${PGB_CONF_DIR}/*/instances/*

for pgb_instance_line in "${pgb_instance_dir_list}"
do
  local pgb_inid=egrep --quiet "^[[:space:]]*PGB_PGAUTOSTART[[:space:]]*=[[:space:]]*yes" ${pgb_instance_dir}/instance.conf
  if [[ ${pgb_initd} -eq 0 ]]; then
    case "$1" in
      "stop" )
        su - @USER@ -c "@COMMANDDIR@/instance stop ${pgb_server} ${pgb_instance}"
        rm -f ${pgb_var_lock}
        ;;
   
      "start" )
        su - @USER@ -c "@COMMANDDIR@/instance start ${pgb_server} ${pgb_instance}"
        touch ${pgb_var_lock}
        ;;

      "restart" | "force-reload" )
        su - @USER@ -c "@COMMANDDIR@/instance stop ${pgb_server} ${pgb_instance}"
        su - @USER@ -c "@COMMANDDIR@/instance start ${pgb_server} ${pgb_instance}"
        touch ${pgb_var_lock}
        ;;

      "reload" )
        su - @USER@ -c "@COMMANDDIR@/instance reload ${pgb_server} ${pgb_instance}"
        touch ${pgb_var_lock}
        ;;

      "force-stop" )
        su - @USER@ -c "@COMMANDDIR@/instance kill ${pgb_server} ${pgb_instance}"
        rm ${pgb_var_lock}
        ;;
   
      "status" )
        su - @USER@ -c "@COMMANDDIR@/instance status ${pgb_server} ${pgb_instance}"
        ;;

      * )
        printf "Unknown option $1\n"
        exit 1
    esac
  fi
done

