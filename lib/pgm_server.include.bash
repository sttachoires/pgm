#! @BASH@

# Differents constants to fit pgm scripts

# 19.02.2016	S. Tachoires	Initiate
#set -xv

if [ "${PGM_SERVER_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGM_SERVER_INCLUDE="LOADED"

. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGM_CONF_DIR}/server.conf
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_util.include

function setServer()
{
  declareFunction "~server~" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  export PGM_PGFULL_VERSION=$1
  if [[ "${PGM_PGFULL_VERSION}" =~ ^${PGM_PGREAL_VERSION_REGEXP}(${PGM_PGVERSION_AUTHORIZED_REGEXP})*$ ]]; then
    # First set versions constants
    export PGM_PGREAL_VERSION=$(echo "${PGM_PGFULL_VERSION}" | egrep --only-matching "^${PGM_PGREAL_VERSION_REGEXP}")
    export PGM_PGMAJOR_VERSION=${PGM_PGREAL_VERSION%.*}

    # Remove trailing slashes.
    for pgm_pattern in ${!PGMSRV_PTRN_*}
    do
      eval pgm_value=\$${pgm_pattern}
      eval export ${pgm_pattern/#PGMSRV_PTRN_/PGM_}=\"${pgm_value%/}\"
    done
    
    return 0
  else
    printError "The name '${PGM_PGFULL_VERSION}' doesn't match '^${PGM_PGREAL_VERSION_REGEXP}(${PGM_PGVERSION_AUTHORIZED_REGEXP})*$'"
    return 2
  fi
}

function serverInfo()
{
  declareFunction "-server- -result-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  
  local pgm_server=$1
  local pgm_result_var=$2

  setServer ${pgm_server}
  if [[ $? -ne 0 ]]; then
    return 2
  fi
  
  if [ -x ${PGM_PGBIN_DIR}/pg_config ]; then
    local pgm_report="$(${PGM_PGBIN_DIR}/pg_config)"
  else
    printError "no valid pg_config in '${PGM_PGBIN_DIR}'\n"
    return 3
  fi

  eval ${pgm_result_var}='${pgm_report}'
}

function checkAllServers()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgm_result_var=$1
  local pgm_report=""
  local pgm_status=0

  getServers pgm_server_list
  for pgm_server in ${pgm_server_list}
  do
    checkServer ${pgm_server} pgm_check_result
    local pgm_report="${pgm_report} ${pgm_check_result}"
    if [[ $? -ne 0 ]]; then
      local pgm_status=$(( ${pgm_status} + 1 ))
    fi
  done

  eval ${pgm_result_var}='${pgm_report//[ ][ ]+/ }'
  return ${pgm_status}
}

function checkServer()
{
  declareFunction "-server- -result-" "$*"
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  
  local pgm_server=$1
  local pgm_result_var=$2
  
  local pgm_status=0

  setServer ${pgm_server}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set server ${pgm_server}"
    return 2
  fi

  checkEnvironment pgm_report
}

function installServer()
{
  declareFunction "-directory- -server-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_src_dir=$1
  local pgm_server=$2

  if [ ! -v PGM_PGHOME_DIR ] || [ ! -v PGM_PGBIN_DIR ] || [ ! -v PGM_PGLIB_DIR ] || [ ! -v PGM_PGINCLUDE_DIR ] || [ ! -v PGM_PGSHARE_DIR ] || [ ! -v PGM_PGMAN_DIR ] || [ ! -v PGM_PGDOC_DIR ]; then
    setServer ${pgm_server}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set server ${pgm_server}"
      return 2
    fi
  fi

  cd ${pgm_src_dir}
  ./configure --prefix=${PGM_PGHOME_DIR} --exec-prefix=$(dirname ${PGM_PGBIN_DIR}) --bindir=${PGM_PGBIN_DIR} --libdir=${PGM_PGLIB_DIR} --includedir=${PGM_PGINCLUDE_DIR} --datarootdir=${PGM_PGSHARE_DIR} --mandir=${PGM_PGMAN_DIR} --docdir=${PGM_PGDOC_DIR} --with-openssl --with-perl --with-python --with-ldap 
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
  addServer ${pgm_server}
}
