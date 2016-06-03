#! @BASH@
# 
# Bash library for PGBrewer scripts
#
# S. Tachoires		19/02/2016	Initial version
#
#set -xv
if [ "${PGB_UTIL_INCLUDE}" == "LOADED" ]; then
  return
fi
export PGB_UTIL_INCLUDE="LOADED"

# CONSTANTS
PGB_LOG="default.log"

# VARIABLES
export PGB_TRACELEVEL=1

declare -xf pgbPrint
function pgbPrint()
{
  if [[ $# -ne 2 ]]; then
    return 1
  fi
  local pgb_print_context="$1"
  local pgb_print_text="$2"
  local pgb_print_date=`date "+%Y.%m.%d-%H.%M.%S"`
  local pgb_print_user=`who am i | cut --delimiter=' ' --fields=1`
  local pgb_spaces=" #${BASH_SUBSHELL}# "
  if [[ ${pgb_print_context} -le ${PGB_TRACELEVEL} ]]; then
    printf "[${FUNCNAME[2]}] ${pgb_spaces} ${pgb_print_text}\n"
  fi
  printf "${pgb_print_date} '${pgb_print_user}' ${pgb_spaces} [${FUNCNAME[2]}] ${pgb_print_text}\n" >> ${PGB_LOG}
}

declare -xf printError
function printError()
{
  pgbPrint 1 "$*"
}

declare -xf printTrace
function printTrace()
{
  pgbPrint 2 "$*"
}

declare -xf printInfo
function printInfo()
{
  pgbPrint 3 "$*"
}

declare -xf declareFunction
function declareFunction()
{
  local pgb_function_name="${FUNCNAME[1]}"
  export -f ${pgb_function_name}
  printTrace "Enter ${pgb_function_name} with '$*'\n"
  if [[ $# -ge 2 ]]; then
    local pgb_arg_list="$1"
    shift;
  fi
}

declare -xf analyzeParameters
function analyzeParameters()
{
  local pgb_arg_list="$1"
  shift
  analyzeStandart $*

  for pgb_arg in ${pgb_arg_list}
  do
    local pgb_arg_name=""
    local pgb_arg_constraint=""

    case ${pgb_arg} in
      "[.]..*[.]")
        pgb_arg_constraint="EXISTS"
        pgb_arg_name=${pgb_arg#-}
        pgb_arg_name=${pgb_arg_name%-}
        ;;

      "[!]..*[!]")
        pgb_arg_constraint="NOTEXISTS"
        pgb_arg_name=${pgb_arg#+}
        pgb_arg_name=${pgb_arg_name%+}
        ;;

      "[+]..*[+]")
        pgb_arg_constraint="ADDED"
        pgb_arg_name=${pgb_arg#~}
        pgb_arg_name=${pgb_arg_name%~}
        ;;

      "[?]..*[?]")
        pgb_arg_constraint="CORRECT"
        pgb_arg_name=${pgb_arg#\.}
        pgb_arg_name=${pgb_arg_name%\.}
        ;;

      "[-]..*[-]")
        pgb_arg_constraint="NOCHECK"
        pgb_arg_name=${pgb_arg#\.}
        pgb_arg_name=${pgb_arg_name%\.}
        ;;

    esac

    case ${pgb_arg_name} in
      "result" )
        pgb_result_var=$1
        shift
        ;;

      *)
        eval local pgb_arg_num_name='pgb_${pgb_arg_name}_num'
        eval local pgb_${pgb_arg_name}_num=$(( pgb_${pgb_arg_name}_num++ ))
        eval local pgb_arg_var_name='pgb_${pgb_arg_name}'

        case ${!pgb_arg_num_name} in
          1)
            eval ${pgb_arg_var_name}='$1'
            ;;

          2)
            eval ${pgb_arg_var_name}_1='${!pgb_arg_var_name}'
            eval unset ${pgb_arg_var_name}
            eval ${pgb_arg_var_name}_2='$1'
            ;;

          *)
            eval ${pgb_arg_var_name}_${!pgb_arg_num_name}='$1'
            ;;
        esac
        shift
        ;;
    esac
  done
}

declare -xf analyzeStandart
function analyzeStandart()
{
  for pgb_option in $*
  do
    case "${pgb_option}" in
      "-h"|"-?"|"--help")
        printf "${PGB_USAGE}\n"
        shift
        ;;

      "-v"|"--verbose"|"verbose")
        export PGB_TRACELEVEL=3
        shift
        ;;

      "-t"|"--trace"|"trace")
        export PGB_TRACELEVEL=2
        shift
        ;;

      "-e"|"--error"|"error")
        export PGB_TRACELEVEL=1
        shift
        ;;

      "-q"|"--quiet"|"--silent"|"silent")
        export PGB_TRACELEVEL=0
        shift
        ;;

      * )
        ;;
    esac
  done
}
declare -xf analyzeStandart

declare -xf exitError
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
declare -xf exitError

declare -xf instantiateTemplate
function instantiateTemplate()
{
  declareFunction ".template. !filename!" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_tpl=$1
  local pgb_dest=$2
  if [ ! -r "${pgb_tpl}" ]; then
    return 2
  fi
  if [ ! -w "$(dirname ${pgb_dest})" ]; then
    return 3
  fi

  local pgb_sed_command=""
  for pgb_var in ${!PGB_*}
  do
    if ! [[ ${!pgb_var} =~ .*[/].* ]]; then
      local pgb_sed_command="${pgb_sed_command} s/\${${pgb_var}}/${!pgb_var}/;"
    elif ! [[ ${!pgb_var} =~ .*[%].* ]]; then
      local pgb_sed_command="${pgb_sed_command} s%\${${pgb_var}}%${!pgb_var}%;"
    fi
  done
  
  if [ -e "${pgb_dest}" ]; then
    cp ${pgb_dest} ${pgb_dest}.orig
    if [[ $? -ne 0 ]]; then
      return 4
    fi
  fi
  sed "${pgb_sed_command}" ${pgb_tpl} > ${pgb_dest}
  if [[ $? -ne 0 ]]; then
    return 5
  fi
}

declare -xf initiateConf
function initiateConf()
{
  declareFunction ".confname. !filename!" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_src=$1
  local pgb_dest=$2
  if [ ! -r "${pgb_src}" ]; then
    return 2
  fi
  if [ ! -w "$(dirname ${pgb_dest})" ]; then
    return 3
  fi

  awk '/^[[:space:]]*#[[:space:]]*EDITABLES VARIABLES/ { beginconf = 1 } 
       /^[[:space:]]*#[[:space:]]*END OF EDITABLES VARIABLES/ { beginconf = 0 }
       beginconf && /^[[:space:]]*$/ { print $0 }
       beginconf && /^[[:space:]]*#/ { print $0 }
       beginconf && /^[[:space:]]*[^#]/ { print "# "$0 }' ${pgb_src} > ${pgb_dest}
  if [[ $? -ne 0 ]]; then
    printError "Cannot initiate configuration ${pgb_dest} from ${pgb_src}"
    return 4
  else
    chmod ug=rw,o= ${pgb_dest}
    if [[ $? -ne 0 ]]; then
      return 5
    fi
    printTrace "${pgb_dest} created from ${pgb_src}"
  fi
}

declare -xf copyConf
function copyConf()
{
  declareFunction ".confname. !filename!" "$*"

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  local pgb_src=$1
  local pgb_dest=$2
  if [ ! -r "${pgb_src}" ]; then
    return 2
  fi
  if [ ! -w "$(dirname ${pgb_dest})" ]; then
    return 3
  fi

  awk '/^[[:space:]]*#[[:space:]]*EDITABLES VARIABLES/ { beginconf = 1 } 
       /^[[:space:]]*#[[:space:]]*END OF EDITABLES VARIABLES/ { beginconf = 0 }
       beginconf { print $0 }' ${pgb_src} > ${pgb_dest}
  if [[ $? -ne 0 ]]; then
    printError "Cannot copy configuration ${pgb_dest} from ${pgb_src}"
    return 4
  else
    chmod ug=rw,o= ${pgb_dest}
    if [[ $? -ne 0 ]]; then
      return 5
    fi
    printTrace "${pgb_dest} created from ${pgb_src}"
  fi
}

declare -xf ensureVars
function ensureVars()
{
  declareFunction "-string- -conditional-test- -result-" "$*"

  local pgb_status=0
  local pgb_report=""

  if [ $# -ne 3 ]; then
    return 1
  fi
  local pgb_var_type=$1
  local pgb_condition=$2
  local pgb_result_var=$3

  local pgb_all_vars="${!PGB_*}"
  local pgb_selected_vars="$(printf ${pgb_all_vars//[ ][ ]+/$'\n'} | egrep -o PGB_.*${pgb_var_type})"
  for pgb_var in ${pgb_selected_vars}
  do
    if ! [ -z "${pgb_var}" ]; then
      local pgb_value="${!pgb_var}"
      if ! [ ${pgb_condition} "${pgb_value}" ]; then
        local pgb_report="${pgb_report} ${pgb_var}:'${pgb_value}'"
        local pgb_status=$(( ${pgb_status} + 1 ))
      fi
    fi
  done

  eval ${pgb_result_var}='${pgb_report//[ ][ ]+/ }'
  return ${pgb_status}
}

declare -xf checkEnvironment
function checkEnvironment()
{
  declareFunction "-result-" "$*"

  if [[ $# -ne 1 ]]; then
    return 1
  fi
  local pgb_result_var=$1
  local pgb_status=0
  local pgb_report=""

  ensureVars _DIR -d pgb_part_report
  if [[ $? -ne 0 ]]; then
    local pgb_report="${pgb_report} ${pgb_part_report}"
    local pgb_status=$(( ${pgb_status} + 1 ))
  fi

  ensureVars _CONF -w pgb_part_report
  if [[ $? -ne 0 ]]; then
    local pgb_report="${pgb_report} ${pgb_part_report}"
    local pgb_status=$(( ${pgb_status} + 1 ))
  fi

  ensureVars _LOG -w pgb_part_report
  if [[ $? -ne 0 ]]; then
    local pgb_report="${pgb_report} ${pgb_part_report}"
    local pgb_status=$(( ${pgb_status} + 1 ))
  fi

  ensureVars _EXE -x pgb_part_report
  if [[ $? -ne 0 ]]; then
    local pgb_report="${pgb_report} ${pgb_part_report}"
    local pgb_status=$(( ${pgb_status} + 1 ))
  fi

  ensureVars _INVENTORY -w pgb_part_report
  if [[ $? -ne 0 ]]; then
    local pgb_report="${pgb_report} ${pgb_part_report}"
    local pgb_status=$(( ${pgb_status} + 1 ))
  fi

  eval ${pgb_result_var}='${pgb_report//[ ][ ]+/ }'
  return ${pgb_status}
}

