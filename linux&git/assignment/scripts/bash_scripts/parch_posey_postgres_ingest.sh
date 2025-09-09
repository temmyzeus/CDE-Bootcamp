#!/bin/bash

# Load environment variables from .env file
# Variables that should be loaded from .env are
# 1. POSTGRES_HOST
# 2. POSTGRES_PORT
# 3. POSTGRES_USER
# 4. POSTGRES_PASSWD

PARENT_PATH=$(realpath $0 | xargs dirname | xargs dirname | xargs dirname)
echo "Parent Directory for script runtime: ${PARENT_PATH}"
cd "${PARENT_PATH}"

source .env
echo "🔃 Environment variables loaded"

FILE_URLS=(
    "https://raw.githubusercontent.com/jdbarillas/parchposey/refs/heads/master/data-raw/accounts.csv"
    "https://raw.githubusercontent.com/jdbarillas/parchposey/refs/heads/master/data-raw/orders.csv"
    "https://raw.githubusercontent.com/jdbarillas/parchposey/refs/heads/master/data-raw/region.csv"
    "https://raw.githubusercontent.com/jdbarillas/parchposey/refs/heads/master/data-raw/sales_reps.csv"
    "https://raw.githubusercontent.com/jdbarillas/parchposey/refs/heads/master/data-raw/web_events.csv"
)

download_dir="parch_and_posey_data_downloads"
mkdir -p "${download_dir}"

DB_NAME="posey"
echo "Attempting to create Database name: ${DB_NAME}"
export PGPASSWORD="${POSTGRES_PASSWD}"

echo "Connecting to Database Host: ${POSTGRES_HOST}:${POSTGRES_PORT}, via Username: ${POSTGRES_USER}"
psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "postgres" -v "ON_ERROR_STOP=0" -f "scripts/sql_scripts/create_databases.sql"
psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${DB_NAME}" -v "ON_ERROR_STOP=0" -f "scripts/sql_scripts/create_schemas.sql"
psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${DB_NAME}" -v "ON_ERROR_STOP=0" -f "scripts/sql_scripts/create_tables.sql"

for file_url in "${FILE_URLS[@]}"; do
  file_basename=$(basename "${file_url}")
  file_path="${download_dir%%/}/${file_basename}"
  table_name="${file_basename%.*}"

  if [ -f "${file_path}" ]; then
    echo "🔐 File ${file_basename} already exists in ${download_dir}. Skipping Download."
  else
    wget -P "${download_dir}" "${file_url}"
  fi

  echo "Loading file: ${file_path} into table ${DB_NAME}.${table_name}"
  psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${DB_NAME}" -v "ON_ERROR_STOP=0" -c "TRUNCATE TABLE ${DB_NAME}.${table_name};"
  psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${DB_NAME}" -v "ON_ERROR_STOP=0" -c "\copy ${DB_NAME}.${table_name} FROM '${file_path}' WITH CSV DELIMITER ',' HEADER;"

done
