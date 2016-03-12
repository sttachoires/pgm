#! @BASH@

# Differents constants to fit pgm scripts

# 19.02.2016	S. Tachoires	Initiate
#set -xv

if [ "${PGM_SERVER_INCLUDE}" == "LOADED" ]; then
  return 0
fi
export PGM_SERVER_INCLUDE="LOADED"

. @CONFDIR@/pgm.conf
if [[ $? -ne 0 ]]; then
  exit 1
fi
. ${PGM_CONF_DIR}/server.conf
. ${PGM_LIB_DIR}/pgm_pginventory.include
. ${PGM_LIB_DIR}/pgm_util.include

function setServer()
{
  if [[ $# -ne 1 ]]; then
    return 1
  fi

  PGM_PGFULL_VERSION=$1
  if [[ "${PGM_PGFULL_VERSION}" =~ ${PGM_PGREAL_VERSION_REGEXP}(${PGM_PGVERSION_AUTHORIZED_REGEXP})? ]]; then
    # First set versions constants
    export PGM_PGREAL_VERSION=$(echo "${PGM_PGFULL_VERSION}" | egrep --only-matching ${PGM_PGREAL_VERSION_REGEXP})
    export PGM_PGMAJOR_VERSION=${PGM_PGREAL_VERSION%.*}

    # Remove trailing slashes.
    for pgm_pattern in ${!PGMSRV_PTRN_*}
    do
      eval pgm_value=\$${pgm_pattern}
      eval export ${pgm_pattern/#PGMSRV_PTRN_/PGM_}=\"${pgm_value%/}\"
    done
    
    return 0
  else
    return 2
  fi
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
  
  if [ -x ${PGM_PGBIN_DIR}/pg_config ]; then
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

  pgm_servers="$(getServers)"
  for pgm_version in ${pgm_servers}
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

function installServer()
{
  pgm_report=""
  pgm_status=0

  if [[ $# -ne 2 ]]; then
    return 1
  fi

  pgm_srcdir=${1%/}
  pgm_version=$2

  if [ ! -v PGM_PGHOME_DIR ] || [ ! -v PGM_PGBIN_DIR ] || [ ! -v PGM_PGLIB_DIR ] || [ ! -v PGM_PGINCLUDE_DIR ] || [ ! -v PGM_PGSHARE_DIR ] || [ ! -v PGM_PGMAN_DIR ] || [ ! -v PGM_PGDOC_DIR ]; then
    setServer ${pgm_version}
    if [[ $? -ne 0 ]]; then
      return 2
    fi
  fi

  cd ${pgm_srcdir}
  ./configure --prefix=${PGM_PGHOME_DIR} --exec-prefix=$(dirname ${PGM_PGBIN_DIR}) --bindir=${PGM_PGBIN_DIR} --libdir=${PGM_PGLIB_DIR} --includedir=${PGM_PGINCLUDE_DIR} --datarootdir=${PGM_PGSHARE_DIR} --mandir=${PGM_PGMAN_DIR} --docdir=${PGM_PGDOC_DIR} --with-openssl --with-perl --with-python --with-ldap
  if [[ $? -ne 0 ]]; then
    return 3
  fi

  make world
  if [[ $? -ne 0 ]]; then
    return 4
  fi

  make check
  if [[ $? -ne 0 ]]; then
    return 5
  fi

  make install-world
  if [[ $? -ne 0 ]]; then
    return 6
  fi

  make distclean
  if [[ $? -ne 0 ]]; then
    return 7
  fi

  addServer ${pgm_version}
}
