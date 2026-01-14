#!/usr/bin/env bash

# Do not use recursive permissions update, as it generate high i/o workload on dev server
# Fix permission only to folders that are directly mounted
chown $APPLICATION_UID:$APPLICATION_GID /app/shared /app/source/var /app/source/public/fileadmin /app/source/public/typo3temp || true

su -p application <<EOF
set -e

# Ensure subdirectories exist in mounted volumes
mkdir -p /app/source/var/cache \
  /app/source/var/log \
  /app/source/public/fileadmin \
  /app/source/public/typo3temp

# Remove FIRST_INSTALL if it exists (prevents "installation required" message)
rm -f /app/source/public/FIRST_INSTALL

# install:fixfolderstructure does not exist in TYPO3 13
# Folders are created by mkdir above

EOF
