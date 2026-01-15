ARG BASE_IMAGE=docker.io/webdevops/php-nginx:8.4
FROM $BASE_IMAGE

ENV WEB_DOCUMENT_ROOT=/app/source/public \
    WEB_DOCUMENT_INDEX="index.php" \
    PROVISION_CONTEXT="production" \
    APPLICATION_UID="1000" \
    APPLICATION_GID="1000"

RUN apt-get update && \
    apt-get install -y gettext && \
    /usr/local/bin/docker-image-cleanup

# Deploy scripts/configurations
COPY ./etc/                        /opt/docker/etc/
COPY ./etc/bootstrap.d             /entrypoint.d
COPY ./etc/scripts/wait-for-it.sh  /tmp/wait-for-it.sh

RUN echo >> /opt/docker/etc/cron/crontab \
    && chmod 0644 /opt/docker/etc/cron/crontab \
    && chmod +x /tmp/wait-for-it.sh \
    && chmod +x /entrypoint.d/*.sh

RUN mkdir -p /app/shared && chown $APPLICATION_UID:$APPLICATION_GID /app/shared

COPY --chown=$APPLICATION_UID:$APPLICATION_GID ./source  /app/source
COPY --chown=$APPLICATION_UID:$APPLICATION_GID ./.env /app/source/.env
COPY --chown=$APPLICATION_UID:$APPLICATION_GID ./shared/.env.dist /app/source/.env.dist

# Configure volume/workdir
WORKDIR /app/source/
