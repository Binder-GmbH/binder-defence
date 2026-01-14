#!/usr/bin/env bash

# Do not use recursive permissions update, as it generate high i/o workload on dev server
# Fix permission only to folder that directly mounted
chown $APPLICATION_UID:$APPLICATION_GID /app/shared

su -p application <<EOF
set -e

# Ensure mounted directories have correct structure
mkdir -p /app/source/var/cache \
  /app/source/var/log \
  /app/source/public/fileadmin \
  /app/source/public/typo3temp

# Shared folder for additional data
mkdir -p /app/shared/uploads

# install:fixfolderstructure does not exist in TYPO3 13
# Folders are created by mkdir above

EOF
