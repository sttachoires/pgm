#! @BASH@
#
# Control PostgreSQL database instance.
# start, stop, reload, restart, monitor, clean.
#
# S. Tachoires          20/02/2016      Initial version
#
#set -xv

if [ "${COMMANDS_PROFILE}" == "LOADED" ]; then
  return 0
fi
export COMMANDS_PROFILE="LOADED"

export PS1='[${PGB_CONFIG_NAME:-"default"}]-${PGB_PGFULL_VERSION:-"..."}:${PGB_PGINSTANCE:-"..."}:${PGB_DATABASE:-"..."} # '
export PS2='# '

source @UIDIR@/*

