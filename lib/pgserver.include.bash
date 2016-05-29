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

function getInstalledServers()
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

  local pgs_source_dir=${PGB_CONF_DIR}/${pgs_source_config}/pgserver/${pgs_source_server}
  local pgs_server_dir=${PGB_CONF_DIR}/${pgs_config}/pgserver/${pgs_server}

  if [ ! -d ${pgs_source_dir} ]; then
    printError "${pgs_source} doesn't exists"
    return 2
  fi

  if [ -d ${pgs_server_dir} ]; then
    return 3
  elif [ -d ${PGB_CONF_DIR}/${pgs_config}/pgserver/.${pgs_server} ]; then
    mv ${PGB_CONF_DIR}/${pgs_config}/pgserver/.${pgs_config} ${pgs_server_dir}
    printTrace "${pgs_server} unremoved"
  else
    mkdir --parents ${pgs_server_dir}
    if [ ! -d ${pgs_server_dir} ]; then
      printError "Cannot create server ${pgs_server}"
      return 3
    fi

    pgs_conf_list="pgserver.conf"

    for pgs_conf in ${pgs_conf_list}
    do
      local pgs_config_file=${pgs_config_dir}/${pgs_conf}
      local pgs_source_file=${pgs_source_dir}/${pgs_conf}
      if [ "${pgs_source_server}x" == "defaultx" ]; then
        initiateConf ${pgs_source_file} ${pgs_config_file}
      else
        copyConf ${pgs_source_file} ${pgs_config_file}
      fi
      if [[ $? -ne 0 ]]; then
        printError "cannot instanciate servr file ${pgs_config_file} from ${pgs_source_file}"
      else
        printTrace "${pgs_server} created"
      fi
    done
  fi
}

function installServer()
{
  declareFunction "+config+ +server+" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgs_config=$1
  local pgs_server=$2

  setServer ${pgs_server}
  if [[ $? -ne 0 ]]; then
    printError "Cannot set server ${pgs_server}"
    return 2
  fi
  
  (cd ${PGB_TMP_DIR}/pgserver_src/; ${PGS_PGSERVER_PROVIDE})

  (cd ${PGB_TMP_DIR}/pgserver_src/${PGS_PGSERVER_SOURCE}; ./configure --prefix=${PGS_PGHOME_DIR} --exec-prefix=$(dirname ${PGS_PGBIN_DIR}) --bindir=${PGS_PGBIN_DIR} --libdir=${PGS_PGLIB_DIR} --includedir=${PGS_PGINCLUDE_DIR} --datarootdir=${PGS_PGSHARE_DIR} --mandir=${PGS_PGMAN_DIR} --docdir=${PGS_PGDOC_DIR} ${PGS_PGSERVER_OPTIONS})
  if [[ $? -ne 0 ]]; then
    return 3
  fi

  (cd ${PGB_TMP_DIR}/pgserver_src/${PGS_PGSERVER_SOURCE}; make world)
  if [[ $? -ne 0 ]]; then
    return 4
  fi

  (cd ${PGB_TMP_DIR}/pgserver_src/${PGS_PGSERVER_SOURCE}; make check)
  if [[ $? -ne 0 ]]; then
    return 5
  fi

  (cd ${PGB_TMP_DIR}/pgserver_src/${PGS_PGSERVER_SOURCE}; make install-world)
  if [[ $? -ne 0 ]]; then
    return 6
  fi

  (cd ${PGB_TMP_DIR}/pgserver_src/${PGS_PGSERVER_SOURCE}; make distclean)
  if [[ $? -ne 0 ]]; then
    return 7
  fi
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

  if [ "${PGS_PGSERVER_NAME}" != "${pgs_server}" ]; then
    unset PGS_DOT_PGSERVER_CONF
    unset PGS_PGSERVER_CONF

    if [ "${pgs_server}x" != "defaultx" ]; then
      export PGS_PGSERVER_NAME=${pgs_server}
    else
      unset PGS_PGSERVER_NAME
    fi

    source ${PGB_CONF_DIR}/${pgs_config}/pgserver/${pgs_server}/pgserver.conf
  fi
}

function setDefaultServer()
{
  declareFunction "+config+ +server+" "$*"
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgs_config=$1
  local pgs_server=$2
  setConfig ${pgs_config}
  local pgs_default_server=${PGB_CONFIG_DIR}/${PGB_CONFIG_NAME}/.defaultServer

  printf "${pgs_server}" > ${pgs_default_server}

  if [[ $? -ne 0 ]]; then
    return 2
  fi
}

function getDefaultServer()
{
  declareFunction "+config+ .result." "$*"
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgs_config=$1
  local pgs_result_var=$2

  setConfig ${pgs_config}

  local pgs_default_server=${PGB_CONFIG_DIR}/${PGB_CONFIG_NAME}/.defaultServer
  if [ -r ${pgs_default_server} ]; then
    pgs_result="$(cat ${pgs_default_server})"
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  else
    pgs_result="default"
  fi

  eval export ${pgs_result_var}='${pgs_result}'
  return 0
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
