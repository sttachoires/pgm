#! /bin/bash
#
# Install PostgreSQL server
#
# 19.02.2016    S. Tachoires    Initial version
#
#set -xv

# Constants
PRGNAME=$(basename $0 2> /dev/null)
if [ $? -ne 0 ]; then
  PRGNAME="Unknown"
fi

# INCLUDE
. {install_dir}/pgm.conf
. ${PGM_LIB_DIR}/pgm_server.include
. ${PGM_LIB_DIR}/pgm_util.include

USAGE="Usage: ${PRGNAME} FULLVERSION SRCDIR\nwhere\n\tFULLVERSION is the full PostgreSQL you are about to install (9.5.0)\n\tSRCDIR is the directory where you've put uncompressed source directory (/var/tmp/postgres-9.5.0-master)"

function checkParameter()
{
  if [ $# -ne 2 ]; then
    exitError "${USAGE}\n"
  fi

  pgm_srcdir=${1%/}
  pgm_version=$2

  if [ ! -d ${pgm_srcdir} ]; then
    exitError "${pgm_srcdir} does not exists\n"
  elif [ ! -x ${pgm_srcdir}/configure ]; then
    exitError "Something wrong with ${pgm_srcdir}. configure script cannot be found executable\n"
  fi

  setServer ${pgm_version}
  if [ $? -ne 0 ]; then
    exitError "Cannot set server ${pgm_version}\n"
  fi
  export PGM_LOG="${PGM_LOG_DIR}/install_server.log"
  printf "\nSERVER INSTALLATION ON $(date)\n  VERSION : '${pgm_version}'\n  SOURCE : '${pgm_srcdir}'\n\n" | tee -a ${PGM_LOG}
}

function createTabEntry()
{
  if [ ! -e ${PGM_PGTAB} ]; then
    echo "#database:instance:version:autostart" > ${PGM_PGTAB}
    if [ $? -ne 0 ]; then
      exitError "Unable to write into ${PGM_PGTAB}\n"
    fi
  fi
  pgmline="*:*:${PGM_FULL_VERSION}:n"
  egrep -q "^[[:space:]]*\*:\*:${PGM_FULL_VERSION}:.?" ${PGM_PGTAB}
  if [ $? -ne 0 ]; then
    echo "${pgmline}" >> ${PGM_PGTAB}
    printf "Line '${pgmline}' added to ${PGM_PGTAB}\n" | tee -a ${PGM_LOG}
  else
    printf "Line '${pgmline}' already present in ${PGM_PGTAB}\n" | tee -a ${PGM_LOG}
  fi
}

#
# M A I N
#

checkParameter $*
cd ${pgm_srcdir}
./configure --prefix=${PGM_PGHOME_DIR} --datarootdir="${PGM_PGHOME_DIR}/share" --with-openssl --with-perl --with-python --with-ldap >> ${PGM_LOG} 2>&1
if [ $? -ne 0 ]; then
  exitError "Problem configuring compilation:\nplease read ${PGM_LOG} and correct problem(s)\n\n"
fi
make world >> ${PGM_LOG} 2>&1
if [ $? -ne 0 ]; then
  exitError "Problem during compilation:\nplease read ${PGM_LOG} and correct problem(s)\n\n"
fi
make check >> ${PGM_LOG} 2>&1
if [ $? -ne 0 ]; then
  exitError "Problem during check:\nplease read ${PGM_LOG} and correct problem(s)\n\n"
fi
make install-world >> ${PGM_LOG} 2>&1
if [ $? -ne 0 ]; then
  exitError "Problem during install:\nplease read ${PGM_LOG} and correct problem(s)\n\n"
fi
make distclean >> ${PGM_LOG} 2>&1
if [ $? -ne 0 ]; then
  exitError "Problem during cleaning:\nplease read ${PGM_LOG} and correct problem(s)\n\n"
fi

createTabEntry

printf "PostgreSQL ${PGM_FULL_VERSION} is installed in ${PGM_PGHOME_DIR}\n" | tee -a ${PGM_LOG}
