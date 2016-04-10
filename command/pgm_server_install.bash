#! @BASH@
#
# Install PostgreSQL server
#
# 19.02.2016    S. Tachoires    Initial version
#
#set -xv

# Constants
PRGNAME=$(basename $0 2> /dev/null)
if [[ $? -ne 0 ]]; then
  PRGNAME="Unknown"
fi

# INCLUDE
. @CONFDIR@/pgm.conf
. ${PGM_LIB_DIR}/util.include
. ${PGM_LIB_DIR}/inventory.include
. ${PGM_LIB_DIR}/server.include

USAGE="Usage: ${PRGNAME} FULLVERSION SRCDIR\nwhere\n\tFULLVERSION is the full PostgreSQL you are about to install (9.5.0)\n\tSRCDIR is the directory where you've put uncompressed source directory (/var/tmp/postgres-9.5.0-master)"

#
# M A I N
#


if [[ $# -lt 2 ]]; then
  exitError "${USAGE}\n"
fi

pgm_srcdir=${1%/}
pgm_server=$2
shift 2

analyzeParameters $*

if [[ ! -d ${pgm_srcdir} ]]; then
  exitError "${pgm_srcdir} does not exists\n"
elif [[ ! -x ${pgm_srcdir}/configure ]]; then
  exitError "Something wrong with ${pgm_srcdir}. Configure script cannot be found executable\n"
fi

installServer ${pgm_srcdir} ${pgm_server}
if [[ $? -ne 0 ]]; then
  printError "Error installing ${pgm_srcdir} ${pgm_server}\n"
else
  printf "PostgreSQL ${PGM_PGFULL_VERSION} installed in ${PGM_PGHOME_DIR}\n"
fi
