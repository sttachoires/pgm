#! @BASH@
# 
# Bash library for PostgreSQL.
#
# S. Tachoires		10/11/2014	Initial version
#
#set -xv

# INCLUDE
if [[ "${PGM_DB_INCLUDE}" == "LOADED" ]]; then
  return 0
fi
. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGM_LIB_DIR}/pgm_server.include
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGM_LIB_DIR}/pgm_util.include
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGM_LIB_DIR}/pgm_pg.include
if [[ $? -ne 0 ]]; then
  exit 1
fi

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

function databaseList()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_report=$(setInstance $1 $2)
  if [[ $? -ne 0 ]]; then
    return 2
  fi
  checkEnvironment
  if [[ $? -ne 0 ]]; then
    return 3
  fi
  printf "$(egrep --only-matching ".*:${PGM_PGINSTANCE}:${PGM_PGFULL_VERSION}:" ${PGM_PG_TAB} | cut --delimiter ':' --fields 3)"
}

# Nothing should happens after next line
export PGM_DB_INCLUDE="LOADED"
