#! @BASH@
# 
# Bash library for PostgreSQL.
#
# S. Tachoires		10/11/2014	Initial version
#
#set -xv

# INCLUDE
if [ "${PGM_DB_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGM_DB_INCLUDE="LOADED"
. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGM_CONF_DIR}/database.conf
. ${PGM_LIB_DIR}/util.include
. ${PGM_LIB_DIR}/inventory.include
. ${PGM_LIB_DIR}/instance.include

function setDatabase()
{
  declareFunction "-server- -instance- -database-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  else
    local pgm_server=$1
    local pgm_instance=$2
    local pgm_database=$3  
  fi

  setInstance ${pgm_server} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set instance ${pgm_server} ${pgm_instance}\n"
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
    printError "Wrong database name ${pgm_database}\n"
    return 1
  fi
}

function databaseExec()
{
  declareFunction "-server- -instance- -database- -request- -result-" "$*"

  if [[ $# -ne 5 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2
  local pgm_database=$3
  local pgm_request=$4
  local pgm_result_var=$5

  if [ "${PGM_PGBIN_DIR}x" == "x" ] || [ "${PGM_PGDATA_DIR}x" == "x" ] || [ "${PGM_PORT}x" == "x" ]; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgm_server} ${pgm_instance}\n" 
      return 2
    fi
  fi

  local pgm_request_result=$(${PGM_PGBIN_DIR}/psql --host=${PGM_PGDATA_DIR} --port=${PGM_PGPORT} --tuples-only -v ON_ERROR_STOP=1 ${dbname} -c "${pgm_request}")
  local pgm_status=$?

  eval export ${pgm_result_var}='${pgm_request_result}'
  return ${pgm_status}
}

function createExtentions()
{
  declareFunction "-server- -instance- -database-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  fi

  local pgm_server=$1
  local pgm_instance=$2
  local pgm_database=$3

  if [ ! -v PGM_PGEXTENSIONS_TO_CREATE ]; then
    setInstance ${pgm_server} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set instance ${pgm_server} ${pgm_instance}\n"
      return 2
    fi
  fi

  local pgm_status=0
  for pgm_extention in ${PGM_PGEXTENSIONS_TO_CREATE//,/}
  do
    databaseExec ${pgm_server} ${pgm_instance} ${pgm_database} "CREATE EXTENSION ${pgm_extention};" pgm_result
    if [[ $? -ne 0 ]]; then
      local pgm_status=$(( pgm_status++ ))
    fi
  done

  return ${pgm_status}
}

