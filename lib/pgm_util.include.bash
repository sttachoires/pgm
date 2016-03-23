#! @BASH@
# 
# Bash library for PGM scripts
#
# S. Tachoires		19/02/2016	Initial version
#
#set -xv
if [ "${PGM_UTIL_INCLUDE}" == "LOADED" ]; then
  return
fi
export PGM_UTIL_INCLUDE="LOADED"

# CONSTANTS
PGM_LOG="default.log"

# VARIABLES
export PGM_TRACELEVEL=1
export PGM_OUTPUT=" >> ${PGM_LOG} 2>&1 >&3 3>&- | tee -a ${PGM_LOG} 3>&-"

function pgmPrint()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  pgm_print_context="$1"
  pgm_print_text="$2"
  pgm_print_date=`date "+%Y.%m.%d-%H.%M.%S"`
  pgm_print_user=`who am i | cut --delimiter=' ' --fields=1`
  pgm_spaces=" #${BASH_SUBSHELL}# "
  if [[ ${pgm_print_context} -le ${PGM_TRACELEVEL} ]]; then
    printf "[${FUNCNAME[2]}] ${pgm_print_text}\n"
  fi
  printf "${pgm_print_date} '${pgm_print_user}' [${FUNCNAME[2]}] ${pgm_print_text}\n" >> ${PGM_LOG}
}

function printError()
{
  pgmPrint 1 "$*"
}

function printTrace()
{
  pgmPrint 2 "$*"
}

function printInfo()
{
  pgmPrint 3 "$*"
}

function declareFunction()
{
  pgm_function_name="${FUNCNAME[1]}"
  printTrace "Enter ${pgm_function_name} with '$*'\n"
  case $# in
    1 )
       analyzeStandart "$*"
       ;;

    2 )
       pgm_param_format="$2"
       shift
       analyzeStandart "$*"
       ;;
  esac
}

function analyzeParameters()
{
  analyzeStandart $*
}

function analyzeStandart()
{
  for pgm_option in $*
  do
    case "${pgm_option}" in
      "-h"|"-?"|"--help"|"help")
        printf "${USAGE}\n"
        ;;

      "-v"|"--verbose"|"verbose")
        export PGM_TRACELEVEL=3
        PGM_OUTPUT=" 2>&1 | tee -a ${PGM_LOG}"
        ;;

      "-t"|"--trace"|"trace")
        export PGM_TRACELEVEL=2
        export PGM_OUTPUT=" >> ${PGM_LOG} 2>&1 >&3 3>&- | tee -a ${PGM_LOG} 3>&-"
        ;;

      "-e"|"--error"|"error")
        export PGM_TRACELEVEL=1
        export PGM_OUTPUT=" >> ${PGM_LOG} 2>&1 >&3 3>&- | tee -a ${PGM_LOG} 3>&-"
        ;;

      "-q"|"--quiet"|"--silent"|"silent")
        export PGM_TRACELEVEL=0
        PGM_OUTPUT=" 2>&1 >> ${PGM_LOG}"
        ;;

      * )
        ;;
    esac
  done
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
  declareFunction "-template- -filename-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_tpl=$1
  pgm_dest=$2
  if [ ! -r "${pgm_tpl}" ]; then
    return 2
  fi
  if [ ! -w "$(dirname ${pgm_dest})" ]; then
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
  
  if [ -e "${pgm_dest}" ]; then
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
  declareFunction "-string- -conditional-test- -result-" "$*"

  pgm_status=0
  pgm_report=""

  if [ $# -ne 3 ]; then
    return 1
  fi
  pgm_var_type=$1
  pgm_condition=$2
  pgm_result_var=$3

  pgm_all_vars="${!PGM_*}"
  pgm_selected_vars="$(printf ${pgm_all_vars//[ ][ ]+/$'\n'} | egrep -o PGM_.*${pgm_var_type})"
  for pgm_var in ${pgm_selected_vars}
  do
    if ! [ -z "${pgm_var}" ]; then
      pgm_value="${!pgm_var}"
      if ! [ ${pgm_condition} "${pgm_value}" ]; then
        pgm_report="${pgm_report} ${pgm_var}:'${pgm_value}'"
        pgm_status=$(( ${pgm_status} + 1 ))
      fi
    fi
  done

  eval export ${pgm_result_var}='${pgm_report//[ ][ ]+/ }'
  return ${pgm_status}
}

function checkEnvironment()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  pgm_result_var=$1
  pgm_status=0
  pgm_report=""

  ensureVars _DIR -d pgm_part_report
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  ensureVars _CONF -w pgm_part_report
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  ensureVars _LOG -w pgm_part_report
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  ensureVars _EXE -x pgm_part_report
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  ensureVars _INVENTORY -w pgm_part_report
  if [[ $? -ne 0 ]]; then
    pgm_report="${pgm_report} ${pgm_part_report}"
    pgm_status=$(( ${pgm_status} + 1 ))
  fi

  eval export ${pgm_result_var}='${pgm_report//[ ][ ]+/ }'
  return ${pgm_status}
}

