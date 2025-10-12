#!/bin/bash

etl_job_runner=$(realpath docker-compose.yaml)

docker compose -f "$etl_job_runner" build

crontab -l > mycron
echo "0 0 * * * docker compose -f ${etl_job_runner} up" >> mycron
crontab mycron

rm mycron
echo "✅ Scheduled ETL Job"
