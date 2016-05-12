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
. @CONFDIR@/pgbrewer.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/inventory.include
. ${PGB_LIB_DIR}/server.include

USAGE="Usage: ${PRGNAME} FULLVERSION SRCDIR\nwhere\n\tFULLVERSION is the full PostgreSQL you are about to install (9.5.0)\n\tSRCDIR is the directory where you've put uncompressed source directory (/var/tmp/postgres-9.5.0-master)"

#
# M A I N
#


if [[ $# -lt 2 ]]; then
  exitError "${USAGE}\n"
fi

pgb_srcdir=${1%/}
pgb_server=$2
shift 2

analyzeParameters $*

if [[ ! -d ${pgb_srcdir} ]]; then
  exitError "${pgb_srcdir} does not exists\n"
elif [[ ! -x ${pgb_srcdir}/configure ]]; then
  exitError "Something wrong with ${pgb_srcdir}. Configure script cannot be found executable\n"
fi

installServer ${pgb_srcdir} ${pgb_server}
if [[ $? -ne 0 ]]; then
  printError "Error installing ${pgb_srcdir} ${pgb_server}\n"
else
  printf "PostgreSQL ${PGB_PGFULL_VERSION} installed in ${PGB_PGHOME_DIR}\n"
fi
