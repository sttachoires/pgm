#! @BASH@

# Differents constants to fit pgm scripts

# 19.02.2016	S. Tachoires	Initiate
#set -xv

if [ "${PGM_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGM_INCLUDE="LOADED"

. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGM_LIB_DIR}/util.include

function getRemovedConfigurations()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgm_result_var=$1
  local pgm_report=""

  for pgm_config_dir in ${PGM_CONF_DIR}/\.??*
  do
    if [ "${pgm_config_dir%/}x" != "x" ] && [ -d ${pgm_config_dir%/} ]; then
      pgm_tempo=$(basename ${pgm_config_dir%/})
      pgm_report="${pgm_report} ${pgm_tempo#.}"
    fi
  done

  eval ${pgm_result_var}='${pgm_report## }'
}

function getConfigurations()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgm_result_var=$1
  local pgm_report=""

  for pgm_config_dir in ${PGM_CONF_DIR}/*
  do
    if [ "${pgm_config_dir%/}x" != "x" ] && [ -d ${pgm_config_dir%/} ]; then
      pgm_report="${pgm_report} $(basename ${pgm_config_dir%/})"
    fi
  done

  eval ${pgm_result_var}='${pgm_report## }'
}

function addConfig()
{
  declareFunction "-config- -config-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_source=$1
  local pgm_config=$2
  if [ "${pgm_source}x" == "defaultx" ]; then
    local pgm_source_dir=${PGM_CONF_DIR}
  else
    local pgm_source_dir=${PGM_CONF_DIR}/${pgm_source}
  fi
  local pgm_config_dir=${PGM_CONF_DIR}/${pgm_config}

  if [ ! -d ${pgm_source_dir} ]; then
    printError "${pgm_source} doesn't exists"
    return 2
  fi
  mkdir --parents ${pgm_config_dir}
  if [[ $? -ne 0 ]]; then
    printError "Cannot create configuration ${pgm_config}"
    return 3
  fi

  pgm_command_list="${pgm_source_dir}/*.conf"
  for pgm_command in ${pgm_command_list}
  do
    local pgm_config_file=${pgm_config_dir}/$(basename ${pgm_command})
    instantiateConf ${pgm_command} ${pgm_config_file}
    if [[ $? -ne 0 ]]; then
      printError "cannot instanciate config file ${pgm_config_file} from ${pgm_command}"
    else
      printTrace "${pgm_config_file} created"
    fi
  done
}

function createConfig()
{
  declareFunction "-config-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgm_config=$1

  if [ "${pgm_config}x" == "defaultx" ]; then
    return 0
  fi

  local pgm_confif_dir=${PGM_CONF_DIR}/${pgm_config}

  if [ ! -d ${pgm_config_dir} ]; then
    printError "unknown configuration ${pgm_config}"
    return 2
  fi

  unset PGM_CONF
  export PGM_CONFIG_NAME=${pgm_config}
  . ${PGM_CONF_DIR}/pgm.conf
  if [[ $? -ne 0 ]]; then
    printError "cannot load config ${pgm_config}"
    return 3
  fi

  ensurePgInventory
  if [[ $? -ne 0 ]]; then
    printError "cannot create inventory for ${pgm_config}"
    return 4
  fi
  
  ensureVars -d _DIR pgm_missing_dirs
  if [[ $? -ne 0 ]]; then
    printError "error ensuring directories"
    return 5
  fi

  local pgm_status=0
  local pgm_report=""
  for pgm_dir in ${pgm_missing_dirs}
  do
    mkdir -p ${pgm_dir}
    if [[ $? -ne 0 ]]; then
      pgm_status=$(( pgm_status++ ))
      pgm_report="${pgm_report} ${pgm_dir}"
    fi
  done
  if [[ ${pgm_status} -ne 0 ]]; then
    printError "error creating directory(ies) ${pgm_report}"
    return 6
  fi
  chmod ug=r,o= ${pgm_confif_dir}/*.conf
  if [[ $? -ne 0 ]]; then
    printError "cannot mark config as created"
    return 7
  fi
}

function editConfig()
{
  declareFunction "-config- -command-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_config=$1
  local pgm_command=$2

  if [ "${pgm_config}x" == "defaultx" ]; then
    local pgm_config_dir=${PGM_CONF_DIR}
  else
    local pgm_config_dir=${PGM_CONF_DIR}/${pgm_config}
  fi
  local pgm_date=$(date "+%Y.%m.%d_%H.%M.%S")

  local pgm_config_file=${pgm_config_dir}/${pgm_command}.conf
  if [ "${pgm_config_file}x" != "x" ]; then
    if [ -w "${pgm_config_file}" ]; then
      cp ${pgm_config_file} ${pgm_config_file}.${pgm_date}
      if [[ $? -ne 0 ]]; then
        printError "Cannot backup ${pgm_config_dir}/${pgm_command}.conf"
        return 3
      fi
      ${EDITOR:=vi} ${pgm_config_file}
      if [[ $? -ne 0 ]]; then
        printError " problem editing ${pgm_config_file} with ${EDITOR}"
        return 4
      fi
      # Test script correctness for bash files
      egrep --quiet "^ #![[:space:]]*${PGM_BASH}" ${pgm_config_file}
      if [[ $? -eq 0 ]]; then
        ${PGM_BASH} -n ${pgm_config_file}
        if [[ $? -ne 0 ]]; then
          mv -f ${pgm_config_file} ${pgm_config_file}.bad.${pgm_date}
          if [[ $? -ne 0 ]]; then
            printError "Cannot backup bad ${pgm_config_file}"
            return 5
          fi

          mv ${pgm_config_file}.${pgm_date} ${pgm_config_file}
          if [[ $? -ne 0 ]]; then
            printError "Cannot restore ${pgm_config_file}"
            return 6
          fi

          printError " Syntax error on ${pgm_command}.conf, old one restored, bad one saved in ${pgm_config_file}.bad.${pgm_date}"
          return 7
        else
          printTrace " ${pgm_config} ${pgm_command} configuration saved\n"
        fi
      else
        printTrace " ${pgm_config} ${pgm_command} configuration saved\n"
      fi
    else
      more ${pgm_config_file}
    fi
  else
    printError " cannot found ${pgm_config} ${pgm_command} configuration\n"
    return 2
  fi
}

function compareConfig()
{
  declareFunction "-config- -config- -result-" "$*"
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_source=$1
  local pgm_config=$2
  local pgm_result_var=$3

  for pgm_confile in ${PGM_CONF_DIR}/${pgm_config}/*.conf
  do
    local pgm_sourcefile="$PGM_CONF_DIR}/${pgm_source}/$(basename ${pgm_confile})"
    if [ -r ${pgm_sourcefile} ]; then
      local pgm_diff=$(diff ${pgm_confile} ${pgm_sourcefile})
      if [[ $? -ne 0 ]]; then
        pgm_report="${pgm_report} ${pgm_diff}"
      fi
    else
      pgm_report="${pgm_report} missing ${pgm_sourcefile}"
    fi
  done
}

function removeConfig()
{
  declareFunction "-config-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgm_config=$1

  if [ "${pgm_config}" == "default" ]; then
    printError "default configuration cannot be removed nor dropped"
    return 2
  fi
  local pgm_config_dir=${PGM_CONF_DIR}/${pgm_config}

  if [ ! -d "${pgm_config_dir}" ]; then
    printError "${pgm_config} cannot be removed"
    return 2
  fi
  mv ${pgm_config_dir} ${PGM_CONF_DIR}/.${pgm_config}
}

function deleteConfig()
{
  declareFunction "-config-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgm_config=$1

  if [ "${pgm_config}" == "default" ]; then
    printError "default configuration cannot be removed nor dropped"
    return 2
  fi
  local pgm_config_dir=${PGM_CONF_DIR}/.${pgm_config}

  if [ ! -d "${pgm_config_dir}" ]; then
    printError "${pgm_config} cannot be deleted"
    return 2
  fi
  rm -rf ${pgm_config_dir}
}
