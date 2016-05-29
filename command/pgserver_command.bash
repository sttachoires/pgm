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
. @CONFDIR@/default/pgserver/default/pgserver.conf
. ${PGB_LIB_DIR}/util.include
. ${PGB_LIB_DIR}/pgserver.include

export PGS_LOG="${PGB_LOG_DIR}/pgserver.log"

export PGS_ACTIONS="\
list +config+
info +config+ +server+
check +config+ +server+
add +config+ !server!
add as +config+ +server+ +config+ !server!
configure +config+ +server+
compare +config+ +server+ +config+ +server+
scan +config+
install +config+ +server+
uninstall +config+ +server+
drop +config+ -server-"

export PGS_ACTIONS_DESCRIPTION="\
list
list available ${PRGNAME} servers actives or removed

info +config+ +server+
will provide information about a server

check +config+ +server+
will check for the server configuration validity, missing directories or files, etc...

add +config+ !server!
add (reference) a new server from default one, allow configuration edition

add as +config+ +server+ +config+ !server!
same as above but will inspire from first server

configure +config+ +server+
edit server configuration file, could be 'server' to edit environment configuration or 'postgresql' or 'pg_hba' or 'ident'

compare +config+ +server+ +config+ +server+
compare two server environments, issuing every differents parameters

scan +config+
scan for installed server and ask to import them into config

install +config+ +server+
install server, that's, make install

remove +config+ +server+
remove server, no deletion, listed a removed, but be empty, no database, replication, whatsoever
 
drop +config+ -server-
perform actual server removal by deletion
"

export PGS_SHORT_DESCRIPTION="\
pgserver command will help handle PostgreSQL server, with, potentialy,
differents directory, instances configuration, compilation..."

export PGS_LONG_DESCRIPTION="\
${PGS_SHORT_DESCRIPTION}

${PGS_GENERAL_PHILOSOPHY_DESCRIPTION}
Actions:\n${PGS_ACTIONS_DESCRIPTION}"

export PGS_USAGE="\
${PGS_GENERAL_SHORT_DESCRIPTION}

${PRGNAME}
Description:
${PGS_SHORT_DESCRIPTION}
${PRGNAME} action [parameters]
Where actions are:
${PGS_ACTIONS//$'\n'/$'\n'$'\t'}"

export PGS_HELP="\
${PGS_GENERAL_SHORT_DESCRIPTION}
${PGS_LONG_DESCRIPTION}
"

analyzeStandart $*

if [[ $# -gt 0 ]]; then
  pgs_action=$1
  shift
else
  exitError 1 "No action\n${PGB_USAGE}"
fi

case "${pgs_action}" in
  "completion")
    if [[ $# -ge 1 ]]; then
      pgs_comp_cword=$1
      shift
    else
      pgs_comp_cword=0
    fi

    pgs_var_name="pgs_previous"
    for ((; ${pgs_comp_cword} > 0; pgs_comp_cword-- ))
    do
      eval ${pgs_var_name}=${!pgs_comp_cword}
      pgs_var_name="${pgs_var_name}_previous"
    done
    pgs_completion=""
    # correct case of command to configure is same as current
    if [ "${pgs_previous}x" == "pgserverx" ] && [[ ${pgs_comp_cword} -ne 1 ]]; then
      pgs_previous="pgs_previous"
    fi
    case "${pgs_previous}" in
      "pgserver" )
        pgs_completion=`printf "${PGS_ACTIONS}\n" | awk '{ print $1 }'`
        pgs_completion="${pgs_completion//$'\n'/' '}"
        ;;

      "actions"|"usage"|"help")
        pgs_completion=""
        ;;

      "info"|"configure"|"check"|"install"|"remove"|"drop"|"compare")
        getAllConfigurations pgs_config_list
        pgs_completion="${pgs_config_list//$'\n'/' '}"
        ;;

      "add")
        pgs_completion="as NAME"
        ;;

      "list")
        pgs_completion="all NOTHING"
        ;;

      "as")

  "actions")
    printf "${PGS_ACTIONS}\n"
    ;;

  "usage")
    printf "${PGS_ACTIONS_DESCRIPTION}\n"
    ;;

  "help")
    printf "${PGS_HELP}\n"
    ;;

  "list")
    if [[ $# -eq 0 ]]; then
      pgs_config=${PGB_CONFIG_NAME:-default}
    else
      pgs_config=$1
    fi
    getInstalledServers ${pgs_config} pgs_server_list
    if [[ $? -ne 0 ]]; then
      exitError 2 "error getting server list"
    fi
    getAddedServers ${pgs_config} pgs_added_server_list
    if [[ $? -ne 0 ]]; then
      exitError 3 "error getting added server list"
    fi
    if [ "${pgs_server_list// }x" == "x" ] && [ "${pgs_added_server_list// }x" == "x" ]; then
      printf "No server.\n"
    else
      if [ "${pgs_server_list}x" != "x" ]; then
        printf "Active servers:\n${pgs_server_list// /$'\n'}\n"
      fi
      if [ "${pgs_added_server_list}x" != "x" ]; then
        if [ "${pgs_server_list}x" != "x" ]; then
          printf "\n"
        fi
        printf "Added servers:\n${pgs_added_server_list// /$'\n'}\n"
      fi
    fi
    ;;

  "info")
    if [[ $# -ge 1 ]]; then
      pgs_config=$1
      shift
    else
      pgs_config=${PGB_CONFIG_NAME:-default}
    fi
    if [[ $# -ge 1 ]]; then
      pgs_server=$1
      shift
    else
      pgs_server=${PGS_SERVER_NAME:-default}
    fi
    getConfigVars ${pgs_config} pgs_config_vars_list
    getServerVars ${pgs_config} ${pgs_server} pgs_server_vars_list
    printf "${pgs_config_vars_list}\n"
    printf "${pgs_server_vars_list}\n"
    ;;

  "check")
    if [[ $# -ge 1 ]]; then
      pgs_config=$1
      shift
    else
      pgs_config=${PGB_CONFIG_NAME:-default}
    fi
    ;;

  "add")
    if [[ $# -eq 0 ]]; then
      pgs_config=${PGB_CONFIG_NAME:-default}
      pgs_server=${PGB_PGSERVER_NAME:-default}
      pgs_source=default
    elif [[ $# -eq 1 ]]; then
      if [ "${1}x" == "asx" ]; then
        pgs_config=${PGB_CONFIG_NAME:-default}
        pgs_server=${PGB_PGSERVER_NAME:-default}
        pgs_source=default
        shift
      else
        pgs_config=${PGB_CONFIG_NAME:-default}
        pgs_server=${PGB_PGSERVER_NAME:-default}
        pgs_source=$1
        shift
      fi
    elif [[ $# -eq 2 ]]; then
      if [ "${1}x" == "asx" ]; then
        shift
        pgs_config=${PGB_CONFIG_NAME:-default}
        pgs_server=${PGB_PGSERVER_NAME:-default}
        pgs_source=$1
        shift
      else
        pgs_config=${PGB_CONFIG_NAME:-default}
        pgs_source=$1
        shift
        pgs_server=$1
        shift
      fi
    elif [[ $# -eq 3 ]]; then
      if [ "${1}x" == "asx" ]; then
        shift
        pgs_config=${PGB_CONFIG_NAME:-default}
        pgs_source=$1
        shift
        pgs_server=$1
        shift
      else
        pgs_source=$1
        shift
        pgs_config=$1
        shift
        pgs_server=$1
        shift
      fi
    else
      if [ "${1}x" == "asx" ]; then
        shift
        pgs_source=$1
        shift
        pgs_config=$1
        shift
        pgs_server=$1
        shift
      else
        exitError "${USAGE}\n"
      fi
    fi

    addServer ${pgs_source} ${pgs_config} ${pgs_server}
    if [[ $? -ne 0 ]]; then
      exitError "problem creating ${pgs_server} from ${pgs_source}"
    else
      printTrace "${pgs_server} added"
    fi
    ;;

  "configure")
    if [[ $# -ge 1 ]]; then
      pgs_command=$1
      shift
    else
      pgs_command=pgbrewer
    fi
    if [[ $# -ge 1 ]]; then
      pgs_config=$1
      shift
    else
      pgs_config="${PGB_CONFIG_NAME:-default}"
    fi

    if [ "${pgs_config}" == "default" ]; then
      pgs_config_dir=${PGB_CONF_DIR}
    else
      pgs_config_dir=${PGB_CONF_DIR}/${pgs_config}
    fi
    if [ "${pgs_command}x" == "listx" ]; then
      if [ ! -d ${pgs_config_dir} ]; then
        exitError "No config ${pgs_config}"
      fi
      for pgs_orig in ${pgs_config_dir}/*.conf
      do
        printf "$(basename ${pgs_orig%\.conf})\n"
      done
    else
      editConfig ${pgs_command} ${pgs_config}
      if [[ $? -ne 0 ]]; then
          exitError " problem editing ${pgs_config} ${pgs_command} configuration"
      fi
    fi
    ;;

  "compare")
    if [[ $# -lt 1 ]]; then
      exitError "${USAGE}"
    else
      pgs_source=$1
      shift
    fi
    if [[ $# -lt 1 ]]; then
      pgs_config=${PGB_CONFIG_NAME:-default}
    else
      pgs_config=$1
      shift
    fi
    compareConfig ${pgs_source} ${pgs_config} pgs_compare_config
    if [[ $? -ne 0 ]]; then
      printf "Configurations differs:\n${pgs_compare_config}\n"
    else
      printf "Same configuration\n"
    fi
    ;;

  "merge")
    printError "Not implemented yet\n"
    ;;

  "create" )
    if [[ $# -ge 1 ]]; then
      pgs_config=$1
      shift
    else
      pgs_config=${PGB_CONFIG_NAME:-default}
    fi

    if [[ $# -ge 1 ]]; then
      pgs_server=$1
      shift
    else
      pgs_server=${PGB_SERVER_NAME:-default}
    fi

    installServer ${pgs_config} ${pgs_server}
if [[ $? -ne 0 ]]; then
  printError "Error installing ${pgs_srcdir} ${pgs_server}\n"
else
  printf "PostgreSQL ${PGB_PGFULL_VERSION} installed in ${PGB_PGHOME_DIR}\n"
fi
    createConfig ${pgs_config}
    if [[ $? -ne 0 ]]; then
      exitError " problem creating ${pgs_config}"
    else
      printTrace " ${pgs_config} created"
    fi
    ;;

  "remove")
    if [[ $# -ge 1 ]]; then
      pgs_config=$1
      shift
    else
      pgs_config=${PGB_CONFIG_NAME:-default}
    fi
    removeConfig ${pgs_config}
    if [[ $? -ne 0 ]]; then
        exitError " problem removing ${pgs_config}"
    fi
    ;;

  "drop")
    if [[ $# -ge 1 ]]; then
      pgs_config=$1
      shift
    else
      pgs_config=${PGB_CONFIG_NAME:-default}
    fi
    deleteConfig ${pgs_config}
    if [[ $? -ne 0 ]]; then
        exitError " problem destroying ${pgs_config}"
    fi
    ;;

  *) exitError "${USAGE}\n"
    ;;
esac

