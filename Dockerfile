ARG BASE_IMAGE=docker.io/webdevops/php-nginx:8.4
FROM $BASE_IMAGE

ENV WEB_DOCUMENT_ROOT=/app/source/public \
    WEB_DOCUMENT_INDEX="index.php" \
    APPLICATION_UID="1000" \
    APPLICATION_GID="1000"

RUN apt-get update && \
    apt-get install -y gettext && \
    /usr/local/bin/docker-image-cleanup

# Deploy scripts/configurations
COPY ./etc/ /opt/docker/etc/

RUN mkdir -p /app/shared && chown $APPLICATION_UID:$APPLICATION_GID /app/shared

COPY --chown=$APPLICATION_UID:$APPLICATION_GID ./source /app/source
COPY --chown=$APPLICATION_UID:$APPLICATION_GID ./shared/.env.dist /app/source/.env.dist

# Configure volume/workdir
WORKDIR /app/source/
