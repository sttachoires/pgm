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

function pgmPrint()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgm_print_context="$1"
  local pgm_print_text="$2"
  local pgm_print_date=`date "+%Y.%m.%d-%H.%M.%S"`
  local pgm_print_user=`who am i | cut --delimiter=' ' --fields=1`
  local pgm_spaces=" #${BASH_SUBSHELL}# "
  if [[ ${pgm_print_context} -le ${PGM_TRACELEVEL} ]]; then
    printf "[${FUNCNAME[2]}] ${pgm_spaces} ${pgm_print_text}\n"
  fi
  printf "${pgm_print_date} '${pgm_print_user}' ${pgm_spaces} [${FUNCNAME[2]}] ${pgm_print_text}\n" >> ${PGM_LOG}
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
  local pgm_function_name="${FUNCNAME[1]}"
  printTrace "Enter ${pgm_function_name} with '$*'\n"
  if [[ $# -ge 2 ]]; then
    local pgm_arg_list="$1"
    shift;
  fi

  analyzeParameters ${pgm_arg_list} $*
}

function analyzeParameters()
{
  local pgm_arg_list="$1"
  shift
  analyzeStandart $*

  for pgm_arg in ${pgm_arg_list}
  do
    case ${pgm_arg} in
      "-server-" | "+server+" | "~server~" )
        pgm_server=$1
        shift
        ;;

      "-instance-" | "+instance+" | "~instance~" )
        pgm_instance=$1
        shift
        ;;

      "-database-" | "+database+" | "~database~" )
        pgm_database=$1
        shift
        ;;

      "-request-" )
        pgm_request=$1
        shift
        ;;

      "-result-" )
        pgm_result_var=$1
        shift
        ;;

      "-port-" | "+port+" | "~port~" )
        pgm_port=$1
        shift
        ;;

      "-listener-" | "+listener+" | "~listener~" )
        pgm_listener=$1
        shift
        ;;

      "-directory-" | "+directory+" | "~directory~" )
        pgm_directory=$1
        shift
        ;;

      "-template-" | "+template+" | "~template~" )
        pgm_template=$1
        shift
        ;;

      "-filename-" | "+filename+" | "~filename~" )
        pgm_filename=$1
        shift
        ;;

      "-string-" )
        pgm_string=$1
        shift
        ;;

      "-conditional-test-" )
        pgm_conditional_test=$1
        shift
        ;;
    esac
  done
}

function analyzeStandart()
{
  for pgm_option in $*
  do
    case "${pgm_option}" in
      "-h"|"-?"|"--help")
        printf "${PGM_USAGE}\n"
        shift
        ;;

      "-v"|"--verbose"|"verbose")
        export PGM_TRACELEVEL=3
        shift
        ;;

      "-t"|"--trace"|"trace")
        export PGM_TRACELEVEL=2
        shift
        ;;

      "-e"|"--error"|"error")
        export PGM_TRACELEVEL=1
        shift
        ;;

      "-q"|"--quiet"|"--silent"|"silent")
        export PGM_TRACELEVEL=0
        shift
        ;;

      * )
        ;;
    esac
  done
}

function exitError()
{
  if [[ $# -gt 1 ]]; then
    local exitCode=$1
    shift
  else
    local exitCode=1
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

  local pgm_tpl=$1
  local pgm_dest=$2
  if [ ! -r "${pgm_tpl}" ]; then
    return 2
  fi
  if [ ! -w "$(dirname ${pgm_dest})" ]; then
    return 3
  fi

  local pgm_sed_command=""
  for pgm_var in ${!PGM_*}
  do
    if ! [[ ${!pgm_var} =~ .*[/].* ]]; then
      local pgm_sed_command="${pgm_sed_command} s/\${${pgm_var}}/${!pgm_var}/;"
    elif ! [[ ${!pgm_var} =~ .*[%].* ]]; then
      local pgm_sed_command="${pgm_sed_command} s%\${${pgm_var}}%${!pgm_var}%;"
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

function instantiateConf()
{
  declareFunction "-filename- -filename-" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgm_src=$1
  local pgm_dest=$2
  if [ ! -r "${pgm_src}" ]; then
    return 2
  fi
  if [ ! -w "$(dirname ${pgm_dest})" ]; then
    return 3
  fi

  awk '/^[[:space:]]*#[[:space:]]*EDITABLES VARIABLES/ { beginconf = 1 } 
       /^[[:space:]]*#[[:space:]]*END OF EDITABLES VARIABLES/ { beginconf = 0 }
       beginconf && /^[[:space:]]*$/ { print $0 }
       beginconf && /^[[:space:]]*#/ { print $0 }
       beginconf && /^[[:space:]]*[^#]/ { print "# "$0 }' ${pgm_src} > ${pgm_dest}
  if [[ $? -ne 0 ]]; then
    printError "Cannot generate configuration ${pgm_dest} from ${pgm_src}"
    return 4
  else
    chmod ug=rw,o= ${pgm_dest}
    if [[ $? -ne 0 ]]; then
      return 5
    fi
    printTrace "${pgm_dest} created from ${pgm_src}"
  fi
}

function ensureVars()
{
  declareFunction "-string- -conditional-test- -result-" "$*"

  local pgm_status=0
  local pgm_report=""

  if [ $# -ne 3 ]; then
    return 1
  fi
  local pgm_var_type=$1
  local pgm_condition=$2
  local pgm_result_var=$3

  local pgm_all_vars="${!PGM_*}"
  local pgm_selected_vars="$(printf ${pgm_all_vars//[ ][ ]+/$'\n'} | egrep -o PGM_.*${pgm_var_type})"
  for pgm_var in ${pgm_selected_vars}
  do
    if ! [ -z "${pgm_var}" ]; then
      local pgm_value="${!pgm_var}"
      if ! [ ${pgm_condition} "${pgm_value}" ]; then
        local pgm_report="${pgm_report} ${pgm_var}:'${pgm_value}'"
        local pgm_status=$(( ${pgm_status} + 1 ))
      fi
    fi
  done

  eval ${pgm_result_var}='${pgm_report//[ ][ ]+/ }'
  return ${pgm_status}
}

function checkEnvironment()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgm_result_var=$1
  local pgm_status=0
  local pgm_report=""

  ensureVars _DIR -d pgm_part_report
  if [[ $? -ne 0 ]]; then
    local pgm_report="${pgm_report} ${pgm_part_report}"
    local pgm_status=$(( ${pgm_status} + 1 ))
  fi

  ensureVars _CONF -w pgm_part_report
  if [[ $? -ne 0 ]]; then
    local pgm_report="${pgm_report} ${pgm_part_report}"
    local pgm_status=$(( ${pgm_status} + 1 ))
  fi

  ensureVars _LOG -w pgm_part_report
  if [[ $? -ne 0 ]]; then
    local pgm_report="${pgm_report} ${pgm_part_report}"
    local pgm_status=$(( ${pgm_status} + 1 ))
  fi

  ensureVars _EXE -x pgm_part_report
  if [[ $? -ne 0 ]]; then
    local pgm_report="${pgm_report} ${pgm_part_report}"
    local pgm_status=$(( ${pgm_status} + 1 ))
  fi

  ensureVars _INVENTORY -w pgm_part_report
  if [[ $? -ne 0 ]]; then
    local pgm_report="${pgm_report} ${pgm_part_report}"
    local pgm_status=$(( ${pgm_status} + 1 ))
  fi

  eval ${pgm_result_var}='${pgm_report//[ ][ ]+/ }'
  return ${pgm_status}
}

