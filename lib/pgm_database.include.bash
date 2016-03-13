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
. ${PGM_LIB_DIR}/pgm_util.include
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_instance.include

function setDatabase()
{
  if [[ $# -ne 3 ]]; then
    return 1
  else
    pgm_version=$1
    pgm_instance=$2
    pgm_database=$3  
  fi


  pgm_report=$(setInstance ${pgm_version} ${pgm_instance})
  if [[ $? -ne 0 ]]; then
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

function databaseExec()
{
  if [[ $# -ne 3 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2
  pgm_database=$3

  if [ "${PGM_PGBIN_DIR}x" == "x" ] || [ "${PGM_PGDATA_DIR}x" == "x" ] || [ "${PGM_PORT}x" == "x" ]; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  fi

  ${PGM_PGBIN_DIR}/psql --host=${PGM_PGDATA_DIR} --port=${PGM_PGPORT} --tuples-only -v ON_ERROR_STOP=1 ${dbname} -c "${request}"
}

function createExtentions()
{
  if [[ $# -ne 3 ]]; then
    return 1
  fi

  pgm_version=$1
  pgm_instance=$2
  pgm_database=$3

  if [ ! -v PGM_PGEXTENSIONS_TO_CREATE ]; then
    setInstance ${pgm_version} ${pgm_instance}
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  fi

  pgm_result=0
  for pgm_extention in ${PGM_PGEXTENSIONS_TO_CREATE//,/}
  do
    databaseExec ${pgm_version} ${pgm_instance} ${pgm_database} "CREATE EXTENSION ${pgm_extention};"
    if [[ $? -ne 0 ]]; then
      pgm_result=$(( pgm_result++ ))
    fi
  done

  return ${result}
}

