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
. ${PGB_LIB_DIR}/pgserver.include

export PGB_LOG="${PGB_LOG_DIR}/pgserver"

export PGB_ACTIONS="\
list +config+
info +config+ +server+
check +config+ +server+
add +config+ !server!
add as +config+ +server+ !server!
configure list +config+ +server+
configure +config+ .serverfilename. +server+
compare +config+ +server+ +server+
merge +config+ +server+ +server+
create +config+ +server+
install +config+ +server+
remove +config+ +server+
drop +config+ -server-"

export PGB_ACTIONS_DESCRIPTION="\
list
list available ${PRGNAME} servers actives or removed

info +config+ +server+
will provide information about a server, that is, differences from default

check +config+ +server+
will check for the server configuration validity, missing directories or files, etc...

add +config+ !server!
add (reference) a new server from default one, allow configuration edition

add as +server+ +config+ !server!
same as above but will inspire from first server

configure list +config+ +server+
list available configurations, server or instances templates

configure .serverfilename. +config+ +server+
edit server configuration file, could be 'server' to edit environment configuration or 'postgresql' or 'pg_hba' or 'ident'

compare +server+ +config+ +server+
compare two server environments, issuing every differents parameters

merge +server+ +config+ +server+
merge first server environment into the second one, configurations by configurations

create +config+ +server+
install server. Then pg_config configuration will take over configuration parameters

install +config+ +server+
same as above

remove +config+ +server+
remove server, no deletion, listed a removed, but be empty, no database, replication, whatsoever
 
drop +config+ -server-
perform actual server removal by deletion
"

export PGB_SHORT_DESCRIPTION="\
pgserver command will help handle PostgreSQL server, with, potentialy,
differents directory, instances configuration, compilation..."

export PGB_LONG_DESCRIPTION="\
${PGB_SHORT_DESCRIPTION}

${PGB_GENERAL_PHILOSOPHY_DESCRIPTION}
Actions:\n${PGB_ACTIONS_DESCRIPTION}"

export PGB_USAGE="\
${PGB_GENERAL_SHORT_DESCRIPTION}

${PRGNAME}
Description:
${PGB_SHORT_DESCRIPTION}
${PRGNAME} action [parameters]
Where actions are:
${PGB_ACTIONS//$'\n'/$'\n'$'\t'}"

export PGB_HELP="\
${PGB_GENERAL_SHORT_DESCRIPTION}
${PGB_LONG_DESCRIPTION}
"

analyzeStandart $*

if [[ $# -gt 0 ]]; then
  pgb_action=$1
  shift
else
  exitError 1 "No action\n${PGB_USAGE}"
fi

case "${pgb_action}" in
  "actions")
    printf "${PGB_ACTIONS}\n"
    ;;

  "usage")
    printf "${PGB_ACTIONS_DESCRIPTION}\n"
    ;;

  "help")
    printf "${PGB_HELP}\n"
    ;;

  "list")
    if [[ $# -eq 0 ]]; then
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    getServers ${pgb_config} pgb_server_list
    if [[ $? -ne 0 ]]; then
      exitError 2 "error getting server list"
    fi
    getRemovedConfigurations ${pgb_config} pgb_removed_server_list
    if [[ $? -ne 0 ]]; then
      exitError 3 "error getting removed server list"
    fi
    if [ "${pgb_server_list// }x" == "x" ] && [ "${pgb_removed_server_list// }x" == "x" ]; then
      printf "No server.\n"
    else
      if [ "${pgb_server_list}x" != "x" ]; then
        printf "Active servers:\n${pgb_server_list// /$'\n'}\n"
      fi
      if [ "${pgb_removed_server_list}x" != "x" ]; then
        if [ "${pgb_server_list}x" != "x" ]; then
          printf "\n"
        fi
        printf "Removed servers:\n${pgb_removed_server_list// /$'\n'}\n"
      fi
    fi
    ;;

  "info")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    if [ "${pgb_config}x" == "defaultx" ]; then
      pgb_config_dir=${PGB_CONF_DIR}/pgserver
    else
      pgb_config_dir=${PGB_CONF_DIR}/${pgb_config}/pgserver
    fi
    if [ ! -d ${pgb_config_dir} ]; then
      exitError "No config ${pgb_config}"
    fi
    for pgb_orig in ${pgb_config_dir}/*.conf
    do
      printf "$(basename ${pgb_orig%\.conf})\n"
    done
    ;;

  "check")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    ;;

  "add")
    if [[ $# -eq 0 ]]; then
      pgb_config=${PGB_CONFIG_NAME:-default}
      pgb_server=${PGB_PGSERVER_NAME:-default}
      pgb_source=default
    elif [[ $# -eq 1 ]]; then
      if [ "${1}x" == "asx" ]; then
        pgb_config=${PGB_CONFIG_NAME:-default}
        pgb_server=${PGB_PGSERVER_NAME:-default}
        pgb_source=default
        shift
      else
        pgb_config=${PGB_CONFIG_NAME:-default}
        pgb_server=${PGB_PGSERVER_NAME:-default}
        pgb_source=$1
        shift
      fi
    elif [[ $# -eq 2 ]]; then
      if [ "${1}x" == "asx" ]; then
        shift
        pgb_config=${PGB_CONFIG_NAME:-default}
        pgb_server=${PGB_PGSERVER_NAME:-default}
        pgb_source=$1
        shift
      else
        pgb_config=${PGB_CONFIG_NAME:-default}
        pgb_source=$1
        shift
        pgb_server=$1
        shift
      fi
    elif [[ $# -eq 3 ]]; then
      if [ "${1}x" == "asx" ]; then
        shift
        pgb_config=${PGB_CONFIG_NAME:-default}
        pgb_source=$1
        shift
        pgb_server=$1
        shift
      else
        pgb_source=$1
        shift
        pgb_config=$1
        shift
        pgb_server=$1
        shift
      fi
    else
      if [ "${1}x" == "asx" ]; then
        shift
        pgb_source=$1
        shift
        pgb_config=$1
        shift
        pgb_server=$1
        shift
      else
        exitError "${USAGE}\n"
      fi
    fi

    addServer ${pgb_source} ${pgb_config} ${pgb_server}
    if [[ $? -ne 0 ]]; then
      exitError "problem creating ${pgb_server} from ${pgb_source}"
    else
      printTrace "${pgb_server} added"
    fi
    ;;

  "configure")
    if [[ $# -ge 1 ]]; then
      pgb_command=$1
      shift
    else
      pgb_command=pgbrewer
    fi
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config="${PGB_CONFIG_NAME:-default}"
    fi

    if [ "${pgb_config}" == "default" ]; then
      pgb_config_dir=${PGB_CONF_DIR}
    else
      pgb_config_dir=${PGB_CONF_DIR}/${pgb_config}
    fi
    if [ "${pgb_command}x" == "listx" ]; then
      if [ ! -d ${pgb_config_dir} ]; then
        exitError "No config ${pgb_config}"
      fi
      for pgb_orig in ${pgb_config_dir}/*.conf
      do
        printf "$(basename ${pgb_orig%\.conf})\n"
      done
    else
      editConfig ${pgb_command} ${pgb_config}
      if [[ $? -ne 0 ]]; then
          exitError " problem editing ${pgb_config} ${pgb_command} configuration"
      fi
    fi
    ;;

  "compare")
    if [[ $# -lt 1 ]]; then
      exitError "${USAGE}"
    else
      pgb_source=$1
      shift
    fi
    if [[ $# -lt 1 ]]; then
      pgb_config=${PGB_CONFIG_NAME:-default}
    else
      pgb_config=$1
      shift
    fi
    compareConfig ${pgb_source} ${pgb_config} pgb_compare_config
    if [[ $? -ne 0 ]]; then
      printf "Configurations differs:\n${pgb_compare_config}\n"
    else
      printf "Same configuration\n"
    fi
    ;;

  "merge")
  "create" )
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi

    createConfig ${pgb_config}
    if [[ $? -ne 0 ]]; then
      exitError " problem creating ${pgb_config}"
    else
      printTrace " ${pgb_config} created"
    fi
    ;;

  "remove")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    removeConfig ${pgb_config}
    if [[ $? -ne 0 ]]; then
        exitError " problem removing ${pgb_config}"
    fi
    ;;

  "drop")
    if [[ $# -ge 1 ]]; then
      pgb_config=$1
      shift
    else
      pgb_config=${PGB_CONFIG_NAME:-default}
    fi
    deleteConfig ${pgb_config}
    if [[ $? -ne 0 ]]; then
        exitError " problem destroying ${pgb_config}"
    fi
    ;;

  *) exitError "${USAGE}\n"
    ;;
esac
                                                                                                 73,1           6%
"Usage: ${PRGNAME} FULLVERSION SRCDIR\nwhere\n\tFULLVERSION is the full PostgreSQL you are about to install (9.5.0)\n\tSRCDIR is the directory where you've put uncompressed source directory (/var/tmp/postgres-9.5.0-master)"

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
