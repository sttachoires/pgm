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
export PGM_PG_INCLUDE="LOADED"

. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGM_CONF_DIR}/instance.conf

. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_server.include
. ${PGM_LIB_DIR}/pgm_database.include

function startInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2

  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}\n"
    return 2
  fi

  ping -c 1 "${PGM_PGLISTENER:-${PGM_PGHOST}}" 2>&1 > /dev/null
  if [[ $? -ne 0 ]]; then
    local pgm_options="-o \"${pgm_options} --host=${PGM_PGHOST}\""
  fi

  ${PGM_PGBIN_DIR}/pg_ctl -w ${pgm_options} --pgdata=${PGM_PGDATA_DIR} --log=${PGM_PG_LOG} start
}

function startLocalInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2
  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}\n"
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl -w -o "-h ''" --pgdata=${PGM_PGDATA_DIR} --log=${PGM_PG_LOG} start
}

function stopInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2
  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}\n"
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA_DIR} --mode=fast stop
}

function reloadInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2
  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}\n"
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA_DIR} reload
}

function stateInstance()
{
  declareFunction "-server- -instance- -result-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2
  local pgm_result_var=$3

  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}\n"
    return 2
  fi

  local pgm_report="$(${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA_DIR} status)"

  local pgm_status=$?
  eval export ${pgm_result_var}='${pgm_report}'
  return ${pgm_status}
}


function promoteInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2
  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}\n"
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA_DIR} promote
}

function killInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2
  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}\n"
    return 2
  fi

  ${PGM_PGBIN_DIR}/pg_ctl --pgdata=${PGM_PGDATA_DIR} --mode=immediate stop
  if [[ $? -ne 0 ]]; then
    if [ -e ${PGM_PGDATA}/postmaster.pid ]; then
      local pgm_pgpid=$(head -1 ${PGM_PGDATA_DIR}/postmaster.pid)
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
  declareFunction "-server- ~instance~" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2
  
  setServer ${pgm_server}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set server ${pgm_server}:\n"
    return 2
  fi

  if [[ ${pgm_instance} =~ ${PGM_PGINSTANCE_AUTHORIZED_REGEXP} ]]; then
    # First set instance constants
    export PGM_PGINSTANCE=${pgm_instance}

    # Remove trailing slashes.
    for pgm_pattern in ${!PGMPG_PTRN_*}
    do
      eval local pgm_value=\$${pgm_pattern}
      eval export ${pgm_pattern/PGMPG_PTRN_/PGM_}=\"${pgm_value%/}\"
    done

    # Try to determine host, port, autolaunch configuration, and running configuration
    local pgm_line=$(egrep "^[[:space:]]*listen_addresses[[:space:]]*=" ${PGM_PG_CONF} 2>&1)
    if [[ $? -eq 0 ]]; then
      export PGM_PGLISTENER="$(echo ${pgm_line} | cut --delimiter='=' --fields=2)"
    fi
    export PGM_PGHOST=$(uname --nodename)
    export PGM_PGHOST="${PGM_PGHOST// /}"
    export PGM_PGLISTENER="${PGM_PGLISTENER// /}"
    export PGM_PGREALLISTENER="${PGM_PGLISTENER:-${PGM_PGHOST}}"

    local pgm_line=$(egrep "^[[:space:]]*port[[:space:]]*=" ${PGM_PG_CONF} 2>&1)
    if [[ $? -eq 0 ]]; then
      export PGM_PGPORT="$(echo ${pgm_line} | cut --delimiter='=' --fields=2)"
    else
      export PGM_PGPORT=${PGM_PGDEFAULTPORT}
    fi
    export PGM_PGPORT=${PGM_PGPORT// /}

    export PGM_PG_LOG=${PGM_PG_LOG_DIR}/${PGM_PG_LOG_NAME}

    local pgm_processes=$(ps -afe | egrep "-D[[:space:]][[:space:]]*${PGM_PGDATA_DIR}[[:space:]]" 2>&1)
    if [[ $? -eq 0 ]]; then
      export PGM_PGSTATUS="started"
      local pgm_hostline=$(echo ${pgm_processes} | egrep --only-matching "[[:space:]][[:space:]]*-(h|-host)[[:space:]][[:space:]]*[^[:space:]][^[:space:]]*[[:space:]]")
      if [[ $? -eq 0 ]]; then
        local pgm_hostline=${pgm_hostline/ -\(h|host\)[ =]/}
        export PGM_PGREALHOST=${pgm_hostline// /}
      fi
      local pgm_portline=$(echo ${pgm_processes} | egrep --only-matching "[[:space:]][[:space:]]*-(p|-port)[[:space:]][[:space:]]*[0-9][0-9]*[[:space:]]")
      if [[ $? -eq 0 ]]; then
        local pgm_portline=${pgm_portline/ -\(p|-port\)[ =]/}
        export PGM_PGREALPORT=${pgm_portline// /}
      fi
    else
      export PGM_PGSTATUS="stopped"
    fi

    getAutolaunchFromInstance ${PGM_PGFULL_VERSION} ${PGM_PGINSTANCE} PGM_PGAUTOLAUNCH
    return 0
  else
    printError "Wrong instance name \"${pgm_instance}\"\n"
    return 3
  fi
}

function checkAllInstances()
{
  declareFunction "-server- -result-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_report=""
  local pgm_status=0
  local pgm_server=$1
  local pgm_result_var=$2

  getInstances ${pgm_server} pgm_instance_list
  for pgm_instance in ${pgm_instance_list}
  do
    checkInstance ${pgm_server} ${pgm_instance} pgm_result
    local pgm_report="${pgm_report} ${pgm_result}"
    if [[ $? -ne 0 ]]; then
      local pgm_status=$(( pgm_status++ ))
    fi
  done

  eval ${pgm_result_var}='${pgm_report}'
  return ${pgm_status}
}

function checkInstance()
{
  declareFunction "-server- ~instance~ -result-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2
  local pgm_result_var=$3

  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    eval ${pgm_result_var}="Cannot set ${pgm_server} ${pgm_instance}"
    printError "Cannot set instance ${pgm_server} ${pgm_instance}:\n${pgm_report}\n"
    return 2
  else
    checkEnvironment pgm_report
    eval ${pgm_result_var}='${pgm_report}'
    return 0
  fi
}

function initInstance ()
{
  declareFunction "-server- +instance+" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2

  if [ "${PGM_PGDATA_DIR}x" == "x" ] || [ "${PGM_PGXLOG_DIR}x" == "x" ] || [ "${PGM_PGDATA_DIR}x" == "x" ]; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgm_server} ${pgm_instance}:\n${pgm_report}\n"
      return 1
    fi
  fi

  # Create cluster
  ${PGM_PGBIN_DIR}/initdb --pgdata=${PGM_PGDATA_DIR} --encoding=UTF8 --xlogdir=${PGM_PGXLOG_DIR} --data-checksums --no-locale
}

function logrotateInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2

  if [ "${PGM_LOGROTATE_CONF}x" == "x" ] || [ "${PGM_PG_LOG_DIR}x" == "x" ] || [ "${PGM_PGLOGROTATE_ENTRY}x" == "x" ]; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgm_server} ${pgm_instance}:\n${pgm_report}\n"
      return 2
    fi
  fi

  touch ${PGM_LOGROTATE_CONF} 
  egrep --quiet --only-matching "${PGM_PG_LOG_DIR}/\*.log" ${PGM_LOGROTATE_CONF}
  if [[ $? -ne 0 ]]; then
    printf "${PGM_PGLOGROTATE_ENTRY}" >> ${PGM_LOGROTATE_CONF}
    printTrace "Logrotate entry created"
  fi
}

function checkInstanceFS ()
{
  declareFunction "-server- -instance- -result-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2
  local pgm_result_var=$3
  local pgm_status=0
  local pgm_report=""

  if [ ! -v PGM_PGFSLIST ]; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      eval ${pgm_result_var}="Cannot set ${pgm_server} ${pgm_instance}"
      printError "Cannot set instance ${pgm_server} ${pgm_instance}:\n${pgm_report}\n"
      local pgm_status=1
    fi
  fi

  local pgm_mountlst="$(mount -l)"
  for pgm_fs in ${PGM_PGFSLIST}
  do
    echo "${pgm_mountlst}" | grep --quiet "${pgm_fs}"
    if [[ $? -ne 0 ]]; then
      local pgm_status=$(( pgm_status++ ))
      local pgm_report="${pgm_report} ${pgm_fs}"
    fi
  done

  eval ${pgm_result_var}='${pgm_report}'
  return ${pgm_status}
}


function createRecovery ()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2

  if [ "${PGM_PGRECOVER_CONF}x" == "x" ] || [ "${PGM_TEMPLATE_DIR}x" == "x" ] ; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgm_server} ${pgm_instance}:\n${pgm_report}\n"
      return 2
    fi
  fi
  local pgm_name=$(basename ${PGM_PGRECOVER_CONF})
  local pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  instantiateTemplate ${pgm_tpl} ${PGM_PGRECOVER_CONF}
  if [[ $? -ne 0 ]]; then
    printError "Cannot instanciate ${pgm_name} from ${pgm_tpl}\n"
    return 3
  else
    printTrace "Templete ${pgm_name} instanciated from ${pgm_tpl}\n"
    return 0
  fi
}


function createPgConf ()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2

  if [ "${PGM_PG_CONF}x" == "x" ] || [ "${PGM_TEMPLATE_DIR}x" == "x" ] ; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgm_server} ${pgm_instance}:\n${pgm_report}\n"
      return 2
    fi
  fi
  local pgm_name=$(basename ${PGM_PG_CONF})
  local pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  if [ "${pgm_tpl}x" == "x" ] || [ ! -r ${pgm_tpl} ]; then
    return 3
  fi
  instantiateTemplate ${pgm_tpl} ${PGM_PG_CONF}
  if [[ $? -ne 0 ]]; then
    printError "Cannot instanciate ${pgm_name} from ${pgm_tpl}\n"
    return 3
  else
    printTrace "Templete ${pgm_name} instanciated from ${pgm_tpl}\n"
    return 0
  fi
}


function createHBA ()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2

  if [ "${PGM_PGHBA_CONF}x" == "x" ] || [ "${PGM_TEMPLATE_DIR}x" == "x" ] ; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgm_server} ${pgm_instance}:\n${pgm_report}\n"
      return 2
    fi
  fi

  local pgm_name=$(basename ${PGM_PGHBA_CONF})
  local pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  if [ "${pgm_tpl}x" == "x" ] || [ ! -r ${pgm_tpl} ]; then
    return 3
  fi

  instantiateTemplate ${pgm_tpl} ${PGM_PGHBA_CONF}
  if [[ $? -ne 0 ]]; then
    printError "Cannot instanciate ${pgm_name} from ${pgm_tpl}\n"
    return 3
  else
    printTrace "Templete ${pgm_name} instanciated from ${pgm_tpl}\n"
    return 0
  fi
}

function createIdent ()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_server=$1 
  local pgm_instance=$2

  if [ "${PGM_PGIDENT_CONF}x" == "x" ] || [ "${PGM_TEMPLATE_DIR}x" == "x" ] ; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgm_server} ${pgm_instance}:\n${pgm_report}\n"
      return 2
    fi
  fi

  local pgm_name=$(basename ${PGM_PGIDENT_CONF})
  local pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  if [ "${pgm_tpl}x" == "x" ] || [ ! -r ${pgm_tpl} ]; then
    return 3
  fi

  instantiateTemplate ${pgm_tpl} ${PGM_PGIDENT_CONF}
  if [[ $? -ne 0 ]]; then
    printError "Cannot instanciate ${pgm_name} from ${pgm_tpl}\n"
    return 3
  else
    printTrace "Templete ${pgm_name} instanciated from ${pgm_tpl}\n"
    return 0
  fi
}

function provideInstanceDirectories()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2

  if [ ! -v PGM_PGDATA_DIR ] || [ ! -v PGM_PGXLOG_DIR ] || [ ! -v PGM_PG_LOG_DIR ] || [ ! -v PGM_PGARCHIVELOG_DIR ]; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgm_server} ${pgm_instance}:\n${pgm_report}\n"
      return 2
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
  declareFunction "-server- -instance- !port! !listener!" "$*"

  if [[ $# -ne 4 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2
  local pgm_port=$3
  local pgm_listener=$4

  printTrace "Creating filesystems for ${pgm_server} ${pgm_instance}"
  checkInstanceFS ${pgm_server} ${pgm_instance} pgm_result
  if [[ $? -ne 0 ]]; then
    printError "Error with filesystems : ${pgm_result}"
    return 2
  fi
  printTrace "Creating directories for ${pgm_server} ${pgm_instance}"
  provideInstanceDirectories ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error creating directories"
    return 3
  fi
  printTrace "Creating instance ${pgm_server} ${pgm_instance}"
  initInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error creating instance"
    return 4
  fi
  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}"
    return 9
  fi
  # Force port and listener that could be set previously
  # because of abscence from configuration file
  PGM_PGPORT=${pgm_port}
  PGM_PGLISTENER=${pgm_listener}
  printTrace "Creating configuration for ${pgm_server} ${pgm_instance}"
  createPgConf ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with configuration file"
    return 5
  fi
  printTrace "Creating recovery file for ${pgm_server} ${pgm_instance}"
  createRecovery ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with recovery file"
    return 6
  fi
  printTrace "Creating security file for ${pgm_server} ${pgm_instance}"
  createHBA ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with security file"
    return 7
  fi
  printTrace "Creating ident file for ${pgm_server} ${pgm_instance}"
  createIdent ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with ident file"
    return 8
  fi
  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}"
    return 9
  fi
  printTrace "Starting localy ${pgm_server} ${pgm_instance}"
  startLocalInstance  ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot start instance ${pgm_server} ${pgm_instance}"
    return 10
  fi
  printTrace "Configuring logrotate for ${pgm_server} ${pgm_instance}"
  logrotateInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with logrotate"
    return 12
  fi
}

