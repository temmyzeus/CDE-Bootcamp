#!/bin/bash

# Load environment variables from .env.etl file
source .env.etl
echo "🔃 Environment variables loaded"

# List of variables loaded from the .env file
# EXTRACT_FILE_URL=

# Extract Layer Start
EXTRACT_TARGET_DIR="raw"
FILENAME=$(basename "${EXTRACT_FILE_URL}")

# Create the extract difrectory, incase it does not exist.
mkdir -p "${EXTRACT_TARGET_DIR}"

EXTRACTED_FILE_PATH="${EXTRACT_TARGET_DIR%%/}/${FILENAME}"

if [ -f "${EXTRACTED_FILE_PATH}" ]; then
    echo "🔐 File already exists in ${EXTRACTED_FILE_PATH}. Skipping Download."
else
    wget -P "${EXTRACT_TARGET_DIR}" "${EXTRACT_FILE_URL}"

    if [ $? -eq 0 ]; then
        echo "✅ Successfully Downloaded File from URL: ${EXTRACT_FILE_URL} into ${EXTRACT_TARGET_DIR} Directory"
    else
        echo "❌ Failed to Downloaded File from URL: ${EXTRACT_FILE_URL} into ${EXTRACT_TARGET_DIR} Directory"
        exit 1
    fi
fi
# Extract Layer End

# Transform Layer Start

TRANSFORMED_LAYER_PATH="Transformed"
TRANSFORMED_FILE_BASENAME="2023_year_finance.csv"
mkdir -p "${TRANSFORMED_LAYER_PATH}"

TRANSFORMED_FILE_PATH="${TRANSFORMED_LAYER_PATH%%/}/${TRANSFORMED_FILE_BASENAME}"

# Rename column name & select subset columns
sed '1,1s/Variable_code/variable_code/g' | awk -F, '{ print $1,$9,$5,$6 }' > "${TRANSFORMED_FILE_PATH}"
echo "✅ Successfully Renamed Column & Selected Subset Columns ..."

if [ -f "${TRANSFORMED_FILE_PATH}" ] || [ $? != 0  ]; then
    echo "✅ Transform file ${TRANSFORMED_FILE_BASENAME} has been loaded into directory ${TRANSFORMED_LAYER_PATH}"
else
    echo "❌ Failed to Load the tranform file ${TRANSFORMED_FILE_BASENAME} into directory ${TRANSFORMED_LAYER_PATH}"
    exit 1
fi
# Tranform Layer End

# Load Layer Start
GOLD_LAYER_PATH="Gold"
mkdir -p "${GOLD_LAYER_PATH}"

cp "${TRANSFORMED_FILE_PATH}" "${GOLD_LAYER_PATH}"
GOLD_FILE_BASENAME=$(basename "${TRANSFORMED_FILE_PATH}")
GOLD_FILE_PATH="${GOLD_LAYER_PATH%%/}/${GOLD_FILE_BASENAME}"

if [ -f "${GOLD_FILE_PATH}" ] || [ $? != 0  ]; then
    echo "✅ Gold file ${GOLD_FILE_BASENAME} has been loaded into directory ${GOLD_FILE_PATH}"
else
    echo "❌ Failed to Load the tranform file ${GOLD_FILE_BASENAME} into directory ${GOLD_FILE_PATH}"
    exit 1
fi

# Load Layer End
