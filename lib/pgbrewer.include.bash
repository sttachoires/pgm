#! @BASH@

# Differents constants to fit pgbrewer scripts

# 19.02.2016	S. Tachoires	Initiate
#set -xv

if [ "${PGB_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGB_INCLUDE="LOADED"

. @CONFDIR@/pgbrewer.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGB_LIB_DIR}/util.include

function getRemovedConfigurations()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgb_result_var=$1
  local pgb_report=""

  for pgb_config_dir in ${PGB_CONF_DIR}/\.??*
  do
    if [ "${pgb_config_dir%/}x" != "x" ] && [ -d ${pgb_config_dir%/} ]; then
      pgb_tempo=$(basename ${pgb_config_dir%/})
      pgb_report="${pgb_report} ${pgb_tempo#.}"
    fi
  done

  eval ${pgb_result_var}='${pgb_report## }'
}

function getConfigurations()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  local pgb_result_var=$1
  local pgb_report=""

  for pgb_config_dir in ${PGB_CONF_DIR}/*
  do
    if [ "${pgb_config_dir%/}x" != "x" ] && [ -d ${pgb_config_dir%/} ]; then
      pgb_report="${pgb_report} $(basename ${pgb_config_dir%/})"
    fi
  done

  eval ${pgb_result_var}='${pgb_report## }'
}

function addConfig()
{
  declareFunction "+config+ !config!" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_source=$1
  local pgb_config=$2
  if [ "${pgb_source}x" == "defaultx" ]; then
    local pgb_source_dir=${PGB_CONF_DIR}
  else
    local pgb_source_dir=${PGB_CONF_DIR}/${pgb_source}
  fi
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

    pgb_conf_list="pgbrewer.conf"

    for pgb_conf in ${pgb_conf_list}
    do
      local pgb_config_file=${pgb_config_dir}/${pgb_conf}
      local pgb_source_file=${pgb_source_dir}/${pgb_conf}
      instantiateConf ${pgb_source_file} ${pgb_config_file}
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

  local pgb_confif_dir=${PGB_CONF_DIR}/${pgb_config}

  if [ ! -d ${pgb_config_dir} ]; then
    printError "unknown configuration ${pgb_config}"
    return 2
  fi

  unset PGB_CONF
  export PGB_CONFIG_NAME=${pgb_config}
  . ${PGB_CONF_DIR}/pgbrewer.conf
  if [[ $? -ne 0 ]]; then
    printError "cannot load config ${pgb_config}"
    return 3
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
  chmod ug=r,o= ${pgb_confif_dir}/*.conf
  if [[ $? -ne 0 ]]; then
    printError "cannot mark config as created"
    return 7
  fi
}

function editConfig()
{
  declareFunction ".configfilename. +config+" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_config=$1
  local pgb_command=$2

  if [ "${pgb_config}x" == "defaultx" ]; then
    local pgb_config_dir=${PGB_CONF_DIR}
  else
    local pgb_config_dir=${PGB_CONF_DIR}/${pgb_config}
  fi
  local pgb_date=$(date "+%Y.%m.%d_%H.%M.%S")

  local pgb_config_file=${pgb_config_dir}/${pgb_command}.conf
  if [ "${pgb_config_file}x" != "x" ]; then
    if [ -w "${pgb_config_file}" ]; then
      cp ${pgb_config_file} ${pgb_config_file}.${pgb_date}
      if [[ $? -ne 0 ]]; then
        printError "Cannot backup ${pgb_config_dir}/${pgb_command}.conf"
        return 3
      fi
      ${EDITOR:=vi} ${pgb_config_file}
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

          printError " Syntax error on ${pgb_command}.conf, old one restored, bad one saved in ${pgb_config_file}.bad.${pgb_date}"
          return 7
        else
          printTrace " ${pgb_config} ${pgb_command} configuration saved\n"
        fi
      else
        printTrace " ${pgb_config} ${pgb_command} configuration saved\n"
      fi
    else
      more ${pgb_config_file}
    fi
  else
    printError " cannot found ${pgb_config} ${pgb_command} configuration\n"
    return 2
  fi
}

function compareConfig()
{
  declareFunction "+config+ +config+ -result-" "$*"
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_source=$1
  local pgb_config=$2
  local pgb_result_var=$3

  for pgb_confile in ${PGB_CONF_DIR}/${pgb_config}/*.conf
  do
    local pgb_sourcefile="$PGB_CONF_DIR}/${pgb_source}/$(basename ${pgb_confile})"
    if [ -r ${pgb_sourcefile} ]; then
      local pgb_diff=`(export PGB_CONFIG_NAME=${pgb_config}; . etc/pgbrewer/pgbrewer.conf; env | grep "PGB_" | sort) > /var/tmp/pg${pgb_config}.tmp; (export PGB_CONFIG_NAME=${pgb_source}; . etc/pgbrewer/pgbrewer.conf; env | grep "PGB_" | sort) > /var/tmp/pgbrewer${pgb_source}.tmp; diff --suppress-common-lines --ignore-space-change --ignore-blank-lines --minimal --old-line-format='%L' --new-line-format='#%L' --unchanged-line-format='' /var/tmp/pgbrewer${pgb_config}.tmp /var/tmp/pgbrewer${pgb_source}.tmp; rm -f /var/tmp/pgbrewer${pgb_config}.tmp /var/tmp/pgbrewer${pgb_source}.tmp`
      if [[ $? -ne 0 ]]; then
        pgb_report="${pgb_report} ${pgb_diff}"
      fi
    else
      pgb_report="${pgb_report} missing ${pgb_sourcefile}"
    fi
  done
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
  local pgb_config_dir=${PGB_CONF_DIR}/.${pgb_config}

  if [ ! -d "${pgb_config_dir}" ]; then
    printError "${pgb_config} cannot be deleted"
    return 2
  fi
  rm -rf ${pgb_config_dir}
}
