#!/usr/bin/env bash

# Do not use recursive permissions update, as it generate high i/o workload on dev server
# Fix permission only to folder that directly mounted
chown $APPLICATION_UID:$APPLICATION_GID /app/shared

su -p application <<EOF
set -e

mkdir -p /app/shared/fileadmin \
  /app/shared/typo3temp \
  /app/shared/var/cache \
  /app/shared/var/log \
  /app/shared/uploads

php /app/source/vendor/bin/typo3 install:fixfolderstructure

EOF
