# omeka-s-docker

This repository hosts a Dockerfile for easily deploying Omeka S with Docker. The core idea of these images is that they take care only of Omeka S core: you will need to take care of the config files, modules, and themes. 

In order to update, you normally just need to change the tag of the relevant image if you're taking this from Docker Hub, or update the relevant line in the Dockerfile if you build this image yourself.

## Environment Variables

You can configure the database connection using environment variables instead of editing the database.ini file directly:

| Variable                | Description                            | Default      |
|-------------------------|----------------------------------------|--------------|
| MYSQL_USER              | Database username                      |              |
| MYSQL_PASSWORD          | Database password                      |              |
| MYSQL_DATABASE          | Database name                          |              |
| MYSQL_HOST              | Database host                          |              |
| MYSQL_PORT              | Database port (optional)               | 3306         |
| MYSQL_SOCKET            | Database unix socket path (optional)   |              |
| MYSQL_LOG_PATH          | Database log path (optional)           |              |
| APPLICATION_ENV         | App mode: development or production    | production   |
| OMEKA_THEMES            | List of theme URLs (GitHub repo or zip)|              |
| OMEKA_MODULES           | List of module URLs (GH repo or zip)   |              |
| PHP_MEMORY_LIMIT        | PHP memory limit (e.g. 512M)           | 512M         |
| PHP_UPLOAD_MAX_FILESIZE | Max upload file size (e.g. 64M)        | 128M         |
| PHP_POST_MAX_SIZE       | Max post size (e.g. 64M)               | 128M         |
| PHP_MAX_EXECUTION_TIME  | Max script execution time (seconds)    | 300          |
| OMEKA_ADMIN_EMAIL       | Email for the first Omeka S admin user |              |
| OMEKA_ADMIN_NAME        | Name of the first admin user           |              |
| OMEKA_ADMIN_PASSWORD    | Password for the admin user            |              |
| OMEKA_SITE_TITLE        | Public title of the Omeka S site       |              |
| OMEKA_TIMEZONE          | Installation timezone (optional)       | UTC          |
| OMEKA_LOCALE            | Interface locale (optional)            | en_US        |
| OMEKA_BLUEPRINT         | Blueprint path or URL (optional)       |              |
| OMEKA_BLUEPRINT_ON_ERROR| On blueprint failure: `abort` or `warn`| abort        |

> If the `OMEKA_ADMIN_` variables (`EMAIL`, `NAME`, `PASSWORD`, `SITE_TITLE`) are not set, Omeka S will not be configured automatically at startup.

## Docker Hub

Recent versions are available directly from Docker Hub  https://hub.docker.com/r/giocomai/omeka-s-docker

Check out the relevant tags. At this stage, the latest Omeka S Omeka S 4.2.0 is kept reasonably updated. 

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

## Applying an Omeka S Blueprint

A blueprint is a declarative JSON file describing an Omeka S environment: modules, themes, settings, users and more. Its format is the shared, implementation-independent [Omeka S Blueprints](https://github.com/omeka-s-contrib/omeka-s-blueprints) specification ([documentation](https://omeka-s-contrib.github.io/omeka-s-blueprints/)), also used by [Omeka S Playground](https://github.com/ateeducacion/omeka-s-playground): a blueprint that only uses sections supported by both works in either.

Set `OMEKA_BLUEPRINT` to apply a blueprint at container startup. It accepts a path inside the container or a URL (including GitHub `blob` URLs and `gh:owner/repo@ref:path`). The blueprint is processed by [Omeka-S-Cli](https://github.com/GhentCDH/Omeka-S-Cli) v0.17.1, bundled in the image as `omeka-s-cli`, not by custom container code.

### Example

In your `docker-compose.yml`:

```yaml
services:
  omeka:
    image: your-image:latest
    environment:
      OMEKA_BLUEPRINT: /config/blueprint.json
    volumes:
      - ./blueprint.json:/config/blueprint.json:ro
```

Or with a URL: `OMEKA_BLUEPRINT: https://example.org/blueprint.json`.

See `blueprint_example.json` for a small blueprint that activates the `Common` module and sets the installation title; `docker-compose_local_example.yml` contains the lines to use it, commented out. To check a blueprint without applying it, use `omeka-s-cli blueprint:validate /config/blueprint.json` inside the container.

### How it works

At every startup, after `OMEKA_THEMES`, `OMEKA_MODULES` and the installation from the `OMEKA_ADMIN_` variables, the container runs:

```sh
omeka-s-cli blueprint:deploy "$OMEKA_BLUEPRINT" --base-path /var/www/html --skip core --force
```

* Omeka S must already be installed, either from the `OMEKA_ADMIN_` variables or through the web installer (restart the container afterwards).
* The blueprint's `install` section is **not** applied (`--skip core`): this image keeps its own installation, so the admin account, title, timezone and locale still come from `OMEKA_ADMIN_*`, `OMEKA_SITE_TITLE`, `OMEKA_TIMEZONE` and `OMEKA_LOCALE`. There is no need to repeat credentials in the blueprint. With the core phase skipped, `--force` only allows deploying onto the installed instance; nothing is reset.
* `OMEKA_MODULES` and `OMEKA_THEMES` work as before. A module they download is used as is by the blueprint, which can then install and activate it.
* Deploying is idempotent, so the blueprint is applied on every start: modules and themes already present are kept, existing users are left untouched, and `settings` and `files` are written again (overwriting changes made in the admin interface).

### Errors

`OMEKA_BLUEPRINT_ON_ERROR` sets what happens when the blueprint cannot be applied (Omeka-S-Cli unavailable, Omeka S not installed or its database unreachable, unreadable file, unreachable URL, invalid blueprint or failed deployment):

* `abort` (default): log the error and stop the container.
* `warn`: log the error and start Omeka S anyway.

Any other value stops the container.

### Supported sections

Omeka-S-Cli validates the whole blueprint against the schema, but v0.17.1 applies only part of it:

| Section | Applied by this image |
|---|---|
| `modules`, `themes`, `files`, `vocabularies`, `resourceTemplates`, `users`, `settings` | Yes |
| `install` | No, the image installs Omeka S itself (see above) |
| `sites`, `items`, `itemSets` | No, not applied by Omeka-S-Cli yet |
| `meta`, `preferredVersions`, `x-*` extensions | Ignored |

### Secrets

The specification allows passwords in `users`, stored in clear text. Do not commit real passwords in blueprints: keep production credentials in environment variables or your secrets management, and declare users without a `password`, setting it afterwards from the admin interface.
