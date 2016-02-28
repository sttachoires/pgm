
#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

# CONSTANTS
PRGNAME=$(basename $0 2> /dev/null)
if [ $? -ne 0 ]; then
  PRGNAME="Unknown"
fi

USAGE="${PRGNAME}\n"

pgm_current_user=$(/usr/bin/whoami)
if [ "${pgm_current_user}" != "root" ]; then
  printf "${PRGNAME} should be launch as 'root' not '${pgm_current_user}'\n"
  exit 1
fi

if [ $# -ne 1 ]; then
  printf "${USAGE}\n"
  exit 1
fi

pgm_var_lock=/var/lock/${PRGNAME}

pgm_instance_line_list=$(egrep --only-matching "\*:[^: ]*:[^: ]*:y" @INVENTORYDIR@/pgtab)
for pgm_instance_line in "${pgm_instance_line_list}"
do
  pgm_instance=$(echo "${pgm_instance_line}" | cut --delimiter ':' --fields 2)
  pgm_version=$(echo "${pgm_instance_line}" | cut --delimiter ':' --fields 3)
  case "$1" in
    "stop" )
      su - @USER@ -c "@SCRIPTDIR@/pgm_instance_stop ${pgm_version} ${pgm_instance}"
      rm -f ${pgm_var_lock}
      ;;
   
    "start" )
      su - @USER@ -c "@SCRIPTDIR@/pgm_instance_start ${pgm_version} ${pgm_instance}"
      touch ${pgm_var_lock}
      ;;

    "restart" | "force-reload" )
      su - @USER@ -c "@SCRIPTDIR@/pgm_instance_stop ${pgm_version} ${pgm_instance}"
      su - @USER@ -c "@SCRIPTDIR@/pgm_instance_start ${pgm_version} ${pgm_instance}"
      touch ${pgm_var_lock}
      ;;

    "reload" )
      su - @USER@ -c "@SCRIPTDIR@/pgm_instance_reload ${pgm_version} ${pgm_instance}"
      touch ${pgm_var_lock}
      ;;

    "force-stop" )
      su - @USER@ -c "@SCRIPTDIR@/pgm_instance_kill ${pgm_version} ${pgm_instance}"
      rm ${pgm_var_lock}
      ;;
   
    "status" )
      su - @USER@ -c "@SCRIPTDIR@/pgm_instance_status ${pgm_version} ${pgm_instance}"
      ;;

    * )
      printf "Unknown option $1\n"
      exit 1
  esac
done
