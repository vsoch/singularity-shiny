Bootstrap: docker
From: rocker/shiny

# sudo singularity build shiny.simg Singularity

%labels
maintainer vsochat@stanford.edu

%post
    mkdir -p /var/log/shiny-server
    chown shiny.shiny /var/log/shiny-server

%runscript
    exec shiny-server 2>&1
