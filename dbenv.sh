#/usr/bin/env bash
export OMEKA_DB_HOST=$(docker network inspect bridge | jq '.[].Containers | map(select(.Name == "db")) | .[].IPv4Address' | sed 's/"//' | sed 's/\/16"//')
export OMEKA_DB_NAME=omeka
export OMEKA_DB_USER=omeka
export OMEKA_DB_PASSWORD=omeka
