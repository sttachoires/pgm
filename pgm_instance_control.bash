#! /bin/bash
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires		20/02/2016	Initial version
#
#set -xv

# CONSTANTS
PRGNAME=$(basename $0 2> /dev/null)
if [ $? -ne 0 ]; then
  PRGNAME="Unknown"
fi

options=""

# INCLUDE
. /home/stephane/postgres/github/pgm/pgm.conf
. /home/stephane/postgres/github/pgm/pgm_util.include
. /home/stephane/postgres/github/pgm/pgm_server.include
. /home/stephane/postgres/github/pgm/pgm_pg.include


USAGE="${PRGNAME} VERSION SID start|stop|restart|monitor|clean|reload\nwhere:\n\tVERSION : Server full version\n\tSID : database identifier\n\tstart : start database if not already running\n\tstop : stop database\n\trestart : stop, start, when reload isn't enough\n\tmonitor : check that database is running and active\n\tclean : force quit\n\treload : reload cofiguration (postgres.conf, pg_hba.conf, et pg_ident.conf)\n"

if [ $# -ne 3 ]; then
  printf "${USAGE}\n"
  exit 1
fi

pgm_version=$1
egrep -q "\*:\*:${pgm_version}" ${PGM_PGTAB}
if [ $? -ne 0 ]; then
  exitError "Unmanaged version pf PostgreSQM ${pgm_version}\n"
fi


pgm_instance=$2
egrep -q "\*:${pgm_instance}:*:?" ${PGM_PGTAB}
if [ $? -ne 0 ]; then
  exitError "Unmanaged SID ${pgm_instance}\n"
fi

setInstance ${pgm_version} ${pgm_instance}
if [ $? -ne 0 ]; then
  exitError "Cannot set instance ${pgm_instance} of ${pgm_version} server\n"
fi

pgm_action=$3
case ${pgm_action} in
  "start" ) startInstance ${pgm_version} ${pgm_sid}
            ;;

  "stop" )  stopInstance ${pgm_version} ${pgm_sid}
            ;;

  "restart" ) stopInstance ${pgm_version} ${pgm_sid}
              startInstance ${pgm_version} ${pgm_sid}
              ;;

  "reload" )
            reloadInstance ${pgm_version} ${pgm_sid}
            pgm_messages=$(tail ${PGM_PGLOG} | grep "PG-55P02" 2>&1)
            if [ $? -eq 0 ]; then
              printf "Instance ${pgm_sid} need restart to set new parameters.\n${pgm_message} Please issue:\n\t${PRGMNAME} ${pgm_version} ${pgm_sid} restart\n"
            fi
            ;;

  "clean" )
            killInstance ${pgm_version} ${pgm_sid}
            ;;

  "monitor" )
             stateInstance ${pgm_version} ${pgm_sid}
             ;;

  "promote" )
             promoteInstance ${pgm_version} ${pgm_sid}
             ;;
    * ) 
       exitError "${USAGE}\n"
             ;;
esac
