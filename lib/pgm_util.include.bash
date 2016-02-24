#! @BASH@
# 
# Bash library for PGM scripts
#
# S. Tachoires		19/02/2016	Initial version
#
#set -xv
if [ "${PGM_UTIL_INCLUDE}" == "LOADED" ]; then
  return
fi

# CONSTANTS

# VARIABLES
function printError()
{
  printf "$*"
  return 1
}

function exitError()
{
  if [ $# -gt 1 ]; then
    exitCode=$1
    shift
  else
    exitCode=1
  fi
  printf "$*"
  exit ${exitCode}
}

function instantiateTemplate()
{
  if [ $# -ne 2 ]; then
    return 1
  fi

  pgm_tpl=$1
  pgm_dest=$2
  if [ ! -r "${pgm_tpl}" ]; then
    return 2
  fi
  if [ ! -w "$(dirname ${pgm_dest})" ]; then
    return 3
  fi

  pgm_sed_command=""
  for pgm_var in ${!PGM_*}
  do
    if ! [[ ${!pgm_var} =~ .*[/].* ]]; then
      pgm_sed_command="${pgm_sed_command} s/\${${pgm_var}}/${!pgm_var}/;"
    elif ! [[ ${!pgm_var} =~ .*[%].* ]]; then
      pgm_sed_command="${pgm_sed_command} s%\${${pgm_var}}%${!pgm_var}%;"
    fi
  done
  
  if [ -e "${pgm_dest}" ]; then
    cp ${pgm_dest} ${pgm_dest}.orig
    if [ $? -ne 0 ]; then
      return 4
    fi
  fi
  sed "${pgm_sed_command}" ${pgm_tpl} > ${pgm_dest}
  if [ $? -ne 0 ]; then
    return 5
  fi
}


# Nothing should happens after next line
export PGM_UTIL_INCLUDE="LOADED"
