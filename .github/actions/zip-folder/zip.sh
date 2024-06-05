#!/bin/bash

# Adapted from https://github.com/TheDoctor0/zip-release.
# Create an archive or exit if the command fails.

set -eu
printf "\n📦 Creating zip archive...\n"

if [ "$RUNNER_OS" = "Windows" ]; then
    if [ "$ARCHIVE_SPLIT" = 1 ]; then
        for name in $ARCHIVE_INCLUDE_PATH/*; do
            if [ -d "$name" ]; then
                include_path="$ARCHIVE_INCLUDE_PATH/$name/"
                7z a -tzip "$name.zip" $include_path || { printf "\n⛔ Unable to create zip archive from %s.\n" "$include_path"; exit 1; }
                printf "\n✔ Successfully created %s archive.\n" "$name.zip"
            fi
        done
    else
        7z a -tzip "$ARCHIVE_OUTPUT_NAME" $ARCHIVE_INCLUDE_PATH || { printf "\n⛔ Unable to create zip archive from %s.\n" "$ARCHIVE_INCLUDE_PATH"; exit 1; }
        printf "\n✔ Successfully created %s archive.\n" "$ARCHIVE_OUTPUT_NAME"
    fi
else
    if [ "$ARCHIVE_SPLIT" = 1 ]; then
        for name in $ARCHIVE_INCLUDE_PATH/*; do
            if [ -d "$name" ]; then
                include_path="$ARCHIVE_INCLUDE_PATH/$name/"
                zip -r "$name.zip" $include_path || { printf "\n⛔ Unable to create zip archive from %s.\n" "$include_path"; exit 1; }
                printf "\n✔ Successfully created %s archive.\n" "$name.zip"
            fi
        done
    else
        zip -r "$ARCHIVE_OUTPUT_NAME" $ARCHIVE_INCLUDE_PATH || { printf "\n⛔ Unable to create zip archive from %s.\n" "$ARCHIVE_INCLUDE_PATH"; exit 1; }
        printf "\n✔ Successfully created %s archive.\n" "$ARCHIVE_OUTPUT_NAME"
    fi
fi

