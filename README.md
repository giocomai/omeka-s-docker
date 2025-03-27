# omeka-s-docker

This repository hosts a Dockerfile for easily deploying Omeka S with Docker. The core idea of these images is that they take care only of Omeka S core: you will need to take care of the config files, modules, and themes. 

In order to update, you normally just need to change the tag of the relevant image if you're taking this from Docker Hub, or update the relevant line in the Dockerfile if you build this image yourself.

## Environment Variables

You can configure the database connection using environment variables instead of editing the database.ini file directly:

| Variable    | Description                                   | Default |
|-------------|-----------------------------------------------|---------|
| DB_USER     | Database username                             | -       |
| DB_PASSWORD | Database password                             | -       |
| DB_NAME     | Database name                                 | -       |
| DB_HOST     | Database host                                 | -       |
| DB_PORT     | Database port (optional)                      | -       |
| DB_SOCKET   | Database unix socket path (optional)          | -       |
| DB_LOG_PATH | Database log path (optional)                  | -       |

## Docker Hub

Recent versions are available directly from Docker Hub  https://hub.docker.com/r/giocomai/omeka-s-docker

Check out the relevant tags. At this stage, the latest Omeka S Omeka S 4.1.1 is kept reasonably updated. 

## docker-compose examples

In this repository, you will find also a "docker-compose_traefik_example.yml". Adjust the lines where you find "FIXME" and, after adjusting relevant details in the `database.ini` file you should be good to go with a deployed Omeka S. 

In your `omekas` volume, you will have a `config` folder, and inside it a `database.ini` file.

Its contents should be something along the lines of:

```
user     = "secretstring"
password = "secretpassword"
dbname   = "secretstring"
host     = "omekas_db"
```
(obviously, fix these lines with the values you used in your docker-compose.yml)

If you use this in deployment, you'll probably want to have a look also at the `local.config.php` file in the same folder.

You will also find a "docker-compose_local_example.yml".  Adjust the lines where you find "FIXME", update your `database.ini` as shown above, and you should be good to go with an instance of Omeka S on your local machine at the 172.20.0.1 address. 

