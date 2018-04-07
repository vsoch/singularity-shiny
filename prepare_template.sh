#!/bin/bash

usage () {

    echo "Usage:
          When starting the application, provide a port and a base for your
               shiny applications, and a shiny server will be deployed there.

              shiny.simg [start|help]
              shiny.simg start --port 3737 --base /path/to/apps

          Commands:
             help: show help and exit
             start: the generation of your config

          Options:  
           --port:  the port for the application (e.g., shiny default is 3737)
           --base: base folder with applications
           --logs: temporary folder with write for logs (not required)
           --disable-index: disable directory indexing

         "
}

# Start the application
SHINY_START="no";

# Port for Flask
SHINY_PORT=$(tr -cd 0-9 </dev/urandom | head -c 4);

# Base for apps
SHINY_BASE=/srv/shiny-server;

# Log folder assumed to be bound to
SHINY_LOGS=$(mktemp -d /tmp/shiny-server.XXXXXX) && rmdir ${SHINY_LOGS};

# Disable indexing (on, default, is not disabled)
DISABLE_DIRINDEX="on";

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
    CONFIG="run_as docker;
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

    echo "Generating shiny portal...";
    echo "port: ${SHINY_PORT}";
    echo "logs:" ${SHINY_LOGS};
    echo "base: ${SHINY_BASE}";

    # Prepare the template
    
    CONFIG=$(prepare_conf $SHINY_PORT $SHINY_BASE $SHINY_LOGS $DISABLE_DIRINDEX);
    
    # Temporary directory, if doesn't exist
    if [ ! -d "${SHINY_LOGS}" ]; then
        mkdir -p ${SHINY_LOGS}/logs;
        mkdir -p ${SHINY_LOGS}/lib;
    fi

    # Configuration file
    echo "${CONFIG}" > "shiny-server.conf";
    echo "Server logging will be in ${SHINY_LOGS}";
    echo
    echo "To run your server:

module load singularity/2.4.6
singularity run --bind $SHINY_LOGS/logs:/var/log/shiny \
--bind $SHINY_LOGS/lib:/var/lib/shiny-server \
--bind shiny-server.conf:/etc/shiny-server/shiny-server.conf \
shiny.simg

For custom applications, also add --bind $SHINY_BASE:/srv/shiny-server

To see your applications, open your browser to http://127.0.0.1:$SHINY_PORT or
open a ssh connection from your computer to your cluster.
"
    exit
else
    usage
fi
