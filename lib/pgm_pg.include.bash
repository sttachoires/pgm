#! @BASH@
# 
# Bash library for PostgreSQL.
#
# S. Tachoires		10/11/2014	Initial version
#
#set -xv

# INCLUDE
if [ "${PGM_PG_INCLUDE}" == "LOADED" ]; then
  return 0
fi
. @CONFDIR@/pgm.conf
if [ $? -ne 0 ]; then
  exit 1
fi
. ${PGM_LIB_DIR}/pgm_server.include
if [ $? -ne 0 ]; then
  exit 1
fi
. ${PGM_LIB_DIR}/pgm_util.include
if [ $? -ne 0 ]; then
  exit 1
fi

function pgExec()
{
  if [ $# -gt 1 ]; then
    dbname=$1
    request=$2
  else
    request=$1
  fi
  if [ ! -x ${PGM_PGHOME_DIR}/bin/psql ]; then
    printError "Problem with '${PGM_PGHOME_DIR}/bin/psql'"
  fi

  ${PGM_PGHOME_DIR}/bin/psql --host=${PGM_PGDATA_DIR} --port=${PGM_PGPORT} --tuples-only -v ON_ERROR_STOP=1 ${dbname} -c "${request}"
}

function startInstance()
{
  if [ $# -ne 2 ]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}

  pgm_options=""
  ping -c 1 "${PGM_PGLISTENER}" 2>&1 > /dev/null
  if [ $? -ne 0 ]; then
    pgm_options="${pgm_options} --host=${PGM_PGHOST}"
  fi

  pg_ctl -w -o "${pgm_options}" --pgdata=${PGM_PGDATA_DIR} --log=${PGM_PG_LOG} start
}

function stopInstance()
{
  if [ $# -ne 2 ]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}

  pg_ctl --pgdata=${PGM_PGDATA_DIR} --mode=fast stop
}

function reloadInstance()
{
  if [ $# -ne 2 ]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}

  pg_ctl --pgdata=${PGM_PGDATA_DIR} reload
}

function stateInstance()
{
  if [ $# -ne 2 ]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}

  pg_ctl --pgdata=${PGM_PGDATA_DIR} status
}


function promoteInstance()
{
  if [ $# -ne 2 ]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}

  pg_ctl --pgdata=${PGM_PGDATA_DIR} promote
}

function killInstance()
{
  if [ $# -ne 2 ]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}

  pg_ctl --pgdata=${PGM_PGDATA} --mode=immediate stop
  if [ $? -ne 0 ]; then
    if [ -e ${PGM_PGDATA}/postmaster.pid ]; then
      pgm_pgpid=$(head -1 ${PGM_PGDATA}/postmaster.pid)
      if [ $? -ne 0 ]; then
        return 2
      else
        pg_ctl TERM ${pgm_pgpid} kill
      fi
    fi
  fi
}

function setInstance()
{
  if [ $# -ne 2 ]; then
    return 1
  fi

  pgm_version=$1
  pgm_sid=$2
  
  setServer ${pgm_version}
  if [ $? -ne 0 ]; then
    return 2
  fi

  if [[ ${pgm_sid} =~ ${PGM_PGSID_AUTHORIZED_REGEXP} ]]; then
    # First set versions constants
    export PGM_PGSID=${pgm_sid}

    # Remove trailing slashes.
    for pgm_pattern in ${!PGMPG_PTRN_*}
    do
      eval pgm_value=\$${pgm_pattern}
      eval export ${pgm_pattern/PGMPG_PTRN_/PGM_}=\"${pgm_value%/}\"
    done

    # Try to determine host, port, autolaunch configuration, and running configuration
    pgm_line=$(egrep "^[[:space:]]*listen_addresses[[:space:]]*=" ${PGM_PG_CONF} 2>&1)
    if [ $? -eq 0 ]; then
      export PGM_PGLISTENER="$(echo ${pgm_line} | cut --delimiter='=' --fields=2)"
    fi
    PGM_PGHOST="${PGM_PGHOST// /}"
    PGM_PGLISTENER="${PGM_PGLISTENER// /}"
    PGM_PGLISTENER="${PGM_PGLISTENER:=${PGM_PGHOST}}"

    pgm_line=$(egrep "^[[:space:]]*port[[:space:]]*=" ${PGM_PG_CONF} 2>&1)
    if [ $? -eq 0 ]; then
      export PGM_PGPORT="$(echo ${pgm_line} | cut --delimiter='=' --fields=2)"
    else
      export PGM_PGPORT=5432
    fi
    PGM_PGPORT=${PGM_PGPORT// /}

    PGM_PG_LOG=${PGM_PG_LOG_DIR}/${PGM_PG_LOG_NAME}

    pgm_processes=$(ps -afe | egrep "-D[[:space:]][[:space:]]*${PGM_PGDATA_DIR}[[:space:]]" 2>&1)
    if [ $? -eq 0 ]; then
      export PGM_PGSTATUS="started"
      pgm_hostline=$(echo ${pgm_processes} | grep -o "[[:space:]][[:space:]]*-\(h|-host)[[:space:]][[:space:]]*[^[:space:]][^[:space:]]*[[:space:]]")
      if [ $? -eq 0 ]; then
        pgm_hostline=${pgm_hostline/ -\(h|host\)[ =]/}
        export PGM_PGREALHOST=${pgm_hostline// /}
      fi
      pgm_portline=$(echo ${pgm_processes} | grep -o "[[:space:]][[:space:]]*-\(p|-port\)[[:space:]][[:space:]]*[0-9][0-9]*[[:space:]]")
      if [ $? -eq 0 ]; then
        pgm_portline=${pgm_portline/ -\(p|-port\)[ =]/}
        export PGM_PGREALPORT=${pgm_portline// /}
      fi
    else
      export PGM_PGSTATUS="stopped"
    fi

    pgm_line=$(egrep --only-matching "^_:${PGM_PGSID}:${PGM_PGVERSION}:[yn]" ${PGM_PG_TAB} | head -1)
    if [ $? -eq 0 ]; then
      pgm_autolaunch=$(echo "${pgm_line}" | cut --delimiter=':' --fields=3)
      pgm_autolaunch=${pgm_line:0:1}
      export PGM_PGAUTOLAUNCH=${pgm_autolaunch,,}
    fi
    return 0
  else
    printInfo "Wrong instance name \"${pgm_sid}\"\n"
    return 3
  fi

}

function setDatabase()
{
  if [ $# -ne 3 ]; then
    return 1
  else
    pgm_version=$1
    pgm_sid=$2
    pgm_database=$3  
  fi


  setInstance ${pgm_version} ${pgm_sid}
  if [ $? -ne 0 ]; then
    return 2
  fi

  if [[ "${pgm_database}" =~ ${PGM_PGDATABASE_AUTHORIZED_REGEXP} ]]; then
    # First set versions constants
    export PGM_PGDATABASE="${pgm_database}"

    # Remove trailing slashes.
    for pgm_pattern in ${!PGMDBPATTERN_*}
    do
      eval pgm_value=\$${pgm_pattern}
      eval export ${pgm_pattern/PGMDBPATTERN_/PGM_}=\"${pgm_value%/}\"
    done

    return 0
  else
    printInfo "Wrong database name {pgm_database}\n"
    return 1
  fi
}

# Nothing should happens after next line
export PGM_PG_INCLUDE="LOADED"
