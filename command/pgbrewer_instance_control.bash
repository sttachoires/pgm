#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires		20/02/2016	Initial version
#
#set -xv

# CONSTANTS
PRGNAME=$(basename $0 2> /dev/null)
if [[ $? -ne 0 ]]; then
  PRGNAME="Unknown"
fi


# INCLUDE
. @CONFDIR@/pgbrewer.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/instance.include
. ${PGB_LIB_DIR}/inventory.include

export PGB_LOG="${PGB_LOG_DIR}/instance_control.log"

USAGE="${PRGNAME} VERSION SID start|stop|restart|monitor|clean|reload\nwhere:\n\tVERSION : Server full version\n\tSID : database identifier\n\tstart : start database if not already running\n\tstop : stop database\n\trestart : stop, start, when reload isn't enough\n\tmonitor : check that database is running and active\n\tclean : force quit\n\treload : reload cofiguration (postgres.conf, pg_hba.conf, et pg_ident.conf)\n"
if [[ $# -lt 3 ]]; then
  printInfo "${USAGE}\n"
  exit 1
fi
pgb_server=$1
pgb_instance=$2
pgb_action=$3

shift 3

analyzeParameters $*

isServerUnknown ${pgb_server}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged version of PostgreSQL ${pgb_server}\n"
fi
setServer ${pgb_server}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set PostgreSQL ${pgb_server}\n"
fi

isInstanceUnknownFromServer ${pgb_server} ${pgb_instance}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged instance ${pgb_instance}\n"
fi

setInstance ${pgb_server} ${pgb_instance}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set instance ${pgb_instance} of ${pgb_server} server\n"
fi

case ${pgb_action} in
  "start" ) startInstance ${pgb_server} ${pgb_instance}
            ;;

  "stop" )  stopInstance ${pgb_server} ${pgb_instance}
            ;;

  "restart" ) stopInstance ${pgb_server} ${pgb_instance}
              startInstance ${pgb_server} ${pgb_instance}
              ;;

  "reload" )
            reloadInstance ${pgb_server} ${pgb_instance}
            pgb_messages=$(tail ${PGB_PG_LOG} | grep "PG-55P02" 2>&1)
            if [[ $? -eq 0 ]]; then
              printInfo "Instance ${pgb_instance} need restart to set new parameters.\n${pgb_message} Please issue:\n\t${PRGMNAME} ${pgb_server} ${pgb_instance} restart\n"
            fi
            ;;

  "clean" )
            killInstance ${pgb_server} ${pgb_instance}
            ;;

  "monitor" )
             printf "PostgreSQL instance ${pgb_server} ${pgb_instance}\n"
             stateInstance ${pgb_server} ${pgb_instance} pgb_instance_status
             printf "${pgb_instance_status}\n"
             ;;

  "promote" )
             promoteInstance ${pgb_server} ${pgb_instance}
             ;;
    * ) 
       exitError "${USAGE}\n"
             ;;
esac
