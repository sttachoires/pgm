#! @BASH@

# Differents constants to fit pgm scripts

# 19.02.2016	S. Tachoires	Initiate
#set -xv

if [[ "${PGM_SERVER_INCLUDE}" == "LOADED" ]]; then
  return 0
fi

. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi

function setServer()
{
  if [[ $# -ne 1 ]]; then
    return 1
  fi

  PGM_PGFULL_VERSION=$1
  if [[ "${PGM_PGFULL_VERSION}" =~ ${PGM_PGVERSION_AUTHORIZED_REGEXP} ]]; then
    # First set versions constants
    export PGM_PGMAJOR_VERSION=${PGM_PGFULL_VERSION%.*}

    # Remove trailing slashes.
    for pgm_pattern in ${!PGMSRV_PTRN_*}
    do
      eval pgm_value=\$${pgm_pattern}
      eval export ${pgm_pattern/#PGMSRV_PTRN_/PGM_}=\"${pgm_value%/}\"
    done
    
#    export PATH="${PGM_PGHOME_DIR}/bin:${PATH}"
#    export LD_LIBRARY_PATH="${PGM_PGHOME_DIR}/lib:${LD_LIBRARY_PATH}"

    return 0
  else
    return 2
  fi
}

function serverList()
{
  if [[ "${PGM_PG_TAB}x" == "x" ]] || [[ ! -r "${PGM_PG_TAB}" ]]; then
    return 1
  fi
  printf "$(egrep --only-matching "_:_:.*:" ${PGM_PG_TAB} | cut --delimiter ':' --fields 3)"
}

function serverInfo()
{
  if [[ $# -ne 1 ]]; then
    return 1
  fi
  
  pgm_result=$(setServer $1)
  if [[ $? -ne 0 ]]; then
    return 2
  fi
  
  if [[ -x ${PGM_PGBIN_DIR}/pg_config ]]; then
    ${PGM_PGBIN_DIR}/pg_config
  else
    printf "no valid pg_config\n"
    return 3
  fi
}

function checkAllServers()
{
  pgm_report=""
  pgm_status=0
  for pgm_version in $(serverList)
  do
    pgm_report="${pgm_report} $(checkServer ${pgm_version})"
    if [[ $? -ne 0 ]]; then
      pgm_status=$(( ${pgm_status} + 1 ))
    fi
  done

  printf "${pgm_report//[ ][ ]+/ }"
  return ${pgm_status}
}

function checkServer()
{
  pgm_report=""
  pgm_status=0

  if [[ $# -ne 1 ]]; then
    return 1
  fi

  setServer ${pgm_version}
  if [[ $? -ne 0 ]]; then
    return 2
  fi

  pgm_report="${pgm_report} $(checkEnvironment)"
  if [[ $? -ne 0 ]]; then
    return 3
  fi

  printf "${pgm_report//[ ][ ]+/ }"
  return ${pgm_status}
}


# Nothing should happens after next line
export PGM_SERVER_INCLUDE="LOADED"
