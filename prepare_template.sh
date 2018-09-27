#!/bin/bash

usage () {

    echo "Steps:
          ----------------------------------------------------------------------
          1. Use this script to prepare your shiny-server.conf (configuration)
 
               /bin/bash prepare_template.sh

          ----------------------------------------------------------------------
          2. If needed, you can provide the following arguments

          Commands:
             help: show help and exit
             start: the generation of your config

          Options:  
           --port:  the port for the application (e.g., shiny default is 3737)
           --user:  the user for the run_as directive in the shiny configuration
           --base: base folder with applications
           --logs: temporary folder with write for logs (not required)
           --disable-index: disable directory indexing

          ----------------------------------------------------------------------
          3. Make sure Singularity is loaded, and run the container using 
             the commands shown by the template.

         "
}

# Start the application
SHINY_START="no";

# Port for Flask
CHECK_PORT="notnull"
while [[ ! -z $CHECK_PORT ]]; do
    SHINY_PORT=$(( ( RANDOM % 60000 )  + 1025 ))
    CHECK_PORT=$(netstat -atn | grep $SHINY_PORT)
done

# Base for apps
SHINY_BASE=/srv/shiny-server;

# Log folder assumed to be bound to
SHINY_LOGS=$(mktemp -d /tmp/shiny-server.XXXXXX) && rmdir ${SHINY_LOGS};

# Disable indexing (on, default, is not disabled)
DISABLE_DIRINDEX="on";

# User to run_as, defaults to docker
SHINY_USER="${USER}"

if [ $# -eq 0 ]; then
    usage
    exit
fi

while true; do
    case ${1:-} in
        -h|--help|help)
            usage
            exit
        ;;
        -s|--start|start)
            SHINY_START="yes"
            shift
        ;;
        -p|--port|port)
            shift
            SHINY_PORT="${1:-}"
            shift
        ;;
        -u|--user)
            shift
            SHINY_USER="${1:-}"
            shift
        ;;
        -di|--disable-index|disable-index)
            DISABLE_DIRINDEX="off"
            shift
        ;;
        -l|logs|--logs)
            shift
            SHINY_LOGS="${1:-}"
            shift
        ;;
        -*)
            echo "Unknown option: ${1:-}"
            exit 1
        ;;
        *)
            break
        ;;
    esac
done

# Functions

function prepare_conf() {
    SHINY_PORT=$1
    SHINY_BASE=$2
    SHINY_LOGS=$3
    DISABLE_DIRINDEX=$4
    SHINY_USER=$5
    CONFIG="run_as ${SHINY_USER};
server {
  listen ${SHINY_PORT};

  # Define a location at the base URL
  location / {

    # Host the directory of Shiny Apps stored in this directory
    site_dir ${SHINY_BASE};

    # Log all Shiny output to files in this directory
    log_dir ${SHINY_LOGS};

    # When a user visits the base URL rather than a particular application,
    # an index of the applications available in this directory will be shown.
    directory_index ${DISABLE_DIRINDEX};
  }
}"
    echo "${CONFIG}";
}


# Are we starting the server?

if [ "${SHINY_START}" == "yes" ]; then

    echo "Generating shiny configuration...";
    echo "port: ${SHINY_PORT}";
    echo "logs:" ${SHINY_LOGS};
    echo "base: ${SHINY_BASE}";
    echo "run_as: ${SHINY_USER}";

    # Prepare the template
    
    CONFIG=$(prepare_conf $SHINY_PORT $SHINY_BASE $SHINY_LOGS $DISABLE_DIRINDEX $SHINY_USER);
    
    # Temporary directory, if doesn't exist
    if [ ! -d "${SHINY_LOGS}" ]; then
        mkdir -p ${SHINY_LOGS}/logs;
        mkdir -p ${SHINY_LOGS}/lib;
    fi

    # Configuration file
    echo "${CONFIG}" > "shiny-server.conf";
    echo "Server logging will be in ${SHINY_LOGS}";
    echo
    echo  "To run your server:

    module load singularity/2.4.6
    singularity run --bind $SHINY_LOGS/logs:/var/log/shiny \\
    --bind $SHINY_LOGS/lib:/var/lib/shiny-server \\
    --bind shiny-server.conf:/etc/shiny-server/shiny-server.conf shiny.simg

    ---------------------------------------------------------------------------
    For custom applications, also add --bind $SHINY_BASE:/srv/shiny-server
    To see your applications, open your browser to http://127.0.0.1:$SHINY_PORT or
    open a ssh connection from your computer to your cluster.
"
    exit
else
    usage
fi
