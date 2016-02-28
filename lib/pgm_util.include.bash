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
  if [ -w "${PGM_LOG}" ]; then
    printf "$*" >&2 | tee -a ${PGM_LOG}
  else
    printf "$*" >&2
  fi
}

function printInfo()
{
  if [ -w "${PGM_LOG}" ]; then
    printf "$*" | tee -a ${PGM_LOG}
  else
    printf "$*" 
  fi
}

function exitError()
{
  if [ $# -gt 1 ]; then
    exitCode=$1
    shift
  else
    exitCode=1
  fi
  printError "$*"
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

function ensureDirs()
{
  pgm_result=""
  for pgm_var in ${!PGM_*}
  do
    pgm_dir_var=$(echo ${pgm_var} | egrep -o "PGM_.*_DIR")
    if [ ! -z "${pgm_dir_var}" ]; then
      eval pgm_value=\"\$${pgm_dir_var}\"
      if [ ! -d "${pgm_value}" ]; then
        pgm_result="${pgm_result} ${pgm_value}"
      fi
    fi
  done
  if [ -z "${pgm_result}" ]; then
    return 0
  else
    printf "${pgm_result}"
    return $(echo "${pgm_result}" | wc -w)
  fi
}

function checkEnvironmentDirs()
{
  pgm_report=""
  pgm_status=0

  pgm_report="${pgm_report} $(ensureDirs)"
  if [ $? -ne 0 ]; then
    pgm_status=1
  fi

  pgm_version_list="$(egrep --only-matching "\*:\*:[0-9.]+:[ynYN]" ${PGM_PGTAB} | cut --delimiter ':' --fields 3)"
  if [ $? -eq 0 ]; then
    for pgm_version in ${pgm_version_list}
    do
      setServer ${pgm_version}
      pgm_report="${pgm_report} $(ensureDirs)"
      if [ $? -ne 0 ]; then
        pgm_status=2
      fi

      pgm_instance_list="$(egrep --only-matching "\*:${PGM_PGSID_AUTHORIZED_REGEXP}:${pgm_version}:[ynYN]" ${PGM_PGTAB} | cut --delimiter ':' --fields 2)"
      if [ $? -eq 0 ]; then
        for pgm_instance in ${pgm_instance_list}
        do
          setInstance ${pgm_version} ${pgm_instance}
          pgm_report="${pgm_report} $(ensureDirs)"
          if [ $? -ne 0 ]; then
            pgm_status=3
          fi
          pgm_database_list="$(egrep --only-matching "${PGM_PGDATABASE_AUTHORIZED_REGEXP}:${pgm_instance}:${pgm_version}:[ynYN]" ${PGM_PGTAB} | cut --delimiter ':' --fields 1)"
          if [ $? -ne 0 ]; then
            for pgm_database in ${pgm_database_list}
            do
              setDatabase ${pgm_version} ${pgm_instance} ${pgm_database}
              pgm_report="${pgm_report} $(ensureDirs)"
              if [ $? -ne 0 ]; then
                pgm_status=3
              fi
            done
          fi
        done
      fi
    done
  fi

  printf "${pgm_report}"
  return ${pgm_status}
}

# Nothing should happens after next line
export PGM_UTIL_INCLUDE="LOADED"
