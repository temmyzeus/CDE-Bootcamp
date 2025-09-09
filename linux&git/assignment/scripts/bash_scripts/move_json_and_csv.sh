#!/bin/bash

SOURCE_FOLDER=${1}
TARGET_FOLDER="json_and_CSV"

mkdir -p "${TARGET_FOLDER}"

mv "${SOURCE_FOLDER}/*.csv" "${SOURCE_FOLDER}/*.json" "${TARGET_FOLDER}"
