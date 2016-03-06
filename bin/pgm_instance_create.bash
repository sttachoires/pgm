#! @BASH@
#
# Create a PostgreSQL instance.
#
# 21.02.2016	S. Tachoires	Initial version
#
#set -xv

# Constants
PRGNAME=$(basename $0 2> /dev/null)
if [[ $? -ne 0 ]]; then
  PRGNAME="Unknown"
fi

# INCLUDE
. @CONFDIR@/pgm.conf
. @LIBDIR@/pgm_util.include
. @LIBDIR@/pgm_server.include
. @LIBDIR@/pgm_pg.include

USAGE="Usage: ${PRGNAME} PGVERSION PGSID PGPORT PGLISTENER\nwhere:\n\tPGVERSION is the major version of PostgreSQL to use (ie: 9.3)\n\tPGSID stands for the cluster name (Oracle SID equivalent)\n\tPGPORT is the port the server is listening from\n\tPGLISTENER  is the hostname/ip listening on the PGPORT (default wil be 'uname --node')\n"


export pgm_version=""
export pgm_sid=""
export pgm_port=5432
export pgm_listener=$(uname --node)

function checkParameters ()
{
  case $# in
    4 )
       pgm_version=$1
       pgm_sid=$2
       pgm_port=$3
       pgm_listener=$4
       ;;

    3 )
       pgm_version=$1
       pgm_sid=$2
       pgm_port=$3
       ;;

    2 )
       pgm_version=$1
       pgm_sid=$2
       ;;

    * ) exitError "${USAGE}\n"
  esac

  setServer ${pgm_version}
  if [[ $? -ne 0 ]]; then
    exitError "Unmanaged version ${pgm_version}\n"
  fi

  setInstance ${pgm_version} ${pgm_sid}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot set ${pgm_sid} version ${pgm_version} \n"
  fi

  export PGM_LOG="${PGM_LOG_DIR}/create_instance.log"
  printInfo "\nINSTANCE CREATION ON $(date)\n  INSTANCE : '${pgm_sid}'\n  VERSION : '${pgm_version}'\n  LISTENER(S) : '${pgm_listener}'\n  PORT : '${pgm_port}'\n\n"
}

function checkFS ()
{
  if [[ "${PGM_PGFSLIST}x" == "x" ]]; then
    printInfo "No required filesystems\n"
    return 0
  fi
  for pgm_fs in ${PGM_PGFSLIST} 
  do
    mount -l | grep -q "${pgm_fs}"
    if [[ $? -ne 0 ]]; then
      exitError "${pgm_fs} is not a filesystem!\n"
    fi
  done

  printInfo "Filesystems ${PGM_PGFSLIST} are present\n"
  return 0
}
  
function buildDirectories()
{
  mkdir -p ${PGM_PGDATA_DIR}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot create ${PGM_PGDATA_DIR}"
  else
    chmod u=rwx,go= ${PGM_PGDATA_DIR}
    if [[ $? -ne 0 ]]; then
      exitError "Cannot adjust ${PGM_PGDATA_DIR} access policy to 700"
    fi
  fi
  mkdir -p ${PGM_PGXLOG_DIR}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot create ${PGM_PGXLOG_DIR}"
  fi

  mkdir -p ${PGM_PG_LOG_DIR}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot create ${PGM_PG_LOG_DIR}"
  fi

  mkdir -p ${PGM_PGARCHIVELOG_DIR}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot create ${PGM_PGARCHIVELOG_DIR}"
  fi

  printInfo "Directories are ok\n" 
}

function initDB ()
{
  # Create cluster
  ${PGM_PGBIN_DIR}/initdb --pgdata=${PGM_PGDATA_DIR} --encoding=UTF8 --xlogdir=${PGM_PGXLOG_DIR} --data-checksums --no-locale 2>&1 >> ${PGM_LOG} 2>&1
  if [[ $? -ne 0 ]]; then
    exitError "Cannot create instance ${PGM_PGINSTANCE} with PostgreSQL ${PGM_PGFULL_VERSION}\nCheck ${PGM_LOG}\n"
  fi

  setInstance ${PGM_PGFULL_VERSION} ${PGM_PGINSTANCE}
  export PGM_PGHOST=${pgm_listener}
  export PGM_PGPORT=${pgm_port}
  printInfo "Instance ${PGM_PGINSTANCE} created\n"
}

function createRecovery ()
{
  pgm_name=$(basename ${PGM_PGRECOVER_CONF})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  instantiateTemplate ${pgm_tpl} ${PGM_PGRECOVER_CONF}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot create ${PGM_PGRECOVER_CONF} from ${pgm_tpl}\n"
  fi
  printInfo "${PGM_PGRECOVER_CONF} created\n"
}


function createConf ()
{
  pgm_name=$(basename ${PGM_PG_CONF})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  instantiateTemplate ${pgm_tpl} ${PGM_PG_CONF}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot create ${PGM_PG_CONF} from ${pgm_tpl}\n"
  fi
  printInfo "${PGM_PG_CONF} created\n"
}


function createHBA ()
{
  pgm_name=$(basename ${PGM_PGHBA_CONF})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  instantiateTemplate ${pgm_tpl} ${PGM_PGHBA_CONF}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot create ${PGM_PGHBA_CONF} from ${pgm_tpl}\n"
  fi
  printInfo "${PGM_PGHBA_CONF} created\n"
}

function createIdent ()
{
  pgm_name=$(basename ${PGM_PGIDENT_CONF})
  pgm_tpl=${PGM_TEMPLATE_DIR}/${pgm_name}.tpl
  instantiateTemplate ${pgm_tpl} ${PGM_PGIDENT_CONF}
  if [[ $? -ne 0 ]]; then
    exitError "Cannot create ${PGM_PGIDENT_CONF} from ${pgm_tpl}\n"
  fi
  printInfo "${PGM_PGIDENT_CONF} created\n"
}

function createTabEntry()
{
  if [[ ! -w "${PGM_PG_TAB}" ]]; then
    exitError "Unable to write into ${PGM_PG_TAB}\n"
  fi
  egrep -q "^_:${PGM_PGINSTANCE}:${PGM_PGFULL_VERSION}:[yn]" ${PGM_PG_TAB}
  if [[ $? -ne 0 ]]; then
    echo "_:${PGM_PGINSTANCE}:${PGM_PGFULL_VERSION}:y" >> ${PGM_PG_TAB}
    printInfo "Line '_:${PGM_PGINSTANCE}:${PGM_PGFULL_VERSION}:y' added to ${PGM_PG_TAB}\n"
  else
    printInfo "Line '_:${PGM_PGINSTANCE}:${PGM_PGFULL_VERSION}:y' already present in ${PGM_PG_TAB}\n"
  fi
}

function createFlags()
{
  # Create no backup flag
  touch ${PGM_PGDATA_DIR}/.no_backup
  if [[ $? -ne 0 ]]; then
    if [[ ! -e ${PGM_PGDATA_DIR}/.no_backup ]]; then
      exitError "Cannot create ${PGM_PGDATA_DIR}/.no_backup file"
    fi
  fi
}

function createExtentions()
{
  for pgm_extention in ${PGM_PGEXTENSIONS_TO_CREATE//,/}
  do
    pgExec template1 "CREATE EXTENSION ${pgm_extention};"
    if [[ $? -ne 0 ]]; then
      exitError "Cannot create extention ${pgm_extention} in template1\n"
    fi
  done
}

function configureLogrotate()
{
  if [[ -e ${PGM_LOGROTATE_CONF} ]]; then
    egrep --quiet --only-matching "${PGM_PG_LOG_DIR}/\*.log" ${PGM_LOGROTATE_CONF}
    if [[ $? -ne 0 ]]; then
      printf "${PGM_LOGROTATE_ENTRY}" >> ${PGM_LOGROTATE_CONF}
    fi
  else
    touch ${PGM_LOGROTATE_CONF}
    printf "${PGM_PG_LOGROTATE_ENTRY}" > ${PGM_LOGROTATE_CONF}
  fi
}

#
# M A I N
#

checkParameters $*
checkFS
buildDirectories
pgm_result="$(ensureVars _DIR -d)"
if [[ $? -ne 0 ]]; then
  exitError "Problem with directories:\n ${pgm_result// /$'\n'}\nplease provide them\n"
fi
initDB
createConf
createRecovery
createHBA
createIdent
createTabEntry
createFlags
startInstance "${PGM_PGFULL_VERSION}" "${PGM_PGINSTANCE}"
if [[ $? -ne 0 ]]; then
  exitError "Cannot start instance ${PGM_PGINSTANCE} (${PGM_PGFULL_VERSION}) read ${PGM_LOG}\n"
fi
createExtentions
configureLogrotate

printInfo "Instance ${PGM_PGINSTANCE} has been created. You have to create a database in it\n"
