#! @BASH@
# 
# Bash library for PGM scripts
#
# S. Tachoires		19/02/2016	Initial version
#
#set -xv
if [[ "${PGM_UTIL_INCLUDE}" == "LOADED" ]]; then
  return
fi

# CONSTANTS

# VARIABLES
function printError()
{
  if [[ -w "${PGM_LOG}" ]]; then
    printf "$*" >&2 | tee -a ${PGM_LOG}
  else
    printf "$*" >&2
  fi
}

function printInfo()
{
  if [[ -w "${PGM_LOG}" ]]; then
    printf "$*" | tee -a ${PGM_LOG}
  else
    printf "$*" 
  fi
}

function exitError()
{
  if [[ $# -gt 1 ]]; then
    exitCode=$1
    shift
  else
    exitCode=1
  fi
  printError "$*"
  exit ${exitCode}
}

function instantiateTemplate()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_tpl=$1
  pgm_dest=$2
  if [[ ! -r "${pgm_tpl}" ]]; then
    return 2
  fi
  if [[ ! -w "$(dirname ${pgm_dest})" ]]; then
    return 3
  fi

  pgm_sed_command=""
  for pgm_var in ${!PGM_*}
  do
    if ! [[ ${!pgm_var} =~ .*[/].* ]]; then
      pgm_sed_command="${pgm_sed_command} s/\${${pgm_var}}/${!pgm_var}/;"
    elif ! [[ ${!pgm_var} =~ .*[%].* ]]; then
      pgm_sed_command="${pgm_sed_command} s%\${${pgm_var}}%${!pgm_var}%;"
    fi
  done
  
  if [[ -e "${pgm_dest}" ]]; then
    cp ${pgm_dest} ${pgm_dest}.orig
    if [[ $? -ne 0 ]]; then
      return 4
    fi
  fi
  sed "${pgm_sed_command}" ${pgm_tpl} > ${pgm_dest}
  if [[ $? -ne 0 ]]; then
    return 5
  fi
}

function ensureVars()
{
  pgm_status=0
  pgm_report=""

  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_all_vars="${!PGM_*}"
  pgm_selected_vars="$(printf ${pgm_all_vars//[ ][ ]+/$'\n'} | egrep -o PGM_.*$1)"
  echo "pgm_selected_vars=${pgm_selected_vars}"
  for pgm_var in ${pgm_selected_vars}
  do
#    pgm_var=$(echo ${pgm_all_var} | egrep -o "PGM_.*$1")
    if ! [[ -z "${pgm_var}" ]]; then
      eval pgm_value=\"\$${pgm_var}\"
      if ! [ $2 "${pgm_value}" ]; then
        pgm_report="${pgm_report} ${pgm_var}:'${pgm_value}'"
        pgm_status=$(( ${pgm_status} + 1 ))
      fi
    fi
  done

  printf "${pgm_report//[ ][ ]+/ }"
  return ${pgm_status}
}

function checkEnvironment()
{
  pgm_status=0
  pgm_report=""

  pgm_part_report="$(ensureVars _DIR -d)"
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  pgm_part_report="$(ensureVars _CONF -w)"
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  pgm_part_report="$(ensureVars _LOG -w)"
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  pgm_part_report="$(ensureVars _EXE -x)"
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  pgm_part_report="$(ensureVars _TAB -w)"
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  printf "${pgm_report//[ ][ ]+/ }"
  return ${pgm_status}
}

# Nothing should happens after next line
export PGM_UTIL_INCLUDE="LOADED"
