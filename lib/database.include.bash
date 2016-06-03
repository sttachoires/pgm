#! @BASH@
# 
# Bash library for PostgreSQL.
#
# S. Tachoires		10/11/2014	Initial version
#
#set -xv

# INCLUDE
if [ "${PGB_DB_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGB_DB_INCLUDE="LOADED"
. @CONFDIR@/pgbrewer.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGB_CONF_DIR}/database.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/inventory.include
. ${PGB_LIB_DIR}/instance.include

declare -xf setDatabase
function setDatabase()
{
  declareFunction "-server- -instance- -database-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  else
    local pgb_server=$1
    local pgb_instance=$2
    local pgb_database=$3  
  fi

  setInstance ${pgb_server} ${pgb_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgb_server} ${pgb_instance}\n"
    return 2
  fi

  if [[ "${pgb_database}" =~ ${PGB_PGDATABASE_AUTHORIZED_REGEXP} ]]; then
    # First set versions constants
    export PGB_PGDATABASE="${pgb_database}"

    # Remove trailing slashes.
    for pgb_pattern in ${!PGBrewer.BPATTERN_*}
    do
      eval pgb_value=\$${pgb_pattern}
      eval export ${pgb_pattern/PGBrewer.BPATTERN_/PGB_}=\"${pgb_value%/}\"
    done

    return 0
  else
    printError "Wrong database name ${pgb_database}\n"
    return 1
  fi
}

declare -xf databaseExec
function databaseExec()
{
  declareFunction "-server- -instance- -database- -request- -result-" "$*"

  if [[ $# -ne 5 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2
  local pgb_database=$3
  local pgb_request=$4
  local pgb_result_var=$5

  if [ "${PGB_PGBIN_DIR}x" == "x" ] || [ "${PGB_PGDATA_DIR}x" == "x" ] || [ "${PGB_PORT}x" == "x" ]; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgb_server} ${pgb_instance}\n" 
      return 2
    fi
  fi

  local pgb_request_result=$(${PGB_PGBIN_DIR}/psql --host=${PGB_PGDATA_DIR} --port=${PGB_PGPORT} --tuples-only -v ON_ERROR_STOP=1 ${dbname} -c "${pgb_request}")
  local pgb_status=$?

  eval export ${pgb_result_var}='${pgb_request_result}'
  return ${pgb_status}
}

declare -xf createExtentions
function createExtentions()
{
  declareFunction "-server- -instance- -database-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  fi

  local pgb_server=$1
  local pgb_instance=$2
  local pgb_database=$3

  if [ ! -v PGB_PGEXTENSIONS_TO_CREATE ]; then
    setInstance ${pgb_server} ${pgb_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgb_server} ${pgb_instance}\n"
      return 2
    fi
  fi

  local pgb_status=0
  for pgb_extention in ${PGB_PGEXTENSIONS_TO_CREATE//,/}
  do
    databaseExec ${pgb_server} ${pgb_instance} ${pgb_database} "CREATE EXTENSION ${pgb_extention};" pgb_result
    if [[ $? -ne 0 ]]; then
      local pgb_status=$(( pgb_status++ ))
    fi
  done

  return ${pgb_status}
}

