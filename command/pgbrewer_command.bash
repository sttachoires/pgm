#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

# CONSTANTS
PRGNAME=$(basename $0 2> /dev/null)
if [[ $? -ne 0 ]]; then
  PRGNAME="Unknown"
fi


# INCLUDE
. @CONFDIR@/default/pgbrewer.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/pgbrewer.include

export PGB_LOG="${PGB_LOG_DIR}/pgbrewer.log"

export PGB_ACTIONS="\
list
default +config+
command +config+
info +config+
check +config+
add !config!
add as +config+ !config!
configure +config+
compare +config+ +config+
create +config+
remove +config+
drop -config-"

export PGB_ACTIONS_DESCRIPTION="\
list
list available ${PRGNAME} environments actives or removed

default +config+
change default config

command +config+
list available commands for config

info +config+
will provide information about a environment

check +config+
will check for the environment configuration validity, missing directories or files, etc...

add !config!
add (reference) a new environment from default one, allow configuration edition

add as +config+ !config!
same as above but will inspire from first environement

configure +config+
edit command configuration file

compare +config+ +config+
compare two pgbrewer environments, issuing every differents parameters

create +config+
validate, set read only configuration.

remove +config+
uncreate environment, set read/write.
 
drop -config-
perform actual environment removal by deletion
"

export PGB_SHORT_DESCRIPTION="\
pgbrewer command will help handle environments configuration, with, potentialy,
differents directory, instances configuration, security..."

export PGB_LONG_DESCRIPTION="\
${PGB_SHORT_DESCRIPTION}

${PGB_GENERAL_PHILOSOPHY_DESCRIPTION}
Actions:\n${PGB_ACTIONS_DESCRIPTION}"

export PGB_USAGE="\
${PGB_GENERAL_SHORT_DESCRIPTION}

${PRGNAME}
Description:
${PGB_SHORT_DESCRIPTION}
${PRGNAME} action [parameters]
Where actions are:
${PGB_ACTIONS//$'\n'/$'\n'$'\t'}"

export PGB_HELP="\
${PGB_GENERAL_SHORT_DESCRIPTION}
${PGB_LONG_DESCRIPTION}
"

analyzeStandart $*

if [[ $# -gt 0 ]]; then
  pgb_action=$1
  shift
else
  exitError 1 "No action\n${PGB_USAGE}"
fi

case "${pgb_action}" in
  "completion")
    if [[ $# -ge 1 ]]; then
      pgb_comp_cword=$1
      shift
    else
      pgb_comp_cword=0
    fi

    pgb_var_name="pgb_previous"
    for ((; ${pgb_comp_cword} > 0; pgb_comp_cword-- ))
    do
      eval ${pgb_var_name}=${!pgb_comp_cword}
      pgb_var_name="${pgb_var_name}_previous"
    done
    pgb_completion=""
    # correct case of command to configure is same as current
    if [ "${pgb_previous}x" == "pgbrewerx" ] && [[ ${pgb_comp_cword} -ne 1 ]]; then
      pgb_previous="pgb_previous"
    fi
    case "${pgb_previous}" in
      "pgbrewer" )
        pgb_completion=`printf "${PGB_ACTIONS}\n" | awk '{ print $1 }'`
        pgb_completion="${pgb_completion//$'\n'/' '}"
        ;;

      "actions"|"usage"|"help")
        pgb_completion=""
        ;;

      "info"|"command"|"configure"|"check"|"create"|"remove"|"drop"|"compare"|"default")
        getAllConfigurations pgb_config_list
        pgb_completion="${pgb_config_list//$'\n'/' '}"
        ;;

      "add")
        pgb_completion="as NAME"
        ;;

      "list")
        pgb_completion="all NOTHING"
        ;;

      "as")
        if [ "${pgb_previous_previous}x" == "addx" ]; then
          getAllConfigurations pgb_config_list
          pgb_completion="${pgb_config_list//$'\n'/' '}"
        else
          pgb_completion=""
        fi
        ;;

      *)
        if [ "${pgb_previous_previous}x" == "comparex" ]; then
          getAllConfigurations pgb_config_list
          pgb_completion="${pgb_config_list//$'\n'/' '}"
        elif [ "${pgb_previous_previous}x" == "asx" ]; then
          pgb_completion="NAME"
        else
          pgb_completion=""
        fi
        ;;
    esac
    echo "${pgb_completion}"
    ;;

  "actions")
    printf "${PGB_ACTIONS}\n"
    ;;

  "usage")
    printf "${PGB_ACTIONS_DESCRIPTION}\n"
    ;;

  "help")
    printf "${PGB_HELP}\n"
    ;;

  "list")
    if [[ $# -ge 1 ]]; then
      if [ "${1}x" == "allx" ]; then
        getAllConfigurations pgb_config_list
        if [[ $? -ne 0 ]]; then
          exitError 2 "error"
        fi
        printf "${pgb_config_list// /$'\n'}\n"
      fi
    else
      getCreatedConfigurations pgb_created_config_list
      if [[ $? -ne 0 ]]; then
        exitError 2 "error"
      fi 
      getAddedConfigurations pgb_added_config_list
      if [[ $? -ne 0 ]]; then
        exitError 2 "error"
      fi
      if [ "${pgb_created_config_list// }x" == "x" ] && [ "${pgb_added_config_list// }x" == "x" ]; then
        printf "No config.\n"
      else
        if [ "${pgb_created_config_list// }x" != "x" ]; then
          printf "Created configurations:\n${pgb_created_config_list// /$'\n'}\n"
          if [ "${pgb_added_config_list// }x" != "x" ]; then
            printf "\n"
          fi
        fi
        if [ "${pgb_added_config_list// }x" != "x" ]; then
          printf "Added configurations:\n${pgb_added_config_list// /$'\n'}\n"
        fi
      fi
    fi
    ;;

  "default")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    setDefault ${pgb_config}
    ;;

  "command")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    getCommands ${pgb_config} pgb_command_list

    if [ "${pgb_command_list}x" == "x" ]; then
      printf "No command for ${pgb_config}"
    else
      printf "${pgb_command_list}\n"
    fi
    ;;

  "info")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    getConfigVars ${pgb_config} pgb_vars_list
    printf "${pgb_vars_list}\n"
    ;;

  "check")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    if [ ! -d ${PGB_CONF_DIR}/${pgb_config} ]; then
      exitError "No config ${pgb_config}"
    fi
    ;;

  "add")
    if [[ $# -eq 0 ]]; then
      pgb_config=${PGB_CONFIG_NAME:-default}
      pgb_source=default
    elif [[ $# -eq 1 ]]; then
      if [ "${1}x" == "asx" ]; then
          shift
          pgb_config=${PGB_CONFIG_NAME:-default}
          pgb_source=default
      else
        if [ "${PGB_CONFIG_NAME}x" == "x" ] || [ "${PGB_CONFIG_NAME}x" == "defaultx" ]; then
          pgb_config=$1
          pgb_source=default
        else
          pgb_config=${PGB_CONFIG_NAME}
          pgb_source=$1
        fi
        shift
      fi
    elif [[ $# -eq 2 ]]; then
      if [ "${1}x" == "asx" ]; then
        shift
        if [ "${PGB_CONFIG_NAME}x" == "x" ] || [ "${PGB_CONFIG_NAME}x" == "defaultx" ]; then
          pgb_config=$1
          pgb_source=default
        else
          pgb_config=${PGB_CONFIG_NAME}
          pgb_source=$1
        fi
        shift
      else
        pgb_source=$1
        shift
        pgb_config=$1
        shift
      fi
    else
      if [ "${1}x" == "asx" ]; then
        shift
        pgb_source=$1
        shift
        pgb_config=$1
        shift
      else
        exitError "${USAGE}\n"
      fi
    fi

    if [ "${pgb_config}x" == "defaultx" ]; then
      exitError 3 "${USAGE}\n"
    fi
    addConfig "${pgb_source}" "${pgb_config}"
    if [[ $? -ne 0 ]]; then
      exitError " problem creating ${pgb_config} from ${pgb_source}"
    else
      printTrace " ${pgb_config} created"
    fi
    ;;

  "configure")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config="${PGB_CONFIG_NAME:-default}"
    fi

    editConfig ${pgb_config} 
    if [[ $? -ne 0 ]]; then
      exitError " problem editing ${pgb_config} configuration"
    fi
    ;;

  "compare")
    if [[ $# -lt 1 ]]; then
      exitError "${USAGE}"
    else
      pgb_source=$1
      shift
    fi
    if [[ $# -lt 1 ]]; then
      pgb_config=${PGB_CONFIG_NAME:-default}
    else
      pgb_config=$1
      shift
    fi
    compareConfig ${pgb_source} ${pgb_config} pgb_compare_config
    if [ "${pgb_compare_config}x" != "x" ]; then
      printf "Configurations differs:\n${pgb_compare_config}\n"
    else
      printf "Same configuration\n"
    fi
    ;;

  "create" )
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    
    createConfig ${pgb_config}
    if [[ $? -ne 0 ]]; then
      exitError " problem creating ${pgb_config}"
    else
      printTrace " ${pgb_config} created"
    fi
    ;;

  "remove")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    removeConfig ${pgb_config}
    if [[ $? -ne 0 ]]; then
        exitError " problem removing ${pgb_config}"
    fi
    ;;

  "drop")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    deleteConfig ${pgb_config}
    if [[ $? -ne 0 ]]; then
        exitError " problem destroying ${pgb_config}"
    fi
    ;;

  *) exitError "${USAGE}\n"
    ;;
esac

