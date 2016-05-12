#! @BASH@

# Differents constants to fit pgbrewer scripts

# 19.02.2016	S. Tachoires	Initiate
#set -xv

if [ "${PGB_SERVER_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGB_SERVER_INCLUDE="LOADED"

. @CONFDIR@/pgbrewer.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGB_CONF_DIR}/pgserver.conf
. ${PGB_LIB_DIR}/util.include

function getRemovedServers()
{
  declareFunction "+config+ -result-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_config=$1
  local pgb_result_var=$2
  local pgb_report=""

  if [ "${pgb_config}x" == "defaultx" ]; then
    pgb_conf_dir=${PGB_CONF_DIR}/pgserver
  else
     pgb_conf_dir=${PGB_CONF_DIR}/${pgb_config}/pgserver
  fi

  for pgb_server_dir in ${pgb_conf_dir}/\.??*
  do
    if [ "${pgb_server_dir%/}x" != "x" ] && [ -d ${pgb_server_dir%/} ]; then
      pgb_tempo=$(basename ${pgb_server_dir%/})
      pgb_report="${pgb_report} ${pgb_tempo#.}"
    fi
  done

  eval ${pgb_result_var}='${pgb_report## }'
}

function getServers()
{
  declareFunction "+config+ -result-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_config=$1
  local pgb_result_var=$2
  local pgb_report=""

  if [ "${pgb_config}x" == "defaultx" ]; then
    pgb_conf_dir=${PGB_CONF_DIR}
  else
     pgb_conf_dir=${PGB_CONF_DIR}/${pgb_config}
  fi

  for pgb_server_dir in ${pgb_conf_dir}/pgserver/*
  do
    if [ "${pgb_server_dir%/}x" != "x" ] && [ -d ${pgb_server_dir%/} ]; then
      pgb_report="${pgb_report} $(basename ${pgb_server_dir%/})"
    fi
  done

  eval ${pgb_result_var}='${pgb_report## }'
}

function setServer()
{
  declareFunction "~server~" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  export PGB_PGFULL_VERSION=$1
  if [[ "${PGB_PGFULL_VERSION}" =~ ^${PGB_PGREAL_VERSION_REGEXP}(${PGB_PGVERSION_AUTHORIZED_REGEXP})*$ ]]; then
    # First set versions constants
    export PGB_PGREAL_VERSION=$(echo "${PGB_PGFULL_VERSION}" | egrep --only-matching "^${PGB_PGREAL_VERSION_REGEXP}")
    export PGB_PGMAJOR_VERSION=${PGB_PGREAL_VERSION%.*}

    # Remove trailing slashes.
    for pgb_pattern in ${!PGBSRV_PTRN_*}
    do
      eval pgb_value=\$${pgb_pattern}
      eval export ${pgb_pattern/#PGBSRV_PTRN_/PGB_}=\"${pgb_value%/}\"
    done
    
    return 0
  else
    printError "The name '${PGB_PGFULL_VERSION}' doesn't match '^${PGB_PGREAL_VERSION_REGEXP}(${PGB_PGVERSION_AUTHORIZED_REGEXP})*$'"
    return 2
  fi
}

function serverInfo()
{
  declareFunction "-server- -result-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  
  local pgb_server=$1
  local pgb_result_var=$2

  setServer ${pgb_server}
  if [[ $? -ne 0 ]]; then
    return 2
  fi
  
  if [ -x ${PGB_PGBIN_DIR}/pg_config ]; then
    local pgb_report="$(${PGB_PGBIN_DIR}/pg_config)"
  else
    printError "no valid pg_config in '${PGB_PGBIN_DIR}'\n"
    return 3
  fi

  eval ${pgb_result_var}='${pgb_report}'
}

function checkAllServers()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgb_result_var=$1
  local pgb_report=""
  local pgb_status=0

  getServers pgb_server_list
  for pgb_server in ${pgb_server_list}
  do
    checkServer ${pgb_server} pgb_check_result
    local pgb_report="${pgb_report} ${pgb_check_result}"
    if [[ $? -ne 0 ]]; then
      local pgb_status=$(( ${pgb_status} + 1 ))
    fi
  done

  eval ${pgb_result_var}='${pgb_report//[ ][ ]+/ }'
  return ${pgb_status}
}

function checkServer()
{
  declareFunction "-server- -result-" "$*"
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  
  local pgb_server=$1
  local pgb_result_var=$2
  
  local pgb_status=0

  setServer ${pgb_server}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set server ${pgb_server}"
    return 2
  fi

  checkEnvironment pgb_report
}

function installServer()
{
  declareFunction "-directory- -server-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_src_dir=$1
  local pgb_server=$2

  if [ ! -v PGB_PGHOME_DIR ] || [ ! -v PGB_PGBIN_DIR ] || [ ! -v PGB_PGLIB_DIR ] || [ ! -v PGB_PGINCLUDE_DIR ] || [ ! -v PGB_PGSHARE_DIR ] || [ ! -v PGB_PGBrewer.N_DIR ] || [ ! -v PGB_PGDOC_DIR ]; then
    setServer ${pgb_server}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set server ${pgb_server}"
      return 2
    fi
  fi

  cd ${pgb_src_dir}
  ./configure --prefix=${PGB_PGHOME_DIR} --exec-prefix=$(dirname ${PGB_PGBIN_DIR}) --bindir=${PGB_PGBIN_DIR} --libdir=${PGB_PGLIB_DIR} --includedir=${PGB_PGINCLUDE_DIR} --datarootdir=${PGB_PGSHARE_DIR} --mandir=${PGB_PGBrewer.N_DIR} --docdir=${PGB_PGDOC_DIR} --with-openssl --with-perl --with-python --with-ldap 
  if [[ $? -ne 0 ]]; then
    return 3
  fi

  make world 
  if [[ $? -ne 0 ]]; then
    return 4
  fi

  make check 
  if [[ $? -ne 0 ]]; then
    return 5
  fi

  make install-world 
  if [[ $? -ne 0 ]]; then
    return 6
  fi

  make distclean 
  if [[ $? -ne 0 ]]; then
    return 7
  fi
  addServer ${pgb_server}
}
