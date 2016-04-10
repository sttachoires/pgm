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
. @CONFDIR@/pgm.conf
. ${PGM_LIB_DIR}/util.include
. ${PGM_LIB_DIR}/pgm.include

export PGM_LOG="${PGM_LOG_DIR}/pgm.log"

export PGM_ACTIONS="\
help
list
info ~config~
check ~config~
add +config+
add as -config- +config+
configure list ~config~
configure -command- ~config~
compare ~config~ ~config~
merge ~config~ ~config~
create ~config~
remove -config-
drop -config-
set .config.
unset
shell ~config~"

export PGM_SHORT_DESCRIPTION="\
pgm command will help handle environments configuration, with, potentialy,
differents directory, instances configuration, security..."

export PGM_LONG_DESCRIPTION="\
${PGM_SHORT_DESCRIPTION}

${PGM_GENERAL_PHILOSOPHY_DESCRIPTION}
Philosophy is that last -config- argument can be ommited if set in environment.
So issue 'pgm create' after 'pgm set dev' is the same as issue 'pgm create dev'
Actions:
help
will provide this text:)

list
list available ${PRGNAME} environments actives or removed

info ~config~
will provide information about a environment, that is, differences from default

check ~config~
will check for the environment configuration validity, missing directories or files, etc...

add +config+
add (reference) a new environment from default one, allow configuration edition

add as -config- +config+
same as above but will inspire from first environement

configure list ~config~
list available configurations, environment or commands one

configure -command- ~config~
edit command configuration file, could be 'pgm' to edit environment configuration

compare ~config~ ~config~
compare two pgm environments, issuing every differents parameters

merge ~config~ ~config~
merge first pgm environment into the second one, configurations by configurations

create ~config~
validate, set read only configuration, allow usage of a pgm environment

remove -config-
remove environment be no deletion, listed a removed, but be empty, no database, replication, whatsoever
 
drop -config-
perform actual environment removal by deletion

set .config.
set default environment to 'config', if last 'config' parameter is ommited, this value will be used

unset
unset default environment
shell ~config~
open the pgm interactiv shell, allowing you yo acces command to create, install, replicate, supervise, backup...PostgreSQL databases
"

export PGM_USAGE="\
${PGM_GENERAL_SHORT_DESCRIPTION}

${PRGNAME}
Description:
${PGM_SHORT_DESCRIPTION}
${PRGNAME} action [parameters]
Where actions are:
${PGM_ACTIONS//$'\n'/$'\n'$'\t'}"

export PGM_HELP="\
${PGM_GENERAL_SHORT_DESCRIPTION}
${PGM_LONG_DESCRIPTION}
"

analyzeStandart $*

if [[ $# -gt 0 ]]; then
  pgm_action=$1
  shift
else
  exitError 1 "No action\n${PGM_USAGE}"
fi

case "${pgm_action}" in
  "help")
    printf "${PGM_HELP}\n"
    ;;

  "list")
    getConfigurations pgm_config_list
    if [[ $? -ne 0 ]]; then
      exitError 2 "error"
    fi
    getRemovedConfigurations pgm_removed_config_list
    if [[ $? -ne 0 ]]; then
      exitError 2 "error"
    fi
    if [ "${pgm_config_list// }x" == "x" ] && [ "${pgm_removed_config_list// }x" == "x" ]; then
      printf "No config.\n"
    else
      if [ "${pgm_config_list}x" != "x" ]; then
        printf "Active configurations:\n${pgm_config_list// /$'\n'}\n"
      fi
      if [ "${pgm_removed_config_list}x" != "x" ]; then
        printf "Removed configurations:\n${pgm_removed_config_list// /$'\n'}\n"
      fi
    fi
    ;;

  "info")
    if [ ! -d ${pgm_config} ]; then
      exitError "No config ${pgm_config}"
    fi
    for pgm_orig in ${PGM_CONF_DIR}/${pgm_config}/*.conf
    do
      printf "$(basename ${pgm_orig%\.conf})\n"
    done
    ;;

  "check")
    if [[ $# -ge 1 ]]; then
      pgm_config=$1
      shift
    else
      exitError "No config name"
    fi
    pgm_env_check="$(unset PGM_CONF && export PGM_CONFIG_NAME=${pgm_config} && . ${PGM_CONF_DIR}/pgm.conf && . ${PGM_LIB_DIR}/util.include && checkEnvironment pgm_env_check; echo ${pgm_env_check})"
    if [[ $? -ne 0 ]]; then
      printError "error config ${pgm_config}:\n${pgm_env_check}"
      return 3
    fi

    export PGM_CONF
    ;;

  "add")
    if [[ $# -lt 1 ]]; then
      exitError "No config name"
    fi
    case "$1" in
      "as")
        shift
        pgm_source=$1
        shift
        if [[ $# -ge 1 ]]; then
          pgm_config=$1
        fi
        ;;

      *)
        pgm_config=$1
        shift
        pgm_source=default
        ;; 
    esac
    
    addConfig "${pgm_source}" "${pgm_config}"
    if [[ $? -ne 0 ]]; then
      exitError " problem creating ${pgm_config} from ${pgm_source}"
    else
      printTrace " ${pgm_config} created"
    fi
    ;;

  "configure")
    if [[ $# -ge 1 ]]; then
      pgm_command=$1
      shift
    else
      pgm_command=pgm
    fi
    if [[ $# -ge 1 ]]; then
      pgm_config=$1
      shift
      pgm_config_dir=${PGM_CONF_DIR}/${pgm_config}
    else
      pgm_config="default"
      pgm_config_dir=${PGM_CONF_DIR}
    fi
    if [ "${pgm_command}x" == "listx" ]; then
      if [ ! -d ${pgm_config_dir} ]; then
        exitError "No config ${pgm_config}"
      fi
      for pgm_orig in ${pgm_config_dir}/*.conf
      do
        printf "$(basename ${pgm_orig%\.conf})\n"
      done
    else
      editConfig ${pgm_config} ${pgm_command}
      if [[ $? -ne 0 ]]; then
          exitError " problem editing ${pgm_config} ${pgm_command} configuration"
      fi
    fi
    ;;

  "compare")
    if [[ $# -lt 1 ]]; then
      exitError "${USAGE}"
    else
      pgm_source=$1
      shift
    fi
    if [[ $# -lt 1 ]]; then
      pgm_config=default
    else
      pgm_config=$1
      shift
    fi
    compareConfig ${pgm_source} ${pgm_config} pgm_compare_config
    if [[ $? -ne 0 ]]; then
      printf "Configurations differs:\n${pgm_compare_config}\n"
    else
      printf "Same configuration\n"
    fi
    ;;

  "merge")
    if [[ $# -lt 1 ]]; then
      exitError "${USAGE}"
    else
      pgm_source=$1
      shift
    fi
    if [[ $# -lt 1 ]]; then
      pgm_config=default
    else
      pgm_config=$1
      shift
    fi
    mergeConfig ${pgm_source} ${pgm_config}
    ;;

  "create" )
    if [[ $# -ge 1 ]]; then
      pgm_config=$1
      shift
      pgm_config_dir=${PGM_CONF_DIR}/${pgm_config}
    else
      pgm_config="default"
      pgm_config_dir=${PGM_CONF_DIR}
    fi
    if [ -d "${pgm_config_dir}" ]; then
      createConfig ${pgm_config}
      if [[ $? -ne 0 ]]; then
        exitError " problem creating ${pgm_config}"
      else
        printTrace " ${pgm_config} created"
      fi
    else
      exitError " ${pgm_config} has to be added first"
    fi
    ;;

  "remove")
    if [[ $# -ge 1 ]]; then
      pgm_config=$1
      shift
    else
      pgm_config="default"
    fi
    removeConfig ${pgm_config}
    if [[ $? -ne 0 ]]; then
        exitError " problem removing ${pgm_config}"
    fi
    ;;

  "drop")
    if [[ $# -ge 1 ]]; then
      pgm_config=$1
      shift
    else
      pgm_config="default"
    fi
    deleteConfig ${pgm_config}
    if [[ $? -ne 0 ]]; then
        exitError " problem destroying ${pgm_config}"
    fi
    ;;

  "set")
    if [[  $# -ge 1 ]]; then
      pgm_config=$1
      shift
    else
      pgm_config="default"
    fi

    export PGM_CONF_NAME=${pgm_config}
    ;;

  "unset")
    unset PGM_CONF_NAME
    ;;

  "shell")
    ;;

  *) exitError "${USAGE}\n"
    ;;
esac

