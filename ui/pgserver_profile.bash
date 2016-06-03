#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

if [ "${PGS_PGSERVER_PROFILE}" == "LOADED" ]; then
  return 0
fi
export PGS_PGSERVER_PROFILE="LOADED"

declare -xf _pgserver_completion
function _pgserver_completion()
{
  COMPREPLY=()

  local pgs_current=${COMP_WORDS[COMP_CWORD]}
  local pgs_completion=$(pgserver completion)

  COMPREPLY=( $(compgen -W "${pgs_completion}" -- ${pgs_current} ) )

  return 0
}

complete -F _pgserver_completion pgserver

declare -xf pgserver
function pgserver()
{
  local pgs_actions="$(@COMMANDDIR@/pgserver_command actions)"
  local pgs_actions="\
help
usage
actions
default ?server?
getdefault
set ?server?
unset
${pgs_actions}"

  local pgs_actions_list=`printf "${pgs_actions}\n" | awk '{ print $1 }'`
        pgs_actions_list="${pgs_actions_list//$'\n'/ }"

  local pgs_actions_description="\
help
explain you how this works

usage
will provide this text:)

actions
list all possible actions and parameters with this command

default ?config?
remember default server so you can ommit this parameter. Will unset if no config

default ?config?
remember default server (PGBSRV_NAME) so you can ommit this parameter. Will unset if no config

default ?config?
remember default server (PGBSRV_NAME) so you can ommit this parameter. Will unset if no config

undefault
unset default configuration

$(@COMMANDDIR@/pgserver_command usage)"


  local pgs_help="pgserver is a helper for human interfacing PostgreSQL server management, adding and handle interface's command and redirecting other to pgserver_command\n\n${pgs_actions_description}"

  if [ $# -eq 0 ]; then
    local pgs_action="help"
  else
    local pgs_action="$1"
    shift
  fi

  case "${pgs_action}" in
    "help" )
      printf "${pgs_help}\n"
      ;;

    "usage" )
      printf "pgserver action [parameters]
Where actions are:
${pgs_actions//$'\n'/$'\n'$'\t'}\n"
      ;;

    "actions" )
      printf "${pgs_actions}\n"
      ;;

    "actionlist" )
      printf "${pgs_actions_list}\n"
      ;;

    "completion" )
      local pgs_previous="${COMP_WORDS[COMP_CWORD-1]}"
      case "${pgs_previous}" in
        "pgserver" )
          if [[ ${COMP_CWORD} -eq 1 ]]; then
            local pgs_completion="${pgs_actions_list}"
          else
            local pgs_completion="$(@COMMANDDIR@/pgserver_command completion ${COMP_CWORD} ${COMP_WORDS[@]})"
          fi
          ;;

        "help"|"usage"|"actions"|"completion")
          local pgs_completion=""
          ;;

        "default"|"shell")
          local pgs_created_server="$(@COMMANDDIR@/pgserver_command list all)"
          local pgs_completion="default ${pgs_created_config//$'\n'/ }"
          ;;

        *)
          local pgs_completion="$(@COMMANDDIR@/pgserver_command completion ${COMP_CWORD} ${COMP_WORDS[@]})"
      esac
      echo "${pgs_completion}"
      ;;


    "default" )
      if [ $# -ge 1 ]; then
        export PGS_SERVER_NAME="$1"
      else
        unset PGS_SERVER_NAME
      fi
      ;;

    "undefault" )
      unset PGS_SERVER_NAME
      ;;

    *)
      @COMMANDDIR@/pgserver_command ${pgs_action} $*
      ;;
  esac
}

