#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

export MANPATH="@MANDIR@:${MANPATH}"

function _pgm_completion()
{
  local pgm_current
  local pgm_previous
  local pgm_options

  COMPREPLY=()

  pgm_current="${COMP_WORDS[COMP_CWORD]}"
  pgm_previous="${COMP_WORDS[COMP_CWORD-1]}"
  pgm_options="help list info check add configure compare merge create remove drop set unset shell"

  if [ ${pgm_current} == "" ]; then
    COMPREPLY=( $(compgen -W "${pgm_options}" -- ${pgm_current}) )
    return 0
  fi
}

complete -F _pgm_completion pgm

function pgm()
{
  case $# in
    0)
      if [ -v PGM_CONFIG_NAME ] && [ "${PGM_CONFIG_NAME}x" != "x" ]; then
        @COMMANDDIR@/pgm_command shell ${PGM_CONFIG_NAME}
      fi
      ;;

    *)
      if [ "${1}x" == "setx" ]; then
        shift
        if [ $# -ge 1 ]; then
          export PGM_CONFIG_NAME="$1"
        else
          unset PGM_CONFIG_NAME
        fi
      elif [ "${1}x" == "unsetx" ]; then
        unset PGM_CONFIG_NAME
      else
        @COMMANDDIR@/pgm_command $*
      fi
      ;;
  esac
}
