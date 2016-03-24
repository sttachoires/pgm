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
. @CONFDIR@/pgm.conf
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_instance.include
. ${PGM_LIB_DIR}/pgm_pginventory.include

export PGM_LOG="${PGM_LOG_DIR}/instance_control.log"

USAGE="${PRGNAME} VERSION SID start|stop|restart|monitor|clean|reload\nwhere:\n\tVERSION : Server full version\n\tSID : database identifier\n\tstart : start database if not already running\n\tstop : stop database\n\trestart : stop, start, when reload isn't enough\n\tmonitor : check that database is running and active\n\tclean : force quit\n\treload : reload cofiguration (postgres.conf, pg_hba.conf, et pg_ident.conf)\n"
if [[ $# -lt 3 ]]; then
  printInfo "${USAGE}\n"
  exit 1
fi
pgm_server=$1
pgm_instance=$2
pgm_action=$3

shift 3

analyzeParameters $*

isServerUnknown ${pgm_server}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged version of PostgreSQL ${pgm_server}\n"
fi
setServer ${pgm_server}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set PostgreSQL ${pgm_server}\n"
fi

isInstanceUnknownFromServer ${pgm_server} ${pgm_instance}
if [[ $? -ne 0 ]]; then
  exitError "Unmanaged instance ${pgm_instance}\n"
fi

setInstance ${pgm_server} ${pgm_instance}
if [[ $? -ne 0 ]]; then
  exitError "Cannot set instance ${pgm_instance} of ${pgm_server} server\n"
fi

case ${pgm_action} in
  "start" ) startInstance ${pgm_server} ${pgm_instance}
            ;;

  "stop" )  stopInstance ${pgm_server} ${pgm_instance}
            ;;

  "restart" ) stopInstance ${pgm_server} ${pgm_instance}
              startInstance ${pgm_server} ${pgm_instance}
              ;;

  "reload" )
            reloadInstance ${pgm_server} ${pgm_instance}
            pgm_messages=$(tail ${PGM_PG_LOG} | grep "PG-55P02" 2>&1)
            if [[ $? -eq 0 ]]; then
              printInfo "Instance ${pgm_instance} need restart to set new parameters.\n${pgm_message} Please issue:\n\t${PRGMNAME} ${pgm_server} ${pgm_instance} restart\n"
            fi
            ;;

  "clean" )
            killInstance ${pgm_server} ${pgm_instance}
            ;;

  "monitor" )
             printf "PostgreSQL instance ${pgm_server} ${pgm_instance}\n"
             stateInstance ${pgm_server} ${pgm_instance} pgm_instance_status
             printf "${pgm_instance_status}\n"
             ;;

  "promote" )
             promoteInstance ${pgm_server} ${pgm_instance}
             ;;
    * ) 
       exitError "${USAGE}\n"
             ;;
esac
