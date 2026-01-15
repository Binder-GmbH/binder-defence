#!/usr/bin/env bash
# Change user, avoid root to be cache owner
su -p application <<EOF
set -e

echo "Waiting for database connection..."
/tmp/wait-for-it.sh \$MYSQL_HOST:\${MYSQL_PORT:-3306} -t 360

echo "Clearing cached config files..."
find /app/source/var/cache/ -type f -name "cached-config*.php" -delete 2>/dev/null || true

# TYPO3 13 removed database:updateschema command
# Database schema is now managed via extension:setup
# Skip for now - will be done via TYPO3 install tool

# Try to flush cache, but don't fail if cache tables don't exist yet
/app/source/vendor/bin/typo3 cache:flush || echo "Cache flush skipped (database not initialized)"
/app/source/vendor/bin/typo3 cache:warmup || echo "Cache warmup skipped (database not initialized)"

echo "Migration and cache operations are done!"
EOF
