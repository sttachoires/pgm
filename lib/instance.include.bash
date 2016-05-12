#! @BASH@
# 
# Bash library for PostgreSQL.
#
# S. Tachoires		10/11/2014	Initial version
#
#set -xv

# INCLUDE
if [ "${PGB_PG_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGB_PG_INCLUDE="LOADED"

. @CONFDIR@/pgbrewer.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGB_CONF_DIR}/instance.conf

. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/inventory.include
. ${PGB_LIB_DIR}/server.include
. ${PGB_LIB_DIR}/database.include

function startInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2

  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}\n"
    return 2
  fi

  ping -c 1 "${PGB_PGLISTENER:-${PGB_PGHOST}}" 2>&1 > /dev/null
  if [[ $? -ne 0 ]]; then
    local pgb_options="-o \"${pgb_options} --host=${PGB_PGHOST}\""
  fi

  ${PGB_PGBIN_DIR}/pg_ctl -w ${pgb_options} --pgdata=${PGB_PGDATA_DIR} --log=${PGB_PG_LOG} start
}

function startLocalInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2
  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}\n"
    return 2
  fi

  ${PGB_PGBIN_DIR}/pg_ctl -w -o "-h ''" --pgdata=${PGB_PGDATA_DIR} --log=${PGB_PG_LOG} start
}

function stopInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2
  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}\n"
    return 2
  fi

  ${PGB_PGBIN_DIR}/pg_ctl --pgdata=${PGB_PGDATA_DIR} --mode=fast stop
}

function reloadInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2
  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}\n"
    return 2
  fi

  ${PGB_PGBIN_DIR}/pg_ctl --pgdata=${PGB_PGDATA_DIR} reload
}

function stateInstance()
{
  declareFunction "-server- -instance- -result-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2
  local pgb_result_var=$3

  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}\n"
    return 2
  fi

  local pgb_report="$(${PGB_PGBIN_DIR}/pg_ctl --pgdata=${PGB_PGDATA_DIR} status)"

  local pgb_status=$?
  eval export ${pgb_result_var}='${pgb_report}'
  return ${pgb_status}
}


function promoteInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2
  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}\n"
    return 2
  fi

  ${PGB_PGBIN_DIR}/pg_ctl --pgdata=${PGB_PGDATA_DIR} promote
}

function killInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2
  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}\n"
    return 2
  fi

  ${PGB_PGBIN_DIR}/pg_ctl --pgdata=${PGB_PGDATA_DIR} --mode=immediate stop
  if [[ $? -ne 0 ]]; then
    if [ -e ${PGB_PGDATA}/postmaster.pid ]; then
      local pgb_pgpid=$(head -1 ${PGB_PGDATA_DIR}/postmaster.pid)
      if [[ $? -ne 0 ]]; then
        return 3
      else
        ${PGB_PGBIN_DIR}/pg_ctl TERM ${pgb_pgpid} kill
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

  local pgb_server=$1
  local pgb_instance=$2
  
  setServer ${pgb_server}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set server ${pgb_server}:\n"
    return 2
  fi

  if [[ ${pgb_instance} =~ ${PGB_PGINSTANCE_AUTHORIZED_REGEXP} ]]; then
    # First set instance constants
    export PGB_PGINSTANCE=${pgb_instance}

    # Remove trailing slashes.
    for pgb_pattern in ${!PGBPG_PTRN_*}
    do
      eval local pgb_value=\$${pgb_pattern}
      eval export ${pgb_pattern/PGBPG_PTRN_/PGB_}=\"${pgb_value%/}\"
    done

    # Try to determine host, port, autolaunch configuration, and running configuration
    local pgb_line=$(egrep "^[[:space:]]*listen_addresses[[:space:]]*=" ${PGB_PG_CONF} 2>&1)
    if [[ $? -eq 0 ]]; then
      export PGB_PGLISTENER="$(echo ${pgb_line} | cut --delimiter='=' --fields=2)"
    fi
    export PGB_PGHOST=$(uname --nodename)
    export PGB_PGHOST="${PGB_PGHOST// /}"
    export PGB_PGLISTENER="${PGB_PGLISTENER// /}"
    export PGB_PGREALLISTENER="${PGB_PGLISTENER:-${PGB_PGHOST}}"

    local pgb_line=$(egrep "^[[:space:]]*port[[:space:]]*=" ${PGB_PG_CONF} 2>&1)
    if [[ $? -eq 0 ]]; then
      export PGB_PGPORT="$(echo ${pgb_line} | cut --delimiter='=' --fields=2)"
    else
      export PGB_PGPORT=${PGB_PGDEFAULTPORT}
    fi
    export PGB_PGPORT=${PGB_PGPORT// /}

    export PGB_PG_LOG=${PGB_PG_LOG_DIR}/${PGB_PG_LOG_NAME}

    local pgb_processes=$(ps -afe | egrep "-D[[:space:]][[:space:]]*${PGB_PGDATA_DIR}[[:space:]]" 2>&1)
    if [[ $? -eq 0 ]]; then
      export PGB_PGSTATUS="started"
      local pgb_hostline=$(echo ${pgb_processes} | egrep --only-matching "[[:space:]][[:space:]]*-(h|-host)[[:space:]][[:space:]]*[^[:space:]][^[:space:]]*[[:space:]]")
      if [[ $? -eq 0 ]]; then
        local pgb_hostline=${pgb_hostline/ -\(h|host\)[ =]/}
        export PGB_PGREALHOST=${pgb_hostline// /}
      fi
      local pgb_portline=$(echo ${pgb_processes} | egrep --only-matching "[[:space:]][[:space:]]*-(p|-port)[[:space:]][[:space:]]*[0-9][0-9]*[[:space:]]")
      if [[ $? -eq 0 ]]; then
        local pgb_portline=${pgb_portline/ -\(p|-port\)[ =]/}
        export PGB_PGREALPORT=${pgb_portline// /}
      fi
    else
      export PGB_PGSTATUS="stopped"
    fi

    getAutolaunchFromInstance ${PGB_PGFULL_VERSION} ${PGB_PGINSTANCE} PGB_PGAUTOLAUNCH
    return 0
  else
    printError "Wrong instance name \"${pgb_instance}\"\n"
    return 3
  fi
}

function checkAllInstances()
{
  declareFunction "-server- -result-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_report=""
  local pgb_status=0
  local pgb_server=$1
  local pgb_result_var=$2

  getInstances ${pgb_server} pgb_instance_list
  for pgb_instance in ${pgb_instance_list}
  do
    checkInstance ${pgb_server} ${pgb_instance} pgb_result
    local pgb_report="${pgb_report} ${pgb_result}"
    if [[ $? -ne 0 ]]; then
      local pgb_status=$(( pgb_status++ ))
    fi
  done

  eval ${pgb_result_var}='${pgb_report}'
  return ${pgb_status}
}

function checkInstance()
{
  declareFunction "-server- ~instance~ -result-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2
  local pgb_result_var=$3

  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    eval ${pgb_result_var}="Cannot set ${pgb_server} ${pgb_instance}"
    printError "Cannot set instance ${pgb_server} ${pgb_instance}:\n${pgb_report}\n"
    return 2
  else
    checkEnvironment pgb_report
    eval ${pgb_result_var}='${pgb_report}'
    return 0
  fi
}

function initInstance ()
{
  declareFunction "-server- +instance+" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_PGDATA_DIR}x" == "x" ] || [ "${PGB_PGXLOG_DIR}x" == "x" ] || [ "${PGB_PGDATA_DIR}x" == "x" ]; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgb_server} ${pgb_instance}:\n${pgb_report}\n"
      return 1
    fi
  fi

  # Create cluster
  ${PGB_PGBIN_DIR}/initdb --pgdata=${PGB_PGDATA_DIR} --encoding=UTF8 --xlogdir=${PGB_PGXLOG_DIR} --data-checksums --no-locale
}

function logrotateInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_LOGROTATE_CONF}x" == "x" ] || [ "${PGB_PG_LOG_DIR}x" == "x" ] || [ "${PGB_PGLOGROTATE_ENTRY}x" == "x" ]; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgb_server} ${pgb_instance}:\n${pgb_report}\n"
      return 2
    fi
  fi

  touch ${PGB_LOGROTATE_CONF} 
  egrep --quiet --only-matching "${PGB_PG_LOG_DIR}/\*.log" ${PGB_LOGROTATE_CONF}
  if [[ $? -ne 0 ]]; then
    printf "${PGB_PGLOGROTATE_ENTRY}" >> ${PGB_LOGROTATE_CONF}
    printTrace "Logrotate entry created"
  fi
}

function checkInstanceFS ()
{
  declareFunction "-server- -instance- -result-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2
  local pgb_result_var=$3
  local pgb_status=0
  local pgb_report=""

  if [ ! -v PGB_PGFSLIST ]; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      eval ${pgb_result_var}="Cannot set ${pgb_server} ${pgb_instance}"
      printError "Cannot set instance ${pgb_server} ${pgb_instance}:\n${pgb_report}\n"
      local pgb_status=1
    fi
  fi

  local pgb_mountlst="$(mount -l)"
  for pgb_fs in ${PGB_PGFSLIST}
  do
    echo "${pgb_mountlst}" | grep --quiet "${pgb_fs}"
    if [[ $? -ne 0 ]]; then
      local pgb_status=$(( pgb_status++ ))
      local pgb_report="${pgb_report} ${pgb_fs}"
    fi
  done

  eval ${pgb_result_var}='${pgb_report}'
  return ${pgb_status}
}


function createRecovery ()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_PGRECOVER_CONF}x" == "x" ] || [ "${PGB_TEMPLATE_DIR}x" == "x" ] ; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgb_server} ${pgb_instance}:\n${pgb_report}\n"
      return 2
    fi
  fi
  local pgb_name=$(basename ${PGB_PGRECOVER_CONF})
  local pgb_tpl=${PGB_TEMPLATE_DIR}/${pgb_name}.tpl
  instantiateTemplate ${pgb_tpl} ${PGB_PGRECOVER_CONF}
  if [[ $? -ne 0 ]]; then
    printError "Cannot instanciate ${pgb_name} from ${pgb_tpl}\n"
    return 3
  else
    printTrace "Templete ${pgb_name} instanciated from ${pgb_tpl}\n"
    return 0
  fi
}


function createPgConf ()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_PG_CONF}x" == "x" ] || [ "${PGB_TEMPLATE_DIR}x" == "x" ] ; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgb_server} ${pgb_instance}:\n${pgb_report}\n"
      return 2
    fi
  fi
  local pgb_name=$(basename ${PGB_PG_CONF})
  local pgb_tpl=${PGB_TEMPLATE_DIR}/${pgb_name}.tpl
  if [ "${pgb_tpl}x" == "x" ] || [ ! -r ${pgb_tpl} ]; then
    return 3
  fi
  instantiateTemplate ${pgb_tpl} ${PGB_PG_CONF}
  if [[ $? -ne 0 ]]; then
    printError "Cannot instanciate ${pgb_name} from ${pgb_tpl}\n"
    return 3
  else
    printTrace "Templete ${pgb_name} instanciated from ${pgb_tpl}\n"
    return 0
  fi
}


function createHBA ()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_PGHBA_CONF}x" == "x" ] || [ "${PGB_TEMPLATE_DIR}x" == "x" ] ; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgb_server} ${pgb_instance}:\n${pgb_report}\n"
      return 2
    fi
  fi

  local pgb_name=$(basename ${PGB_PGHBA_CONF})
  local pgb_tpl=${PGB_TEMPLATE_DIR}/${pgb_name}.tpl
  if [ "${pgb_tpl}x" == "x" ] || [ ! -r ${pgb_tpl} ]; then
    return 3
  fi

  instantiateTemplate ${pgb_tpl} ${PGB_PGHBA_CONF}
  if [[ $? -ne 0 ]]; then
    printError "Cannot instanciate ${pgb_name} from ${pgb_tpl}\n"
    return 3
  else
    printTrace "Templete ${pgb_name} instanciated from ${pgb_tpl}\n"
    return 0
  fi
}

function createIdent ()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_server=$1 
  local pgb_instance=$2

  if [ "${PGB_PGIDENT_CONF}x" == "x" ] || [ "${PGB_TEMPLATE_DIR}x" == "x" ] ; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgb_server} ${pgb_instance}:\n${pgb_report}\n"
      return 2
    fi
  fi

  local pgb_name=$(basename ${PGB_PGIDENT_CONF})
  local pgb_tpl=${PGB_TEMPLATE_DIR}/${pgb_name}.tpl
  if [ "${pgb_tpl}x" == "x" ] || [ ! -r ${pgb_tpl} ]; then
    return 3
  fi

  instantiateTemplate ${pgb_tpl} ${PGB_PGIDENT_CONF}
  if [[ $? -ne 0 ]]; then
    printError "Cannot instanciate ${pgb_name} from ${pgb_tpl}\n"
    return 3
  else
    printTrace "Templete ${pgb_name} instanciated from ${pgb_tpl}\n"
    return 0
  fi
}

function provideInstanceDirectories()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2

  if [ ! -v PGB_PGDATA_DIR ] || [ ! -v PGB_PGXLOG_DIR ] || [ ! -v PGB_PG_LOG_DIR ] || [ ! -v PGB_PGARCHIVELOG_DIR ]; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgb_server} ${pgb_instance}:\n${pgb_report}\n"
      return 2
    fi
  fi

  mkdir -p ${PGB_PGDATA_DIR} 
  chmod u=rwx,go= ${PGB_PGDATA_DIR} 
  mkdir -p ${PGB_PGXLOG_DIR} 
  mkdir -p ${PGB_PG_LOG_DIR} 
  mkdir -p ${PGB_PGARCHIVELOG_DIR} 
}

function createInstance()
{
  declareFunction "-server- -instance- !port! !listener!" "$*"

  if [[ $# -ne 4 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2
  local pgb_port=$3
  local pgb_listener=$4

  printTrace "Creating filesystems for ${pgb_server} ${pgb_instance}"
  checkInstanceFS ${pgb_server} ${pgb_instance} pgb_result
  if [[ $? -ne 0 ]]; then
    printError "Error with filesystems : ${pgb_result}"
    return 2
  fi
  printTrace "Creating directories for ${pgb_server} ${pgb_instance}"
  provideInstanceDirectories ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error creating directories"
    return 3
  fi
  printTrace "Creating instance ${pgb_server} ${pgb_instance}"
  initInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error creating instance"
    return 4
  fi
  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}"
    return 9
  fi
  # Force port and listener that could be set previously
  # because of abscence from configuration file
  PGB_PGPORT=${pgb_port}
  PGB_PGLISTENER=${pgb_listener}
  printTrace "Creating configuration for ${pgb_server} ${pgb_instance}"
  createPgConf ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with configuration file"
    return 5
  fi
  printTrace "Creating recovery file for ${pgb_server} ${pgb_instance}"
  createRecovery ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with recovery file"
    return 6
  fi
  printTrace "Creating security file for ${pgb_server} ${pgb_instance}"
  createHBA ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with security file"
    return 7
  fi
  printTrace "Creating ident file for ${pgb_server} ${pgb_instance}"
  createIdent ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with ident file"
    return 8
  fi
  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}"
    return 9
  fi
  printTrace "Starting localy ${pgb_server} ${pgb_instance}"
  startLocalInstance  ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot start instance ${pgb_server} ${pgb_instance}"
    return 10
  fi
  printTrace "Configuring logrotate for ${pgb_server} ${pgb_instance}"
  logrotateInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Error with logrotate"
    return 12
  fi
}

