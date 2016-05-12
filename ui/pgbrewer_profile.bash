#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

if [ "${PGBREWER_PROFILE}" == "LOADED" ]; then
  return 0
fi
export PGBREWER_PROFILE="LOADED"
export MANPATH="@MANDIR@:${MANPATH}"
export PS1="${PS1} # "

function _pgbrewer_completion()
{
  COMPREPLY=()

  local pgb_current="${COMP_WORDS[COMP_CWORD]}"
  local pgb_previous="${COMP_WORDS[COMP_CWORD-1]}"
  local pgb_actions="$(pgbrewer actions)"

  if [ "${pgb_previous}x" == "pgbrewerx" ]; then
    local pgb_completion=$(printf "${pgb_actions}" | awk '{ print $1 }')
    COMPREPLY=( $(compgen -W "${pgb_completion//$'\n'/ }" -- ${pgb_current} ) )
  else
    local pgb_line=$(printf "${pgb_actions}" | grep ^${pgb_previous})
    local pgb_completion=$(printf "${pgb_line}" | awk '{ print $2 }')
  fi
  return 0
}

complete -F _pgbrewer_completion pgbrewer

function pgbrewer()
{
  local pgb_actions="$(@COMMANDDIR@/pgbrewer_command actions)"
  local pgb_actions="\
help
usage
actions
default ?config?
undefault
shell ?config?
${pgb_actions}"

  local pgb_actions_description="\
help
explain you how this works

usage
will provide this text:)

actions
list all possible actions and parameters with this command

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
      local pgb_action="shell ${PGB_CONFIG_NAME}"
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
      ${BASH} --init-file @UIDIR@/commands_profile
      ;;

    *)
      @COMMANDDIR@/pgbrewer_command ${pgb_action} $* ${PGB_CONFIG_NAME}
      ;;
  esac
}
