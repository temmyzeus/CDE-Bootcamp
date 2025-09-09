#!/bin/bash

etl_script=$(realpath etl.sh)

crontab -l > mycron
echo "0 0 * * * ${etl_script}" >> mycron
crontab mycron

rm mycron
echo "✅ Scheduled ETL Script"
