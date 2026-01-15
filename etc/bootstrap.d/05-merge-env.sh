#!/bin/bash
# Merge .env.dist and .env files for TYPO3
# This ensures TYPO3__ variables from .env.dist are available alongside
# environment-specific variables from .env

ENV_FILE="/app/source/.env"
ENV_DIST_FILE="/app/source/.env.dist"
ENV_MERGED_FILE="/app/source/.env.merged"

# If .env exists and .env.dist exists, merge them
if [ -f "$ENV_FILE" ] && [ -f "$ENV_DIST_FILE" ]; then
    echo "Merging .env.dist and .env..."
    cat "$ENV_DIST_FILE" "$ENV_FILE" > "$ENV_MERGED_FILE"
    mv "$ENV_MERGED_FILE" "$ENV_FILE"
    echo ".env files merged successfully"
elif [ -f "$ENV_DIST_FILE" ] && [ ! -f "$ENV_FILE" ]; then
    echo "Only .env.dist exists, copying it to .env..."
    cp "$ENV_DIST_FILE" "$ENV_FILE"
fi
