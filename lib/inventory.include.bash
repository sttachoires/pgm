#! @BASH@
# 
# Bash library for PostgreSQL.
#
# S. Tachoires		10/11/2014	Initial version
#
#set -xv

# INCLUDE
if [ "${PGB_PGINVENTORY_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGB_PGINVENTORY_INCLUDE="LOADED"

. @CONFDIR@/pgbrewer.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGB_LIB_DIR}/util.include


function ensurePgInventory()
{
  declareFunction "" "$*"

  mkdir -p $(dirname ${PGB_PG_INVENTORY})
  if [[ $? -ne 0 ]]; then
    printError "cannot create $(dirname ${PGB_PG_INVENTORY})"
    return 1
  fi
  if [ ! -e ${PGB_PG_INVENTORY} ]; then
    echo "#server:instance:database:state:managed" > ${PGB_PG_INVENTORY}
    if [[ $? -ne 0 ]]; then
      printError "cannot create ${PGB_PG_INVENTORY}"
    else
      printTrace "${PGB_PG_INVENTORY} created"
    fi
  fi
}

function getDatabasesFromInstance()
{
  declareFunction "-server- -instance- -result-" "$*"

  if [[ $# != 3 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2
  local pgb_result_var=$3

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgb_report=$(awk --field-separator=':' '/^..+:'${pgb_instance}':'${pgb_server}':[yn]/ { print $1 }' ${PGB_PG_INVENTORY})
  eval ${pgb_result_var}='${pgb_report}'
}

function getDatabasesFromServer()
{
  declareFunction "-server- -result-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_result_var=$2

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgb_report=$(awk --field-separator=':' '/^..+:.*:'${pgb_server}':[yn]/ { print $1 }' ${PGB_PG_INVENTORY})
  eval ${pgb_result_var}='${pgb_report}'
}

function isDatabaseUnknownFromInstance()
{
  declareFunction "-server- -instance- -database-" "$*"

  if [[ $# != 3 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2
  local pgb_database=$3
  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "${pgb_database}:${pgb_instance}:${pgb_server}:[yn]" ${PGB_PG_INVENTORY}
}

function isDatabaseUnknownFromServer()
{
  declareFunction "-server- -database-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_database=$2
  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "${pgb_database}:${pgb_instance}:${pgb_server}:[yn]" ${PGB_PG_INVENTORY}
}

function isInstanceAutolaunch()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_AUTOLAUNCH_INVENTORY}x" == "x" ] || [ ! -r ${PGB_AUTOLAUNCH_INVENTORY} ]; then
    printError "Inventory '${PGB_AUTOLAUNCH_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet "^${pgb_server}:${pgb_instance}" ${PGB_AUTOLAUNCH_INVENTORY}
}

function setInstanceAutolaunch()
{
  declareFunction "-server- -instance-" "$*"

    if [[ $# != 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_AUTOLAUNCH_INVENTORY}x" == "x" ] || [ ! -r ${PGB_AUTOLAUNCH_INVENTORY} ]; then
    printError "Inventory '${PGB_AUTOLAUNCH_INVENTORY}' cannot be read"
    return 2
  fi

  isInstanceAutolaunch ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    echo "${pgb_server}:${pgb_instance}" >> ${PGB_AUTOLAUNCH_INVENTORY}
  fi
}

function unsetInstanceAutolaunch()
{
    declareFunction "-server- -instance-" "$*"

    if [[ $# != 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_AUTOLAUNCH_INVENTORY}x" == "x" ] || [ ! -r ${PGB_AUTOLAUNCH_INVENTORY} ]; then
    printError "Inventory '${PGB_AUTOLAUNCH_INVENTORY}' cannot be read"
    return 2
  fi

  isInstanceAutolaunch ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    sed --in-place '/^'${pgb_server}':'${pgb_instance}'.*$/ s/^/#/' ${PGB_AUTOLAUNCH_INVENTORY}
    return $?
  else
    return 3
  fi
}

function addInstance()
{
  declareFunction "-server- +instance+" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGB_PG_INVENTORY}" ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  isInstanceUnknownFromServer ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    echo "_:${pgb_instance}:${pgb_server}:y" >> ${PGB_PG_INVENTORY}
  fi
}

function removeInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGB_PG_INVENTORY}" ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  isInstanceAlone ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    sed '/^.*:'${pgb_instance}':'${pgb_server}':[yn].*$/ s/^/#/' ${PGB_PG_INVENTORY}
    return $?
  else
    return 3
  fi
}

function getInstances()
{
  declareFunction "-result-" "$*"

  if [[ $# != 1 ]]; then
    return 1
  fi
  local pgb_result_var=$1

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgb_report=$(awk --field-separator=':' '/^_:..+:.*:[yn]/ { print $2 }' ${PGB_PG_INVENTORY})
  eval ${pgb_result_var}='${pgb_report}'
}

function isInstanceAlone()
{
  declareFunction "-instance-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgb_instance=$1

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGB_PG_INVENTORY}" ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "^..+:${pgb_instance}:.*:[yn]" ${PGB_PG_INVENTORY}
}

function isInstanceUnknownFromServer()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_instance=$2

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "^.*:${pgb_instance}:${pgb_server}:[yn]" ${PGB_PG_INVENTORY}
}

function getInstancesFromServer()
{
  declareFunction "-server- -result-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgb_server=$1
  local pgb_result_var=$2

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgb_report=$(awk --field-separator=':' '/^_:..+:'${pgb_server}':[yn]/ { print $2 }' ${PGB_PG_INVENTORY})
  eval ${pgb_result_var}='${pgb_report}'
}

function addServer()
{
  declareFunction "+server+" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgb_server=$1

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGB_PG_INVENTORY}" ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  isServerUnknown ${pgb_server}
  if [[ $? -ne 0 ]]; then
    echo "_:_:${pgb_server}:y" >> ${PGB_PG_INVENTORY}
    return $?
  else
    return 0
  fi
}

function removeServer()
{
  declareFunction "-server-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgb_server=$1

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGB_PG_INVENTORY}" ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  isServerAlone ${pgb_server}
  if [[ $? -ne 0 ]]; then
    sed '/^.*:.*:'${pgb_server}':[yn].*$/ s/^/#/' ${PGB_PG_INVENTORY}
    return $?
  else
    return 3
  fi
}

function getServers()
{
  declareFunction "-result-" "$*"

  if [[ $# != 1 ]]; then
    return 1
  fi
  local pgb_result_var=$1

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 1
  fi

  local pgb_report=$(awk --field-separator=':' '/^_:_:..+:[yn]/ { print $3 }' ${PGB_PG_INVENTORY})
  eval ${pgb_result_var}='${pgb_report}'
}

function getServersFromInstance()
{
  declareFunction "-instance- -result-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgb_instance=$1
  local pgb_result_var=$2

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgb_report=$(awk --field-separator=':' '/^_:'${pgb_instance}':..+:[yn]/ { print $3 }' ${PGB_PG_INVENTORY})
  eval ${pgb_result_var}='${pgb_report}'
}

function isServerUnknown()
{
  declareFunction "-server-" "$*"

  if [[ $# != 1 ]]; then
    return 1
  fi
  local pgb_server=$1

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGB_PG_INVENTORY} ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "^.*:.*:${pgb_server}:[yn]" ${PGB_PG_INVENTORY}
}

function isServerAlone()
{
  declareFunction "-server-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgb_server=$1

  if [ "${PGB_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGB_PG_INVENTORY}" ]; then
    printError "Inventory '${PGB_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "^(.*:..+|..+:.*):${pgb_server}:[yn]" ${PGB_PG_INVENTORY}
}


