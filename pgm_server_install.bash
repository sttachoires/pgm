#! /bin/bash
#
# Install PostgreSQL server
#
# 19.02.2016    S. Tachoires    Initial versio
#
#set -xv

# Constants
PRGNAME=$(basename $0 2> /dev/null)
if [ $? -ne 0 ]; then
  PRGNAME="Unknown"
fi

# INCLUDE
. /home/stephane/postgres/github/pgm/pgm_server.include
. /home/stephane/postgres/github/pgm/pgm_util.include

USAGE="Usage: ${PRGNAME} FULLVERSION SRCDIR\nwhere\n\tFULLVERSION is the full PostgreSQL you are about to install (9.5.0)\n\tSRCDIR is the directory where you've put uncompressed source directory (/var/tmp/postgres-9.5.0-master)"

function checkParameter()
{
  if [ $# -ne 2 ]; then
    exitError "${USAGE}\n"
  fi

  version=$1
  srcdir=${2%/}

  if [ ! -d ${srcdir} ]; then
    exitError "${srcdir} does not exists\n"
  elif [ ! -x ${srcdir}/configure ]; then
    exitError "Something wrong with ${srcdir}. configure script cannot be found executable\n"
  fi

  setServer ${version}
  if [ $? -ne 0 ]; then
    exitError "Cannot set server\n"
  fi
  export PGM_LOGFILE="${PGM_LOGDIR}/install_server.log"
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
    printf "Line '${pgmline}' added to ${PGM_PGTAB}\n" | tee -a ${PGM_LOGFILE}
  else
    printf "Line '${pgmline}' already present in ${PGM_PGTAB}\n" | tee -a ${PGM_LOGFILE}
  fi
}

#
# M A I N
#

checkParameter $*
cd ${srcdir}
./configure --prefix=${PGM_PGHOME_DIR} --datarootdir="${PGM_PGHOME}/share" --with-openssl --with-ldap | tee -a ${PGM_LOGFILE}
if [ $? -ne 0 ]; then
  exitError "Problem configuring compilation:\nplease read preceding ouput and correct problem(s)\n\n"
fi
make world | tee -a ${PGM_LOGFILE}
if [ $? -ne 0 ]; then
  exitError "Problem during compilation:\nplease read preceding ouput and correct problem(s)\n\n"
fi
make check | tee -a ${PGM_LOGFILE}
if [ $? -ne 0 ]; then
  exitError "Problem during check:\nplease read preceding ouput and correct problem(s)\n\n"
fi
make install-world | tee -a ${PGM_LOGFILE}
if [ $? -ne 0 ]; then
  exitError "Problem during install:\nplease read preceding ouput and correct problem(s)\n\n"
fi
make distclean | tee -a ${PGM_LOGFILE}
if [ $? -ne 0 ]; then
  exitError "Problem during cleaning:\nplease read preceding ouput and correct problem(s)\n\n"
fi

createTabEntry

printf "PostgreSQL ${PGM_VERSION} is installed in ${PGM_BASE}/${PGM_VERSION}\n" | tee -a ${PGM_LOGFILE}
