#! @BASH@
# 
# Bash library for PostgreSQL.
#
# S. Tachoires		10/11/2014	Initial version
#
#set -xv

# INCLUDE
if [[ "${PGM_PGINVENTORY_INCLUDE}" == "LOADED" ]]; then
  return 0
fi
. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi

function getAutolaunchFromInstance()
{
  if [[ $? != 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_instance=$2

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 2
  fi

  awk --field-separator=":" "/^_:${pgm_instance}:${pgm_version}:[yn]/ { print \$4 }" ${PGM_PG_INVENTORY}
}

function getDatabaseFromInstance()
{
  if [[ $? != 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_instance=$2

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 2
  fi

  awk --field-separator=':' "/^[^_]:${pgm_instance}:${pgm_version}:[yn]/ { print $1 }" ${PGM_PG_INVENTORY}
}

function getServersFromInstance()
{
  if [[ $? != 1 ]]; then
    return 1
  fi
  pgm_instance=$1

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 2
  fi

  awk --field-separator=':' "/^_:${pgm_instance}:[^_]+:[yn]/ { print $3 }" ${PGM_PG_INVENTORY}
}

function getInstances()
{
  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 1
  fi

  awk --field-separator=':' "/^_:[^_]+:[^_]+:[yn]/ { print $2 }" ${PGM_PG_INVENTORY}
}

function isInstanceUnknownFromServer()
{
  if [[ $? != 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_instance=$2
  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 2
  fi

  egrep --quiet --only-matching "^_:${pgm_instance}:${pgm_version}:[yn]" ${PGM_PG_INVENTORY}
}

function getInstancesFromServer()
{
  if [[ $? != 1 ]]; then
    return 1
  fi
  pgm_version=$1

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 2
  fi

  awk --field-separator=':' "/^_:[^_]+:${pgm_version}:[yn]/ { print $2 }" ${PGM_PG_INVENTORY}
}

function getDatabasesFromServer()
{
  if [[ $? != 1 ]]; then
    return 1
  fi
  pgm_version=$1

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 2
  fi

  awk --field-separator=':' "/^[^_]+:[^_]+:${pgm_version}:[yn]/ { print $1 }" ${PGM_PG_INVENTORY}
}

function getServers()
{
  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 1
  fi

  awk --field-separator=':' "/^_:_:[^_]+:[yn]/ { print $\3 }" ${PGM_PG_INVENTORY}
}

function isServerUnknown()
{
  if [[ $? != 1 ]]; then
    return 1
  fi
  pgm_version=$1

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 2
  fi

  egrep --quiet --only-matching "^_:_:${pgm_version}:[yn]" ${PGM_PG_INVENTORY}
}

function addServer()
{
  if [[ $# -ne 1 ]]; then
    return 1
  fi
  pgm_version=$1

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -w "${PGM_PG_INVENTORY}" ]]; then
    return 2
  fi

  isServerUnknown ${pgm_version}
  if [[ $? -ne 0 ]]; then
    echo "_:_:${pgm_version}:y" >> ${PGM_PG_INVENTORY}
  fi

}

function removeServer()
{
  if [[ $# -ne 1 ]]; then
    return 1
  fi
  pgm_version=$1

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -w "${PGM_PG_INVENTORY}" ]]; then
    return 2
  fi

  isServerUnknown ${pgm_version}
  if [[ $? -ne 0 ]]; then
    return 0
  fi
  pgm_db="$(getInstancesFromServer ${pgm_version})"
  if [[ $? -eq 0 ]]; then
    return 2
  else
    sed "/^_:_:${pgm_version}:[yn].*$/ s/^/#/" ${PGM_PG_INVENTORY}
  fi
}

function addInstance()
{
  if [[ $# -ne 2 ]]; then
    return 2
  fi
  pgm_version=$1
  pgm_instance=$2

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -w "${PGM_PG_INVENTORY}" ]]; then
    return 2
  fi

  isInstanceUnknownFromServer ${pgm_version} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    echo "_:_:${pgm_version}:y" >> ${PGM_PG_INVENTORY}
  fi

}

function removeInstance()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_instance=$2

  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -w "${PGM_PG_INVENTORY}" ]]; then
    return 2
  fi

  isInstanceUnknownFromServer ${pgm_version} ${pgm_instance}
  if [[ $? -ne 0 ]]; then
    return 0
  fi
  pgm_db="$(getDatabasesFromInstance ${pgm_version} ${pgm_instance})"
  if [[ $? -eq 0 ]]; then
    return 2
  else
    sed "'/^_:${pgm_instance}:${pgm_version}:[yn].*$/ s/^/#/'" ${PGM_PG_INVENTORY}
  fi
}

function isDatabaseUnknownFromInstance()
{
  if [[ $? != 3 ]]; then
    return 1
  fi
  pgm_version=$1
  pgm_instance=$2
  pgm_database=$3
  if [[ "${PGM_PG_INVENTORY}x" == "x" ]] || [[ ! -r ${PGM_PG_INVENTORY} ]]; then
    return 2
  fi

  egrep --quiet --only-matching \"${pgm_database}:${pgm_instance}:${pgm_version}:[yn]\" ${PGM_PG_INVENTORY}
}


# Nothing should happens after next line
export PGM_PGINVENTORY_INCLUDE="LOADED"
