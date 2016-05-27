#! @BASH@

# Differents constants to fit pgbrewer scripts

# 19.02.2016	S. Tachoires	Initiate
#set -xv

if [ "${PGS_SERVER_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGS_SERVER_INCLUDE="LOADED"

. @CONFDIR@/default/pgbrewer.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGB_CONF_DIR}/default/pgserver/default/pgserver.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/pgbrewer.include

function getAllServers()
{
  declareFunction "+config+ -result-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgs_config=$1
  local pgs_result_var=$2
  local pgs_report=""

  if [ "${pgs_config}x" == "defaultx" ]; then
    pgs_conf_dir=${PGB_CONF_DIR}/pgserver
  else
    pgs_conf_dir=${PGB_CONF_DIR}/${pgs_config}/pgserver
  fi

  for pgs_server_dir in ${pgs_conf_dir}/*
  do
    if [ "${pgs_server_dir%/}x" != "x" ] && [ -d ${pgs_server_dir%/} ]; then
      pgs_tempo=$(basename ${pgs_server_dir%/})
      pgs_report="${pgs_report} ${pgs_tempo#.}"
    fi
  done

  eval ${pgs_result_var}='${pgs_report## }'
}

function getCreatedServers()
{
  declareFunction "+config+ -result-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgs_config=$1
  local pgs_result_var=$2
  local pgs_report=""

  if [ "${pgs_config}x" == "defaultx" ]; then
    pgs_conf_dir=${PGB_CONF_DIR}/pgserver
  else
    pgs_conf_dir=${PGB_CONF_DIR}/${pgs_config}/pgserver
  fi

  for pgs_server_dir in ${pgs_conf_dir}/??*
  do
    if [ "${pgs_server_dir%/}x" != "x" ] && [ -d ${pgs_server_dir%/} ]; then
      pgs_tempo=$(basename ${pgs_server_dir%/})
      setServer ${pgs_config} ${pgs_tempo}
      if [ -x ${PGS_PGBIN_DIR}/pg_config ]; then
        pgs_report="${pgs_report} ${pgs_tempo}"
      fi
    fi
  done

  eval ${pgs_result_var}='${pgs_report## }'
}

function getAddedServers()
{
  declareFunction "+config+ -result-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgs_config=$1
  local pgs_result_var=$2
  local pgs_report=""

  if [ "${pgs_config}x" == "defaultx" ]; then
    pgs_conf_dir=${PGB_CONF_DIR}
  else
     pgs_conf_dir=${PGB_CONF_DIR}/${pgs_config}
  fi

  for pgs_server_dir in ${pgs_conf_dir}/pgserver/*
  do
    if [ "${pgs_server_dir%/}x" != "x" ] && [ -d ${pgs_server_dir%/} ]; then
      pgs_tempo=$(basename ${pgs_server_dir%/})
      setServer ${pgs_config} ${pgs_tempo}
      if [ ! -x ${PGS_PGBIN_DIR}/pg_config ]; then
        pgs_report="${pgs_report} ${pgs_tempo}"
      fi
    fi
  done

  eval ${pgs_result_var}='${pgs_report## }'
}

function addServer()
{
  declareFunction "+config+ +server+ +config+ !server!" "$*"

  if [[ $# -ne 4 ]]; then
    return 1
  fi

  local pgs_source_config=$1
  local pgs_source_server=$2
  local pgs_config=$3
  local pgs_server=$4

  local pgs_source_dir=${PGB_CONF_DIR}/${pgs_source_config:-default}/pgserver/${pgs_source_server:-default}
  local pgs_config_dir=${PGB_CONF_DIR}/${pgs_config:-default}/pgserver/${pgs_server:-default}

  if [ ! -d ${pgs_source_dir} ]; then
    printError "${pgs_source} doesn't exists"
    return 2
  fi

  if [ -d ${pgs_config_dir} ]; then
    return 3
  elif [ -d ${PGB_CONF_DIR}/${pgs_config:-default}/pgserver/.${pgs_server:-default} ]; then
    mv ${PGB_CONF_DIR}/.${pgb_config} ${PGB_CONF_DIR}/${pgb_config}
    printTrace "${pgb_config} unremoved"
  else
    mkdir --parents ${pgb_config_dir}
    if [ ! -d ${pgb_config_dir} ]; then
      printError "Cannot create configuration ${pgb_config}"
      return 3
    fi

    pgs_conf_list="pgserver.conf"

    for pgs_conf in ${pgs_conf_list}
    do
      local pgs_config_file=${pgs_config_dir}/${pgs_conf}
      local pgs_source_file=${pgs_source_dir}/${pgs_conf}
      instantiateConf ${pgs_source_file} ${pgs_config_file}
      if [[ $? -ne 0 ]]; then
        printError "cannot instanciate config file ${pgs_config_file} from ${pgs_source_file}"
      else
        printTrace "${pgs_config} created"
      fi
    done
  fi
}

function installServer()
{
  declareFunction "-directory- -server-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgs_src_dir=$1
  local pgs_server=$2

  if [ ! -v PGB_PGHOME_DIR ] || [ ! -v PGB_PGBIN_DIR ] || [ ! -v PGB_PGLIB_DIR ] || [ ! -v PGB_PGINCLUDE_DIR ] || [ ! -v PGB_PGSHARE_DIR ] || [ ! -v PGB_PGBrewer.N_DIR ] || [ ! -v PGB_PGDOC_DIR ]; then
    setServer ${pgs_server}
    if [[ $? -ne 0 ]]; then
      printError "Cannot set server ${pgs_server}"
      return 2
    fi
  fi

  cd ${pgs_src_dir}
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
  addServer ${pgs_server}
}

function setServer()
{
  declareFunction "+config+ ~server~" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgs_config=$1
  local pgs_server=$2

  setConfig ${pgs_config}

  unset PGS_DOT_PGSERVER_CONF
  unset PGS_PGSERVER_CONF

  if [ "${pgs_server}x" != "defaultx" ]; then
    export PGS_PGSERVER_NAME=${pgs_server}
  else
    unset PGS_PGSERVER_NAME
  fi

  source ${PGB_CONF_DIR}/${PGB_CONFIG_NAME:-default}/pgserver/${PGS_PGSERVER_NAME:-default}/pgserver.conf
}

function serverInfo()
{
  declareFunction "+config+ +server+ -result-" "$*"

  if [[ $# -ne 3 ]]; then
    return 1
  fi
  
  local pgs_config=$1
  local pgs_server=$2
  local pgs_result_var=$3

  setServer ${pgs_config} ${pgs_server}
  if [[ $? -ne 0 ]]; then
    return 2
  fi
  
  if [ -x ${PGS_PGBIN_DIR}/pg_config ]; then
    local pgs_report="$(${PGS_PGBIN_DIR}/pg_config)"
  else
    printError "no valid pg_config in '${PGB_PGBIN_DIR}'\n"
    return 3
  fi

  eval ${pgs_result_var}='${pgs_report}'
}

function checkAllServers()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgs_result_var=$1
  local pgs_report=""
  local pgs_status=0

  getServers pgs_server_list
  for pgs_server in ${pgs_server_list}
  do
    checkServer ${pgs_server} pgs_check_result
    local pgs_report="${pgs_report} ${pgs_check_result}"
    if [[ $? -ne 0 ]]; then
      local pgs_status=$(( ${pgs_status} + 1 ))
    fi
  done

  eval ${pgs_result_var}='${pgs_report//[ ][ ]+/ }'
  return ${pgs_status}
}

function checkServer()
{
  declareFunction "-server- -result-" "$*"
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  
  local pgs_server=$1
  local pgs_result_var=$2
  
  local pgs_status=0

  setServer ${pgs_server}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set server ${pgs_server}"
    return 2
  fi

  checkEnvironment pgs_report
}
