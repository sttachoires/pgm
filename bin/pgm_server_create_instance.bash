#! @BASH@
#
# Create a PostgreSQL instance.
#
# 21.02.2016	S. Tachoires	Initial version
#
#set -xv

# Constants
PRGNAME=$(basename $0 2> /dev/null)
if [ $? -ne 0 ]; then
  PRGNAME="Unknown"
fi

# INCLUDE
. @CONFDIR@/pgm.conf
. @LIBDIR@/pgm_util.include
. @LIBDIR@/pgm_server.include
. @LIBDIR@/pgm_pg.include

USAGE="Usage: ${PRGNAME} PGVERSION PGSID PGPORT PGLISTENER\nwhere:\n\tPGVERSION is the major version of PostgreSQL to use (ie: 9.3)\n\tPGSID stands for the cluster name (Oracle SID equivalent)\n\tPGPORT is the port the server is listening from\n\tPGLISTENER  is the hostname/ip listening on the PGPORT (default wil be '*')\n"


function checkParameters ()
{
  if [ $# -lt 4 ]; then
    exitError "${USAGE}\n"
  fi

  export pgm_version=$1
  export pgm_sid=$2
  export pgm_port=$3
  export pgm_listener=$4

  setInstance ${pgm_version} ${pgm_sid}
  if [ $? -ne 0 ]; then
    exitError "Cannot set ${pgm_sid} version ${pgm_version} \n"
  fi

  export PGM_LOG="${PGM_LOG_DIR}/create_instance.log"
  printInfo "\nINSTANCE CREATION ON $(date)\n  INSTANCE : '${pgm_sid}'\n  VERSION : '${pgm_version}'\n  LISTENER(S) : '${pgm_listener}'\n  PORT : '${pgm_port}'\n\n"
}

function checkFS ()
{
  for pgm_fs in ${PGM_PGFSLIST} 
  do
    mount -l | grep -q "${pgm_fs}"
    if [ $? -ne 0 ]; then
      exitError "${pgm_fs} is not a filesystem!"
    fi
  done

  printInfo "Filesystems ${PGM_PGFSLIST} are present\n"
  return 0
}
  
function buildDirectories()
{
  mkdir -p ${PGM_PGDATA_DIR}
  if [ $? -ne 0 ]; then
    exitError "Cannot create ${PGM_PGDATA_DIR}"
  else
    chmod u=rwx,go= ${PGM_PGDATA_DIR}
    if [ $? -ne 0 ]; then
      exitError "Cannot adjust ${PGM_PGDATA_DIR} access policy to 700"
    fi
  fi
  mkdir -p ${PGM_PGXLOG_DIR}
  if [ $? -ne 0 ]; then
    exitError "Cannot create ${PGM_PGXLOG_DIR}"
  fi

  printInfo "Directories ${PGM_PGDATA_DIR} and ${PGM_PGXLOG_DIR} are ok\n" 
}

function initDB ()
{
  # Create cluster
  ${PGM_PGBIN_DIR}/initdb --pgdata=${PGM_PGDATA_DIR} --encoding=UTF8 --xlogdir=${PGM_PGXLOG_DIR} --data-checksums --no-locale 2>&1 >> ${PGM_LOG} 2>&1
  if [ $? -ne 0 ]; then
    exitError "Cannot create instance ${PGM_PGSID} with PostgreSQL ${PGM_PGFULL_VERSION}\n"
  fi

  setInstance ${PGM_PGFULL_VERSION} ${PGM_PGSID}
  export PGM_PGHOST=${pgm_listener}
  export PGM_PGPORT=${pgm_port}
  printInfo "Instance ${PGM_PGSID} created\n"
}

function createRecovery ()
{
  pgm_name=$(basename ${PGM_PGRECOVER})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  instantiateTemplate ${pgm_tpl} ${PGM_PGRECOVER}
  if [ $? -ne 0 ]; then
    exitError "Cannot create ${PGM_PGRECOVER} from ${pgm_tpl}\n"
  fi
  printInfo "${PGM_PGRECOVER} created\n"
}


function createConf ()
{
  pgm_name=$(basename ${PGM_PGCONF})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  instantiateTemplate ${pgm_tpl} ${PGM_PGCONF}
  if [ $? -ne 0 ]; then
    exitError "Cannot create ${PGM_PGCONF} from ${pgm_tpl}\n"
  fi
  printInfo "${PGM_PGCONF} created\n"
}


function createHBA ()
{
  pgm_name=$(basename ${PGM_PGHBA})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  instantiateTemplate ${pgm_tpl} ${PGM_PGHBA}
  if [ $? -ne 0 ]; then
    exitError "Cannot create ${PGM_PGHBA} from ${pgm_tpl}\n"
  fi
  printInfo "${PGM_PGHBA} created\n"
}

function createIdent ()
{
  pgm_name=$(basename ${PGM_PGIDENT})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  instantiateTemplate ${pgm_tpl} ${PGM_PGIDENT}
  if [ $? -ne 0 ]; then
    exitError "Cannot create ${PGM_PGIDENT} from ${pgm_tpl}\n"
  fi
  printInfo "${PGM_PGHBA} created\n"
}

function createTabEntry()
{
  if [ ! -w "${PGM_PGTAB}" ]; then
    exitError "Unable to write into ${PGM_PGTAB}\n"
  fi
  egrep -q "^[[:space:]]*\*:${PGM_PGSID}:${PGM_PGFULL_VERSION}:[yYnN]" ${PGM_PGTAB}
  if [ $? -ne 0 ]; then
    echo "*:${PGM_PGSID}:${PGM_PGFULL_VERSION}:y" >> ${PGM_PGTAB}
    printInfo "Line '*:${PGM_PGSID}:${PGM_PGFULL_VERSION}:y' added to ${PGM_PGTAB}\n"
  else
    printInfo "Line '*:${PGM_PGSID}:${PGM_PGFULL_VERSION}:y' already present in ${PGM_PGTAB}\n"
  fi
}

function createFlags()
{
  # Create no backup flag
  touch ${PGM_PGDATA_DIR}/.no_backup
  if [ $? -ne 0 ]; then
    if [ ! -e ${PGM_PGDATA_DIR}/.no_backup ]; then
      exitError "Cannot create ${PGM_PGDATA_DIR}/.no_backup file"
    fi
  fi
}

function createExtentions()
{
  for pgm_extention in ${PGM_PGEXTENTIONS_TO_CREATE//,/}
  do
    pgExec template1 "CREATE EXTENSION ${pgm_extention};"
    if [ $? -ne 0 ]; then
      exitError "Cannot create extention ${pgm_extention} in template1\n"
    fi
  done
}

function configureLogrotate()
{
  if [ -e ${PGM_LOGROTATE_CONF} ]; then
    egrep --quiet --only-matching "${PGM_PGLOG_DIR}/\*.log" ${PGM_LOGROTATE_CONF}
    if [ $? -ne 0 ]; then
      printf "${PGM_LOGROTATE_ENTRY}" >> ${PGM_LOGROTATE_CONF}
    fi
  else
    touch ${PGM_LOGROTATE_CONF}
    printf "${PGM_PGLOGROTATE_ENTRY}" > ${PGM_LOGROTATE_CONF}
  fi
}

#
# M A I N
#

checkParameters $*
setServer ${pgm_version}
if [ $? -ne 0 ]; then
  exitError "Cannot set ${pgm_version} server\n"
fi
ensureDirs
checkFS
buildDirectories
initDB
createConf
createRecovery
createHBA
createIdent
createTabEntry
createFlags
startInstance "${PGM_PGFULL_VERSION}" "${PGM_PGSID}"
if [ $? -ne 0 ]; then
  exitError "Cannot start instance ${PGM_PGSID} (${PGM_PGFULL_VERSION}) read ${PGM_LOG}\n"
fi
createExtentions
configureLogrotate

printInfo "Instance ${PGM_PGSID} has been created. You have to create a database in it\n"
