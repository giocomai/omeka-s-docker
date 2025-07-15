# omeka-s-docker

This repository hosts a Dockerfile for easily deploying Omeka S with Docker. The core idea of these images is that they take care only of Omeka S core: you will need to take care of the config files, modules, and themes. 

In order to update, you normally just need to change the tag of the relevant image if you're taking this from Docker Hub, or update the relevant line in the Dockerfile if you build this image yourself.

## Environment Variables

You can configure the database connection using environment variables instead of editing the database.ini file directly:

| Variable                | Description                            | Default      |
|-------------------------|----------------------------------------|--------------|
| MYSQL_DATABASE_USER     | Database username                      |              |
| MYSQL_DATABASE_PASSWORD | Database password                      |              |
| MYSQL_DATABASE_NAME     | Database name                          |              |
| MYSQL_DATABASE_HOST     | Database host                          |              |
| MYSQL_DATABASE_PORT     | Database port (optional)               | 3306         |
| MYSQL_DATABASE_SOCKET   | Database unix socket path (optional)   |              |
| MYSQL_DATABASE_LOG_PATH | Database log path (optional)           |              |
| APPLICATION_ENV         | App mode: development or production    | production   |
| OMEKA_THEMES            | List of theme URLs (GitHub repo or zip)|              |
| OMEKA_MODULES           | List of module URLs (GH repo or zip)   |              |
| PHP_MEMORY_LIMIT        | PHP memory limit (e.g. 512M)           | 512M         |
| PHP_UPLOAD_MAX_FILESIZE | Max upload file size (e.g. 64M)        | 128M         |
| PHP_POST_MAX_SIZE       | Max post size (e.g. 64M)               | 128M         |
| PHP_MAX_EXECUTION_TIME  | Max script execution time (seconds)    | 300          |

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

## Installing Themes Automatically

You can automatically download and install themes by setting the `OMEKA_THEMES` environment variable.

Each entry in this variable must be either:

* A **direct URL to a ZIP file**, pointing to a valid Omeka S theme archive.
* A **GitHub repository URL**, from which the latest release ZIP will be automatically resolved.

Use one URL per line.

The ZIP file is expected to contain a single folder at its root. This folder will be extracted into the `themes` directory inside the container or your persistent volume.

### Example

In your `docker-compose.yml`:

```yaml
services:
  omeka:
    image: your-image:latest
    environment:
      OMEKA_THEMES: |
        https://github.com/omeka-s-themes/freedom
        https://github.com/omeka-s-themes/default/releases/download/v1.9.1/theme-default-v1.9.1.zip 
```
When the container starts, it will:

1. Download the ZIP file from the URL.
2. Extract it into `/var/www/html/volume/themes/`.
3. Set the proper file permissions.

If the theme is already present in the `themes` directory, the download will be skipped.

## Installing Modules Automatically

You can also automatically install modules by setting the `OMEKA_MODULES` environment variable. This should contain one or more URLs (one per line) pointing to GitHub repositories or ZIP files of valid Omeka S modules.

The ZIP archives are expected to contain a single folder at their root. These folders will be extracted into the `modules` directory inside your persistent volume.

### Example

In your `docker-compose.yml`:

```yaml
services:
  omeka:
    image: your-image:latest
    environment:
      OMEKA_MODULES: |
        https://github.com/Daniel-KM/Omeka-S-module-Common
        https://github.com/Daniel-KM/Omeka-S-module-EasyAdmin/releases/download/3.4.29/EasyAdmin-3.4.29.zip
```

At container startup:

1. Each ZIP file will be downloaded.
2. Its contents will be extracted into `/var/www/html/volume/modules/`.
3. Permissions will be set accordingly.

If a module is already present in the `modules` directory, the download will still proceed unless you implement further logic for skipping.
