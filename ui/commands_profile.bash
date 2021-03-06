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

export PS1='[${PGB_CONFIG_NAME:-"default"}]-${PGS_PGSERVER_NAME:-" "}:${PGI_PGINSTANCE_NAME:-" "}:${PGD_PGDATABASE_NAME:-" "} # '
export PS2='# '

for pgb_command in @UIDIR@/*
do
  source ${pgb_command}
done

