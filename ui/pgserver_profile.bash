#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

if [ "${PGSERVER_PROFILE}" == "LOADED" ]; then
  return 0
fi
export PGSERVER_PROFILE="LOADED"

function _pgserver_completion()
{
  COMPREPLY=()

  local pgb_current=${COMP_WORDS[COMP_CWORD]}
  local pgb_completion=$(pgbrewer completion)

  COMPREPLY=( $(compgen -W "${pgb_completion}" -- ${pgb_current} ) )

  return 0
}

complete -F _pgserver_completion pgserver

function pgserver()
{
  local pgb_actions="$(@COMMANDDIR@/pgserver_command actions)"
  local pgb_actions="\
help
usage
actions
default ?server?
undefault
${pgb_actions}"

  local pgb_actions_description="\
help
explain you how this works

usage
will provide this text:)

actions
list all possible actions and parameters with this command

default ?config?
remember default server (PGBSRV_NAME) so you can ommit this parameter. Will unset if no config

undefault
unset default configuration

$(@COMMANDDIR@/pgserver_command usage)"


  local pgb_help="pgserver is a helper for human interfacing PostgreSQL server management, adding and handle interface's command and redirecting other to pgserver_command\n\n${pgb_actions_description}"

  if [ $# -eq 0 ]; then
    local pgb_action="help"
  else
    local pgb_action="$1"
    shift
  fi

  case "${pgb_action}" in
    "help" )
      printf "${pgb_help}\n"
      ;;

    "usage" )
      printf "pgserver action [parameters]
Where actions are:
${pgb_actions//$'\n'/$'\n'$'\t'}\n"
      ;;

    "actions" )
      printf "${pgb_actions}\n"
      ;;

    "default" )
      if [ $# -ge 1 ]; then
        export PGB_PGSRV_NAME="$1"
      else
        unset PGB_PGSRV_NAME
      fi
      ;;

    "undefault" )
      unset PGB_PGSRV_NAME
      ;;

    *)
      @COMMANDDIR@/pgserver_command ${pgb_action} $*
      ;;
  esac
}

