#!/bin/bash

ENVIRONMENT_VAR_FILE=".env"
source "${ENVIRONMENT_VAR_FILE}"

POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_HOST_PORT="25432"

ETL_IMAGE_NAME="cde_docker_etl_image:latest"
ETL_CONTAINER_NAME="cde_docker_etl"

POSTGRES_CONTAINER_NAME="cde_docker_postgres"

# Stop and Remove container if it already exists
echo "Stopping and Removing ETL Container: ${ETL_CONTAINER_NAME}"
docker stop "${ETL_CONTAINER_NAME}"
echo "Stopping and Removing Postgres Container: ${POSTGRES_CONTAINER_NAME}"
docker stop "${POSTGRES_CONTAINER_NAME}"

docker rm "${ETL_CONTAINER_NAME}"
echo "Removed ETL Container: ${ETL_CONTAINER_NAME}"
docker rm "${POSTGRES_CONTAINER_NAME}"
echo "Removed Postgres Container: ${POSTGRES_CONTAINER_NAME}"

docker rmi "${ETL_IMAGE_NAME}"
echo "Removed ETL Image: ${ETL_IMAGE_NAME}"

# Build Image for the ETL Container
docker build -f Dockerfile --tag "${ETL_IMAGE_NAME}" .

docker network rm cde-docker-assignment

docker network create cde-docker-assignment

echo "Creating Postgres Container with connection credentials: Username: ${POSTGRES_USER}, Password: ${POSTGRES_PASSWORD}, Database: postgres, Port: ${POSTGRES_HOST_PORT}"
docker run -d -i -e POSTGRES_USER="${POSTGRES_USER}" -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} -e POSTGRES_DB=my_postgres_db  -p $POSTGRES_HOST_PORT:5432 --network cde-docker-assignment --name "${POSTGRES_CONTAINER_NAME}" postgres:14

# Time for Database Start-up before starting the ETL Process
sleep 20

echo "Creating ETL Container: ${ETL_CONTAINER_NAME} using Image: ${ETL_IMAGE_NAME}"
docker run -d -i --network cde-docker-assignment -e PG_HOST="${POSTGRES_CONTAINER_NAME}" -e PG_PORT=5432 -e PG_USER="${POSTGRES_USER}" -e PG_PASSWD="${POSTGRES_PASSWORD}" --name "${ETL_CONTAINER_NAME}" "${ETL_IMAGE_NAME}"
