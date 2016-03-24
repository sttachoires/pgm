#! @BASH@
# 
# Bash library for PostgreSQL.
#
# S. Tachoires		10/11/2014	Initial version
#
#set -xv

# INCLUDE
if [ "${PGM_PGINVENTORY_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGM_PGINVENTORY_INCLUDE="LOADED"

. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGM_LIB_DIR}/pgm_util.include

function getAutolaunchFromInstance()
{
  declareFunction "-server- -instance- -result-" "$*"

  if [[ $# != 3 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2
  local pgm_result_var=$3

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgm_report=$(awk --field-separator=':' '/^_:'${pgm_instance}':'${pgm_server}':[yn]/ { print $4 }' ${PGM_PG_INVENTORY})
  eval ${pgm_result_var}='${pgm_report}'
}

function getDatabasesFromInstance()
{
  declareFunction "-server- -instance- -result-" "$*"

  if [[ $# != 3 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2
  local pgm_result_var=$3

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgm_report=$(awk --field-separator=':' '/^..+:'${pgm_instance}':'${pgm_server}':[yn]/ { print $1 }' ${PGM_PG_INVENTORY})
  eval ${pgm_result_var}='${pgm_report}'
}

function getServersFromInstance()
{
  declareFunction "-instance- -result-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgm_instance=$1
  local pgm_result_var=$2

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgm_report=$(awk --field-separator=':' '/^_:'${pgm_instance}':..+:[yn]/ { print $3 }' ${PGM_PG_INVENTORY})
  eval ${pgm_result_var}='${pgm_report}'
}

function getInstances()
{
  declareFunction "-result-" "$*"

  if [[ $# != 1 ]]; then
    return 1
  fi
  local pgm_result_var=$1

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgm_report=$(awk --field-separator=':' '/^_:..+:.*:[yn]/ { print $2 }' ${PGM_PG_INVENTORY})
  eval ${pgm_result_var}='${pgm_report}'
}

function isInstanceUnknownFromServer()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "^.*:${pgm_instance}:${pgm_server}:[yn]" ${PGM_PG_INVENTORY}
}

function getInstancesFromServer()
{
  declareFunction "-server- -result-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_result_var=$2

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgm_report=$(awk --field-separator=':' '/^_:..+:'${pgm_server}':[yn]/ { print $2 }' ${PGM_PG_INVENTORY})
  eval ${pgm_result_var}='${pgm_report}'
}

function getDatabasesFromServer()
{
  declareFunction "-server- -result-" "$*"

  if [[ $# != 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_result_var=$2

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  local pgm_report=$(awk --field-separator=':' '/^..+:.*:'${pgm_server}':[yn]/ { print $1 }' ${PGM_PG_INVENTORY})
  eval ${pgm_result_var}='${pgm_report}'
}

function getServers()
{
  declareFunction "-result-" "$*"

  if [[ $# != 1 ]]; then
    return 1
  fi
  local pgm_result_var=$1

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 1
  fi

  local pgm_report=$(awk --field-separator=':' '/^_:_:..+:[yn]/ { print $3 }' ${PGM_PG_INVENTORY})
  eval ${pgm_result_var}='${pgm_report}'
}

function isServerUnknown()
{
  declareFunction "-server-" "$*"

  if [[ $# != 1 ]]; then
    return 1
  fi
  local pgm_server=$1

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "^.*:.*:${pgm_server}:[yn]" ${PGM_PG_INVENTORY}
}

function addServer()
{
  declareFunction "+server+" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgm_server=$1

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGM_PG_INVENTORY}" ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  isServerUnknown ${pgm_server}
  if [[ $? -ne 0 ]]; then
    echo "_:_:${pgm_server}:y" >> ${PGM_PG_INVENTORY}
    return $?
  else
    return 0
  fi
}

function isServerAlone()
{
  declareFunction "-server-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgm_server=$1

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGM_PG_INVENTORY}" ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "^(.*:..+|..+:.*):${pgm_server}:[yn]" ${PGM_PG_INVENTORY}
}

function isInstanceAlone()
{
  declareFunction "-instance-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgm_instance=$1

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGM_PG_INVENTORY}" ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "^..+:${pgm_instance}:.*:[yn]" ${PGM_PG_INVENTORY}
}

function removeServer()
{
  declareFunction "-server-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgm_server=$1

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGM_PG_INVENTORY}" ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  isServerAlone ${pgm_server}
  if [[ $? -ne 0 ]]; then
    sed '/^.*:.*:'${pgm_server}':[yn].*$/ s/^/#/' ${PGM_PG_INVENTORY}
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
  local pgm_server=$1
  local pgm_instance=$2

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGM_PG_INVENTORY}" ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  isInstanceUnknownFromServer ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    echo "_:${pgm_instance}:${pgm_server}:y" >> ${PGM_PG_INVENTORY}
  fi
}

function removeInstance()
{
  declareFunction "-server- -instance-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2

  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -w "${PGM_PG_INVENTORY}" ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  isInstanceAlone ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    sed '/^.*:'${pgm_instance}':'${pgm_server}':[yn].*$/ s/^/#/' ${PGM_PG_INVENTORY}
    return $?
  else
    return 3
  fi
}

function isDatabaseUnknownFromInstance()
{
  declareFunction "-server- -instance- -database-" "$*"

  if [[ $# != 3 ]]; then
    return 1
  fi
  local pgm_server=$1
  local pgm_instance=$2
  local pgm_database=$3
  if [ "${PGM_PG_INVENTORY}x" == "x" ] || [ ! -r ${PGM_PG_INVENTORY} ]; then
    printError "Inventory '${PGM_PG_INVENTORY}' cannot be read"
    return 2
  fi

  egrep --quiet --only-matching "${pgm_database}:${pgm_instance}:${pgm_server}:[yn]" ${PGM_PG_INVENTORY}
}


