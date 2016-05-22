#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

if [ "${PGB_PGBREWER_PROFILE}" == "LOADED" ]; then
  return 0
fi
export PGB_PGBREWER_PROFILE="LOADED"
export MANPATH="@MANDIR@:${MANPATH}"
export PS1="${PS1} # "

function _pgbrewer_completion()
{
  COMPREPLY=()

  local pgb_current=${COMP_WORDS[COMP_CWORD]}
  local pgb_completion=$(pgbrewer completion)

  COMPREPLY=( $(compgen -W "${pgb_completion}" -- ${pgb_current} ) )

  return 0
}

complete -F _pgbrewer_completion pgbrewer

function pgbrewer()
{
  local pgb_actions="$(@COMMANDDIR@/pgbrewer_command actions)"
  local pgb_actions="\
${pgb_actions}
default ?config?
undefault
shell ?config?"

  local pgb_actions_list=`printf "${pgb_actions}\n" | awk '{ print $1 }'`
        pgb_actions_list="${pgb_actions_list//$'\n'/ }"

  local pgb_actions_description="\
default ?config?
remember default configuration (PGB_CONFIG_NAME) so you can ommit this parameter. Will unset if no config

undefault
unset default configuration

shell  +config+
open the pgbrewer interactiv shell, allowing you yo acces command to create, install, replicate, supervise, backup...PostgreSQL databases

$(@COMMANDDIR@/pgbrewer_command usage)"


  local pgb_help="pgbrewer is a helper for human interfacing pgbrewer commands, adding and handle interface's command and redirecting other to pgbrewer_command\n\n${pgb_actions_description}"

  if [ $# -eq 0 ]; then
    if [ -v PGB_CONFIG_NAME ] && [ "${PGB_CONFIG_NAME}x" != "x" ]; then
      local pgb_action="shell"
    else
      local pgb_action="help"
    fi
  else
    local pgb_action="$1"
    shift
  fi

  case "${pgb_action}" in
    "help" )
      printf "${pgb_help}\n"
      ;;

    "usage" )
      printf "pgbrewer action [parameters]
Where actions are:
	${pgb_actions//$'\n'/$'\n'$'\t'}\n"
      ;;

    "actions" )
      printf "${pgb_actions}\n"
      ;;

    "actionlist" )
      printf "${pgb_actions_list}\n"
      ;;

    "completion" )
      local pgb_previous="${COMP_WORDS[COMP_CWORD-1]}"
      case "${pgb_previous}" in
        "pgbrewer" )
          if [[ ${COMP_CWORD} -eq 1 ]]; then
            local pgb_created_config="$(@COMMANDDIR@/pgbrewer_command list all)"
            local pgb_completion="default ${pgb_created_config//$'\n'/' '} ${pgb_actions_list}"
          else
            local pgb_completion="$(@COMMANDDIR@/pgbrewer_command completion ${COMP_CWORD} ${COMP_WORDS[@]})"
          fi
          ;;

        "help"|"usage"|"actions"|"completion")
          local pgb_completion=""
          ;;

        "default"|"shell")
          local pgb_created_config="$(@COMMANDDIR@/pgbrewer_command list all)"
          local pgb_completion="default ${pgb_created_config//$'\n'/ }"
          ;;

        *)
          local pgb_completion="$(@COMMANDDIR@/pgbrewer_command completion ${COMP_CWORD} ${COMP_WORDS[@]})"
      esac
      echo "${pgb_completion}"
      ;;

    "default" )
      if [ $# -ge 1 ]; then
        export PGB_CONFIG_NAME="$1"
      else
        unset PGB_CONFIG_NAME
      fi
      ;;

    "undefault" )
      unset PGB_CONFIG_NAME
      ;;

    "shell" )
      if [ $# -ge 1 ]; then
        export PGB_CONFIG_NAME="$1"
      fi
      unset PGB_PGBREWER_PROFILE # ensure pgbrewer ui will be loaded
      ${BASH} --init-file @UIDIR@/commands_profile
      ;;

    *)
      (@COMMANDDIR@/pgbrewer_command ${pgb_action} $*)
      ;;
  esac
}
