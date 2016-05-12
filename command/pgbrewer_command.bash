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
. @CONFDIR@/pgbrewer.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/pgbrewer.include

export PGB_LOG="${PGB_LOG_DIR}/pgbrewer.log"

export PGB_ACTIONS="\
list
info +config+
check +config+
add !config!
add as +config+ !config!
configure list +config+
configure .configfilename. +config+
compare +config+ +config+
merge +config+ +config+
create +config+
remove +config+
drop -config-"

export PGB_ACTIONS_DESCRIPTION="\
list
list available ${PRGNAME} environments actives or removed

info +config+
will provide information about a environment, that is, differences from default

check +config+
will check for the environment configuration validity, missing directories or files, etc...

add !config!
add (reference) a new environment from default one, allow configuration edition

add as +config+ !config!
same as above but will inspire from first environement

configure list +config+
list available configurations, environment or commands one

configure .configfilename. +config+
edit command configuration file, could be 'pgbrewer' to edit environment configuration

compare +config+ +config+
compare two pgbrewer environments, issuing every differents parameters

merge +config+ +config+
merge first pgbrewer environment into the second one, configurations by configurations

create +config+
validate, set read only configuration, allow usage of a pgbrewer environment

remove +config+
remove environment be no deletion, listed a removed, but be empty, no database, replication, whatsoever
 
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
    getConfigurations pgb_config_list
    if [[ $? -ne 0 ]]; then
      exitError 2 "error"
    fi
    getRemovedConfigurations pgb_removed_config_list
    if [[ $? -ne 0 ]]; then
      exitError 2 "error"
    fi
    if [ "${pgb_config_list// }x" == "x" ] && [ "${pgb_removed_config_list// }x" == "x" ]; then
      printf "No config.\n"
    else
      if [ "${pgb_config_list}x" != "x" ]; then
        printf "Active configurations:\n${pgb_config_list// /$'\n'}\n"
      fi
      if [ "${pgb_removed_config_list}x" != "x" ]; then
        if [ "${pgb_config_list}x" != "x" ]; then
          printf "\n"
        fi
        printf "Removed configurations:\n${pgb_removed_config_list// /$'\n'}\n"
      fi
    fi
    ;;

  "info")
    if [ ! -d ${pgb_config} ]; then
      exitError "No config ${pgb_config}"
    fi
    for pgb_orig in ${PGB_CONF_DIR}/${pgb_config}/*.conf
    do
      printf "$(basename ${pgb_orig%\.conf})\n"
    done
    ;;

  "check")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      exitError "No config name"
    fi
    pgb_env_check="$(unset PGB_CONF && export PGB_CONFIG_NAME=${pgb_config} && . ${PGB_CONF_DIR}/pgbrewer.conf && . ${PGB_LIB_DIR}/util.include && checkEnvironment pgb_env_check; echo ${pgb_env_check})"
    if [[ $? -ne 0 ]]; then
      printError "error config ${pgb_config}:\n${pgb_env_check}"
      return 3
    fi

    export PGB_CONF
    ;;

  "add")
    if [[ $# -lt 1 ]]; then
      exitError "No config name"
    fi
    case "$1" in
      "as")
        shift
        pgb_source=$1
        shift
        if [[ $# -ge 1 ]]; then
          pgb_config=$1
        fi
        ;;

      *)
        pgb_config=$1
        shift
        pgb_source=default
        ;; 
    esac
    
    addConfig "${pgb_source}" "${pgb_config}"
    if [[ $? -ne 0 ]]; then
      exitError " problem creating ${pgb_config} from ${pgb_source}"
    else
      printTrace " ${pgb_config} created"
    fi
    ;;

  "configure")
    if [[ $# -ge 1 ]]; then
      pgb_command=$1
      shift
    else
      pgb_command=pgbrewer
    fi
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
      pgb_config_dir=${PGB_CONF_DIR}/${pgb_config}
    else
      pgb_config="default"
      pgb_config_dir=${PGB_CONF_DIR}
    fi
    if [ "${pgb_command}x" == "listx" ]; then
      if [ ! -d ${pgb_config_dir} ]; then
        exitError "No config ${pgb_config}"
      fi
      for pgb_orig in ${pgb_config_dir}/*.conf
      do
        printf "$(basename ${pgb_orig%\.conf})\n"
      done
    else
      editConfig ${pgb_config} ${pgb_command}
      if [[ $? -ne 0 ]]; then
          exitError " problem editing ${pgb_config} ${pgb_command} configuration"
      fi
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
      pgb_config=default
    else
      pgb_config=$1
      shift
    fi
    compareConfig ${pgb_source} ${pgb_config} pgb_compare_config
    if [[ $? -ne 0 ]]; then
      printf "Configurations differs:\n${pgb_compare_config}\n"
    else
      printf "Same configuration\n"
    fi
    ;;

  "merge")
    if [[ $# -lt 1 ]]; then
      exitError "${USAGE}"
    else
      pgb_source=$1
      shift
    fi
    if [[ $# -lt 1 ]]; then
      pgb_config=default
    else
      pgb_config=$1
      shift
    fi
    mergeConfig ${pgb_source} ${pgb_config}
    ;;

  "create" )
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
      pgb_config_dir=${PGB_CONF_DIR}/${pgb_config}
    else
      pgb_config="default"
      pgb_config_dir=${PGB_CONF_DIR}
    fi
    if [ -d "${pgb_config_dir}" ]; then
      createConfig ${pgb_config}
      if [[ $? -ne 0 ]]; then
        exitError " problem creating ${pgb_config}"
      else
        printTrace " ${pgb_config} created"
      fi
    else
      exitError " ${pgb_config} has to be added first"
    fi
    ;;

  "remove")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config="default"
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
      pgb_config="default"
    fi
    deleteConfig ${pgb_config}
    if [[ $? -ne 0 ]]; then
        exitError " problem destroying ${pgb_config}"
    fi
    ;;

  *) exitError "${USAGE}\n"
    ;;
esac

