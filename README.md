# omeka-s-docker

This repository hosts a Dockerfile for easily deploying Omeka S with Docker. The core idea of these images is that they take care only of Omeka S core: you will need to take care of the config files, modules, and themes. 

In order to update, you normally just need to change the tag of the relevant image if you're taking this from Docker Hub, or update the relevant line in the Dockerfile if you build this image yourself. 

## Docker Hub

Recent versions are available directly from Docker Hub  https://hub.docker.com/r/giocomai/omeka-s-docker

Check out the relevant tags. At this stage, both Omeka S 3.2.3 and Omeka S 4.0.1 are kept reasonably updated. 

## docker-compose examples

In this repository, you will find also a "docker-compose_traefik_example.yml". Adjust the lines where you find "FIXME" and you should be good to go with a deployed Omeka S. 

You will also find a "docker-compose_local_example.yml".  Adjust the lines where you find "FIXME" and you should be good to go with an instance of Omeka S on your local machine at the 172.20.0.1 address. 
