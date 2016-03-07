#! @BASH@
# 
# Bash library for PostgreSQL.
#
# S. Tachoires		10/11/2014	Initial version
#
#set -xv

# INCLUDE
if [[ "${PGM_PG_INCLUDE}" == "LOADED" ]]; then
  return 0
fi
. @CONFDIR@/pgm.conf
. ${PGM_LIB_DIR}/pgm_server.include
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include

function startInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}
  if [[ $? -ne 0 ]]; then
    return 2
  fi

  pgm_options=""
  ping -c 1 "${PGM_PGLISTENER:-${PGM_PGHOST}}" 2>&1 > /dev/null
  if [[ $? -ne 0 ]]; then
    pgm_options="-o \"${pgm_options} --host=${PGM_PGHOST}\""
  fi

  ${PGM_PGBIN_DIR}/pg_ctl -w ${pgm_options} --pgdata=${PGM_PGDATA_DIR} --log=${PGM_PG_LOG} start
}

function stopInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}
  if [[ $? -ne 0 ]]; then
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA_DIR} --mode=fast stop
}

function reloadInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}
  if [[ $? -ne 0 ]]; then
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA_DIR} reload
}

function stateInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}
  if [[ $? -ne 0 ]]; then
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA_DIR} status
}


function promoteInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}
  if [[ $? -ne 0 ]]; then
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA_DIR} promote
}

function killInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_sid=$2
  setInstance ${pgm_version} ${pgm_sid}
  if [[ $? -ne 0 ]]; then
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA} --mode=immediate stop
  if [[ $? -ne 0 ]]; then
    if [[ -e ${PGM_PGDATA}/postmaster.pid ]]; then
      pgm_pgpid=$(head -1 ${PGM_PGDATA}/postmaster.pid)
      if [[ $? -ne 0 ]]; then
        return 3
      else
        ${PGM_PGBIN_DIR}/pg_ctl TERM ${pgm_pgpid} kill
      fi
    fi
  fi
}

function setInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_sid=$2
  
  setServer ${pgm_version}
  if [[ $? -ne 0 ]]; then
    return 2
  fi

  if [[ ${pgm_sid} =~ ${PGM_PGINSTANCE_AUTHORIZED_REGEXP} ]]; then
    # First set instance constants
    export PGM_PGINSTANCE=${pgm_sid}

    # Remove trailing slashes.
    for pgm_pattern in ${!PGMPG_PTRN_*}
    do
      eval pgm_value=\$${pgm_pattern}
      eval export ${pgm_pattern/PGMPG_PTRN_/PGM_}=\"${pgm_value%/}\"
    done

    # Try to determine host, port, autolaunch configuration, and running configuration
    pgm_line=$(egrep "^[[:space:]]*listen_addresses[[:space:]]*=" ${PGM_PG_CONF} 2>&1)
    if [[ $? -eq 0 ]]; then
      export PGM_PGLISTENER="$(echo ${pgm_line} | cut --delimiter='=' --fields=2)"
    fi
    PGM_PGHOST=$(uname --nodename)
    PGM_PGHOST="${PGM_PGHOST// /}"
    PGM_PGLISTENER="${PGM_PGLISTENER// /}"
    PGM_PGREALLISTENER="${PGM_PGLISTENER:-${PGM_PGHOST}}"

    pgm_line=$(egrep "^[[:space:]]*port[[:space:]]*=" ${PGM_PG_CONF} 2>&1)
    if [[ $? -eq 0 ]]; then
      export PGM_PGPORT="$(echo ${pgm_line} | cut --delimiter='=' --fields=2)"
    else
      export PGM_PGPORT=5432
    fi
    PGM_PGPORT=${PGM_PGPORT// /}

    export PGM_PG_LOG=${PGM_PG_LOG_DIR}/${PGM_PG_LOG_NAME}

    pgm_processes=$(ps -afe | egrep "-D[[:space:]][[:space:]]*${PGM_PGDATA_DIR}[[:space:]]" 2>&1)
    if [[ $? -eq 0 ]]; then
      export PGM_PGSTATUS="started"
      pgm_hostline=$(echo ${pgm_processes} | grep -o "[[:space:]][[:space:]]*-\(h|-host)[[:space:]][[:space:]]*[^[:space:]][^[:space:]]*[[:space:]]")
      if [[ $? -eq 0 ]]; then
        pgm_hostline=${pgm_hostline/ -\(h|host\)[ =]/}
        export PGM_PGREALHOST=${pgm_hostline// /}
      fi
      pgm_portline=$(echo ${pgm_processes} | grep -o "[[:space:]][[:space:]]*-\(p|-port\)[[:space:]][[:space:]]*[0-9][0-9]*[[:space:]]")
      if [[ $? -eq 0 ]]; then
        pgm_portline=${pgm_portline/ -\(p|-port\)[ =]/}
        export PGM_PGREALPORT=${pgm_portline// /}
      fi
    else
      export PGM_PGSTATUS="stopped"
    fi

    export PGM_PGAUTOLAUNCH=$(getAutolaunchFromInstance ${PGM_PGVERSION} ${PGM_PGINSTANCE})
    return 0
  else
    printInfo "Wrong instance name \"${pgm_sid}\"\n"
    return 3
  fi
}

function checkAllInstances()
{
  if [[ $# -ne 1 ]]; then
    return 1
  fi

  pgm_report=""
  pgm_status=0
  pgm_version=$1

  for pgm_instance in $(getInstances ${pgm_version})
  do
    pgm_report="${pgm_report} $(checkInstance ${pgm_version} ${pgm_instance})"
    if [[ $? -ne 0 ]]; then
      pgm_status=$(( ${pgm_status} + 1 ))
    fi
  done

  printf "${pgm_report}"
  return ${pgm_status}
}

function checkInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_report=""
  pgm_status=0
  pgm_version=$1
  pgm_instance=$2

  setInstance ${pgm_version} ${pgm_instance} && checkEnvironment
}

function initInstance ()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2

  if [[ "${PGM_PGDATA_DIR}x" == "x" ]] || [[ "${PGM_PGXLOG_DIR}x" == "x" ]] || [[ "${PGM_PGDATA_DIR}x" == "x" ]]; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 1
    fi
  fi

  # Create cluster
  ${PGM_PGBIN_DIR}/initdb --pgdata=${PGM_PGDATA_DIR} --encoding=UTF8 --xlogdir=${PGM_PGXLOG_DIR} --data-checksums --no-locale
}

function logrotateInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2

  if [[ "${PGM_LOGROTATE_CONF}x" == "x" ]] || [[ "${PGM_PG_LOG_DIR}x" == "x" ]] || [[ "${PGM_LOGROTATE_ENTRY}" ]]; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  fi

  touch ${PGM_LOGROTATE_CONF}
  egrep --quiet --only-matching "${PGM_PG_LOG_DIR}/\*.log" ${PGM_LOGROTATE_CONF}
  if [[ $? -ne 0 ]]; then
    printf "${PGM_LOGROTATE_ENTRY}" >> ${PGM_LOGROTATE_CONF}
  fi
}

function checkInstanceFS ()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2
  pgm_result=$3

  if [[ ! -v PGM_PGFSLIST ]]; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  fi

  pgm_mountlst="$(mount -l)"
  for pgm_fs in ${PGM_PGFSLIST}
  do
    echo "${pgm_mountlst}" | grep --quiet "${pgm_fs}"
    if [[ $? -ne 0 ]]; then
      pgm_result=$(( pgm_result++ ))
    fi
  done

  return ${pgm_result}
}


function createRecovery ()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2

  if [[ "${PGM_PGRECOVER_CONF}x" == "x" ]] || [[ "${PGM_TEMPLATE_DIR}x" == "x" ]] ; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  fi
  pgm_name=$(basename ${PGM_PGRECOVER_CONF})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  if [[ "${pgm_tpl}x" == "x" ]] || [[ ! -r ${pgm_tpl} ]]; then
    return 3
  fi
  instantiateTemplate ${pgm_tpl} ${PGM_PGRECOVER_CONF}
}


function createConf ()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2

  if [[ "${PGM_PG_CONF}x" == "x" ]] || [[ "${PGM_TEMPLATE_DIR}x" == "x" ]] ; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  fi
  pgm_name=$(basename ${PGM_PG_CONF})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  if [[ "${pgm_tpl}x" == "x" ]] || [[ ! -r ${pgm_tpl} ]]; then
    return 3
  fi
  instantiateTemplate ${pgm_tpl} ${PGM_PG_CONF}
}


function createHBA ()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2

  if [[ "${PGM_PGHBA_CONF}x" == "x" ]] || [[ "${PGM_TEMPLATE_DIR}x" == "x" ]] ; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  fi

  pgm_name=$(basename ${PGM_PGHBA_CONF})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  if [[ "${pgm_tpl}x" == "x" ]] || [[ ! -r ${pgm_tpl} ]]; then
    return 3
  fi

  instantiateTemplate ${pgm_tpl} ${PGM_PGHBA_CONF}
}

function createIdent ()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_version=$1 
  pgm_instance=$2

  if [[ "${PGM_PGIDENT_CONF}x" == "x" ]] || [[ "${PGM_TEMPLATE_DIR}x" == "x" ]] ; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  fi

  pgm_name=$(basename ${PGM_PGIDENT_CONF})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  if [[ "${pgm_tpl}x" == "x" ]] || [[ ! -r ${pgm_tpl} ]]; then
    return 3
  fi

  instantiateTemplate ${pgm_tpl} ${PGM_PGIDENT_CONF}
}

function createExtentions()
{
  pgm_result=0
  for pgm_extention in ${PGM_PGEXTENSIONS_TO_CREATE//,/}
  do
    databaseExec ${PGM_PGFULL_VERSION} ${PGM_PGINSTANCE} template1 "CREATE EXTENSION ${pgm_extention};"
    if [[ $? -ne 0 ]]; then
      pgm_result=$(( ${pgm_result}++ ))
    fi
  done
}

function provideInstanceDirectories()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2

  if ! [[ -v PGM_PGDATA_DIR ]] || ! [[ -v PGM_PGXLOG_DIR ]] || ! [[ -v PGM_PG_LOG_DIR ]] || ! [[ -v PGM_PGARCHIVELOG_DIR ]]; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 1
    fi
  fi

  mkdir -p ${PGM_PGDATA_DIR}
  chmod u=rwx,go= ${PGM_PGDATA_DIR}
  mkdir -p ${PGM_PGXLOG_DIR}
  mkdir -p ${PGM_PG_LOG_DIR}
  mkdir -p ${PGM_PGARCHIVELOG_DIR}
}

function createInstance()
{
  if [[ $# -ne 4 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2
  pgm_port=$3
  pgm_listener=$4
  pgm_result=0
  pgm_report=""

  checkInstanceFS
  if [[ $? -ne 0 ]]; then
    return 2
  fi
  buildDirectories
  if [[ $? -ne 0 ]]; then
    return 3
  fi
  initInstance ${pgm_version} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    return 4
  fi
  createPgConf
  if [[ $? -ne 0 ]]; then
    return 5
  fi
  createRecovery
  if [[ $? -ne 0 ]]; then
    return 6
  fi
  createHBA
  if [[ $? -ne 0 ]]; then
    return 7
  fi
  createIdent
  if [[ $? -ne 0 ]]; then
    return 8
  fi
  addInstance ${pgm_version} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    return 9
  fi
  startInstance "${PGM_PGFULL_VERSION}" "${PGM_PGINSTANCE}"
  if [[ $? -ne 0 ]]; then
    return 10
  fi
  createExtentions
  if [[ $? -ne 0 ]]; then
    return 11
  fi
  logrotateInstance
  if [[ $? -ne 0 ]]; then
    return 12
  fi
}

# Nothing should happens after next line
export PGM_PG_INCLUDE="LOADED"
