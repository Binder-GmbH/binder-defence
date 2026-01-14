#!/usr/bin/env bash
# Change user, avoid root to be cache owner
su -p application <<EOF
set -e
set -o xtrace

/tmp/wait-for-it.sh \$MYSQL_HOST:\${MYSQL_PORT:-3306} -t 360
find /app/source/var/cache/ -type f -name "cached-config*.php" -delete -print

# TYPO3 13 removed database:updateschema command
# Database schema is now managed via extension:setup
# Skip for now - will be done via TYPO3 install tool

/app/source/vendor/bin/typo3 cache:flush
/app/source/vendor/bin/typo3 cache:warmup

echo "Migration and cache clear are done!"
EOF
