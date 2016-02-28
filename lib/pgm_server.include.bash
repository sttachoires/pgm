#! @BASH@

# Differents constants to fit pgm scripts

# 19.02.2016	S. Tachoires	Initiate
#set -xv

if [ "${PGM_SERVER_INCLUDE}" == "LOADED" ]; then
  return 0
fi

. @CONFDIR@/pgm.conf
if [ $? -ne 0 ]; then
  exit 1
fi

function setServer()
{
  if [ $# -ne 1 ]; then
    return 1
  fi

  PGM_PGFULL_VERSION=$1
  if [[ "${PGM_PGFULL_VERSION}" =~ ${PGM_VERSION_AUTHORIZED_REGEXP} ]]; then
    # First set versions constants
    export PGM_PGFULL_VERSION_NUM=${PGM_PGFULL_VERSION//./}
    export PGM_PGMAJOR_VERSION=${PGM_PGFULL_VERSION%.*}
    export PGM_PGMAJOR_VERSION_NUM=${PGM_PGMAJOR_VERSION//./}

    # Remove trailing slashes.
    for pgm_pattern in ${!PGMSRV_PTRN_*}
    do
      eval pgm_value=\$${pgm_pattern}
      eval export ${pgm_pattern/#PGMSRV_PTRN_/PGM_}=\"${pgm_value%/}\"
    done
    
    export PATH="${PGM_PGHOME_DIR}/bin:${PATH}"
    export LD_LIBRARY_PATH="${PGM_PGHOME_DIR}/lib:${LD_LIBRARY_PATH}"

    return 0
  else
    return 2
  fi
}

# Nothing should happens after next line
export PGM_SERVER_INCLUDE="LOADED"
