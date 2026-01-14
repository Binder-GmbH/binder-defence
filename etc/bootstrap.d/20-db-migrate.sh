#!/usr/bin/env bash
# Change user, avoid root to be cache owner
su -p application <<EOF
set -e
set -o xtrace

/tmp/wait-for-it.sh \$MYSQL_HOST:\${MYSQL_PORT:-3306} -t 360
find /app/source/var/cache/ -type f -name "cached-config*.php" -delete -print
/app/source/typo3 database:updateschema "*.add,*.change" --verbose
/app/source/typo3 cache:flush
/app/source/typo3 cache:warmup

echo "Migration and cache clear are done!"
EOF
