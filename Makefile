run: clean build

clean:
	sudo rm -rf shiny.simg

build: clean
	sudo singularity build shiny.simg Singularity
