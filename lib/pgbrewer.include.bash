#! @BASH@

# Differents constants to fit pgbrewer scripts

# 19.02.2016	S. Tachoires	Initiate
#set -xv

if [ "${PGB_PGBREWER_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGB_PGBREWER_INCLUDE="LOADED"

. @CONFDIR@/default/pgbrewer.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGB_LIB_DIR}/util.include

function getAllConfigurations()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgb_result_var=$1
  local pgb_report=""

  for pgb_config_dir in ${PGB_CONF_DIR}/??*
  do
    if [ "${pgb_config_dir%/}x" != "x" ] && [ -d ${pgb_config_dir%/} ]; then
      pgb_tempo=$(basename ${pgb_config_dir%/})
      pgb_report="${pgb_report} ${pgb_tempo#.}"
    fi
  done

  eval ${pgb_result_var}='${pgb_report## }'
}

function getAddedConfigurations()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgb_result_var=$1
  local pgb_report=""

  for pgb_config_dir in ${PGB_CONF_DIR}/*
  do
    if [ "${pgb_config_dir%/}x" != "x" ] && [ -d ${pgb_config_dir%/} ] && [ -w ${pgb_config_dir%/} ] && [ -w ${pgb_config_dir%/}/pgbrewer.conf ]; then
      pgb_report="${pgb_report} $(basename ${pgb_config_dir%/})"
    fi
  done

  eval ${pgb_result_var}='${pgb_report## }'
}

function getCreatedConfigurations()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgb_result_var=$1
  local pgb_report=""

  for pgb_config_dir in ${PGB_CONF_DIR}/*
  do
    if [ "${pgb_config_dir%/}x" != "x" ] && [ -d ${pgb_config_dir%/} ] && [ -r ${pgb_config_dir%/} ] && [ ! -w ${pgb_config_dir%/}/pgbrewer.conf ]; then
      pgb_report="${pgb_report} $(basename ${pgb_config_dir%/})"
    fi
  done

  eval ${pgb_result_var}='${pgb_report## }'
}

function getCommands()
{
  declareFunction "+config+ -result-" "$*"

  if  [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_config=$1
  local pgb_result_var=$2

  local pgb_result_list=""
  setConfig ${pgb_config}

  for pgb_command in ${PGB_COMMAND_DIR}/*_command
  do
    pgb_command="$(basename ${pgb_command%_command})"
    pgb_result_list="${pgb_result_list} ${pgb_command}"
  done

  eval export ${pgb_result_var}='${pgb_result_list## }'
  return 0
}

function addConfig()
{
  declareFunction "+config+ !config!" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_source=$1
  local pgb_config=$2

  local pgb_source_dir=${PGB_CONF_DIR}/${pgb_source}
  local pgb_config_dir=${PGB_CONF_DIR}/${pgb_config}

  if [ ! -d ${pgb_source_dir} ]; then
    printError "${pgb_source} doesn't exists"
    return 2
  fi

  if [ -d ${pgb_config_dir} ]; then
    return 3
  elif [ -d ${PGB_CONF_DIR}/.${pgb_config} ]; then
    mv ${PGB_CONF_DIR}/.${pgb_config} ${PGB_CONF_DIR}/${pgb_config}
    printTrace "${pgb_config} unremoved"
  else
    mkdir --parents ${pgb_config_dir}
    if [ ! -d ${pgb_config_dir} ]; then
      printError "Cannot create configuration ${pgb_config}"
      return 3
    fi

    pgb_confile_list="pgbrewer.conf"

    for pgb_confile in ${pgb_confile_list}
    do
      local pgb_config_file=${pgb_config_dir}/${pgb_confile}
      local pgb_source_file=${pgb_source_dir}/${pgb_confile}
      if [ "${pgb_source}x" == "defaultx" ]; then
        initiateConf ${pgb_source_file} ${pgb_config_file}
      else
        copyConf ${pgb_source_file} ${pgb_config_file}
      fi
      if [[ $? -ne 0 ]]; then
        printError "cannot instanciate config file ${pgb_config_file} from ${pgb_source_file}"
      else
        printTrace "${pgb_config} created"
      fi
    done
  fi
}

function createConfig()
{
  declareFunction "+config+" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgb_config=$1

  if [ "${pgb_config}x" == "defaultx" ]; then
    return 0
  fi

  setConfig ${pgb_config}

  local pgb_config_dir=${PGB_CONF_DIR}/${pgb_config}

  if [ ! -d ${pgb_config_dir} ]; then
    printError "unknown configuration ${pgb_config}"
    return 2
  fi

  ensureVars -d _DIR pgb_missing_dirs
  if [[ $? -ne 0 ]]; then
    printError "error ensuring directories"
    return 5
  fi

  local pgb_status=0
  local pgb_report=""
  for pgb_dir in ${pgb_missing_dirs}
  do
    mkdir -p ${pgb_dir}
    if [[ $? -ne 0 ]]; then
      pgb_status=$(( pgb_status++ ))
      pgb_report="${pgb_report} ${pgb_dir}"
    fi
  done
  if [[ ${pgb_status} -ne 0 ]]; then
    printError "error creating directory(ies) ${pgb_report}"
    return 6
  fi
  chmod ug=r,o= ${pgb_config_dir}/pgbrewer.conf
  if [[ $? -ne 0 ]]; then
    printError "cannot mark config as created"
    return 7
  fi
}

function editConfig()
{
  declareFunction "+config+" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgb_config=$1

  . setConfig ${pgb_config}
  local pgb_config_dir=${PGB_CONF_DIR}/${pgb_config}
  local pgb_date=$(date "+%Y.%m.%d_%H.%M.%S")

  local pgb_config_file=${pgb_config_dir}/pgbrewer.conf
  if [ "${pgb_config_file}x" != "x" ]; then
    if [ -w "${pgb_config_file}" ]; then
      cp ${pgb_config_file} ${pgb_config_file}.${pgb_date}
      if [[ $? -ne 0 ]]; then
        printError "Cannot backup ${pgb_config_file}"
        return 3
      fi
      ${EDITOR:-vi} ${pgb_config_file}
      if [[ $? -ne 0 ]]; then
        printError " problem editing ${pgb_config_file} with ${EDITOR}"
        return 4
      fi
      # Test script correctness for bash files
      egrep --quiet "^ #![[:space:]]*${PGB_BASH}" ${pgb_config_file}
      if [[ $? -eq 0 ]]; then
        ${PGB_BASH} -n ${pgb_config_file}
        if [[ $? -ne 0 ]]; then
          mv -f ${pgb_config_file} ${pgb_config_file}.bad.${pgb_date}
          if [[ $? -ne 0 ]]; then
            printError "Cannot backup bad ${pgb_config_file}"
            return 5
          fi

          mv ${pgb_config_file}.${pgb_date} ${pgb_config_file}
          if [[ $? -ne 0 ]]; then
            printError "Cannot restore ${pgb_config_file}"
            return 6
          fi

          printError " Syntax error in configuration, old one restored, bad one saved in ${pgb_config_file}.bad.${pgb_date}"
          return 7
        else
          printTrace " ${pgb_config} configuration saved\n"
        fi
      else
        printTrace " ${pgb_config} configuration saved\n"
      fi
    else
      more ${pgb_config_file}
    fi
  else
    printError " cannot found ${pgb_config} configuration\n"
    return 2
  fi
}

function setConfig()
{
  declareFunction "+config+" "$*"
  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgb_config=$1

  if [ "${PGB_CONFIG_NAME}" != "${pgb_config}" ]; then
    unset PGB_PGBREWER_CONF
    unset PGB_DOT_PGBREWER_CONF
  
    export PGB_CONFIG_NAME=${pgb_config}

    source ${PGB_CONF_DIR}/default/pgbrewer.conf
  fi
}

function setDefaultConfig()
{
  declareFunction "+config+" "$*"
  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgb_config=$1

  setConfig ${pgb_config}
  local pgb_default_config=${PGB_CONFIG_DIR}/.defaultConfig

  printf "${pgb_config}" > ${pgb_default_config}
    
  if [[ $? -ne 0 ]]; then
    return 2
  fi
}

function getDefaultConfig()
{
  declareFunction "+config+ .result." "$*"
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_config=$1
  local pgb_result_var=$2

  setConfig ${pgb_config}

  local pgb_default_config=${PGB_CONFIG_DIR}/.defaultConfig
  if [ -r ${pgb_default_config} ]; then
    pgb_result="$(cat ${pgb_default_config})"
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  else
    pgb_result="default"
  fi

  eval export ${pgb_result_var}='${pgb_result}'
  return 0
}

function getConfigVars()
{
  declareFunction "+config+ .result." "$*"
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_config=$1
  local pgb_result_var=$2

  local pgb_vars=`setConfig ${pgb_config}; pgb_vars="${!PGB_*}"; for pgb_var in $(printf "${pgb_vars}" | sort); do pgb_value="${!pgb_var}"; printf "${pgb_var}=\"${pgb_value}\"\n"; done`

  eval export ${pgb_result_var}='${pgb_vars}'

  return 0
}

function compareConfig()
{
  declareFunction "+config+ +config+ -result-" "$*"
  if [[ $# -ne 3 ]]; then
    return 1
  fi

  local pgb_source=$1
  local pgb_config=$2
  local pgb_result_var=$3

  getConfigVars ${pgb_source} pgb_source_vars
  getConfigVars ${pgb_config} pgb_config_vars

  local pgb_diff=`diff --suppress-common-lines --ignore-space-change --ignore-blank-lines --minimal --old-line-format='#%L' --new-line-format='%L' --unchanged-line-format='' <(printf "${pgb_source_vars}\n") <(printf "${pgb_config_vars}\n") `
  if [[ $? -eq 0 ]] && [ "${pgb_diff}x" != "x" ]; then
    eval export ${pgb_result_var}="'${pgb_diff}'"
  else
    eval export ${pgb_result_var}=''
  fi
 
  return 0
}

function removeConfig()
{
  declareFunction "+config+" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgb_config=$1

  if [ "${pgb_config}" == "default" ]; then
    printError "default configuration cannot be removed nor dropped"
    return 2
  fi

  setConfig ${pgb_config}
  local pgb_config_dir=${PGB_CONF_DIR}/${pgb_config}

  if [ ! -d "${pgb_config_dir}" ]; then
    printError "${pgb_config} cannot be removed"
    return 2
  fi
  mv ${pgb_config_dir} ${PGB_CONF_DIR}/.${pgb_config}
}

function deleteConfig()
{
  declareFunction "-config-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgb_config=$1

  if [ "${pgb_config}" == "default" ]; then
    printError "default configuration cannot be removed nor dropped"
    return 2
  fi

  setConfig ${pgb_config}
  local pgb_config_dir=${PGB_CONF_DIR}/.${pgb_config}

  if [ ! -d "${pgb_config_dir}" ]; then
    printError "${pgb_config} cannot be deleted"
    return 2
  fi
  rm -rf ${pgb_config_dir}
}

