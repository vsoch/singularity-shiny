# Singularity Shiny
Singularity Image to run a local shiny server.

## Build
Use the makefile

```
make
```

or build on your own:

```
sudo singularity build shiny.simg Singularity
```

## Generate Configuration
You will first generate a custom configuration for your user, and it will
give you instructions for usage:

```
$ /bin/bash prepare_template.sh
Generating shiny portal...
port: 9098
logs: /tmp/shiny-server.PtVRXE
base: /srv/shiny-server
Server logging will be in /tmp/shiny-server.PtVRXE

To run your server:

module load singularity/2.4.6
singularity run --bind /tmp/shiny-server.PtVRXE:/var/log/shiny --bind shiny-server.conf:/etc/shiny-server/shiny-server.conf shiny.simg

For custom applications, also add --bind /srv/shiny-server:/srv/shiny-server

To see your applications, open your browser to http://127.0.0.1:9098 or
open a ssh connection from your computer to your cluster.
```

The configuration is generated in your present working directory:

```
$ cat shiny-server.conf
run_as vanessa;
server {
  listen 9098;

  # Define a location at the base URL
  location / {

    # Host the directory of Shiny Apps stored in this directory
    site_dir /srv/shiny-server;

    # Log all Shiny output to files in this directory
    log_dir /tmp/shiny-server.PtVRXE;

    # When a user visits the base URL rather than a particular application,
    # an index of the applications available in this directory will be shown.
    directory_index on;
  }
}
```

Once you have that template, follow the instructions to run the container. The
temporary folder will be already created for you.

```
singularity run --bind /tmp/shiny-server.PtVRXE:/var/log/shiny --bind shiny-server.conf:/etc/shiny-server/shiny-server.conf shiny.simg
```
