FROM ghcr.io/element-hq/dendrite-monolith:latest

# Ставим envsubst (gettext)
USER root
RUN apk add --no-cache gettext && \
    mkdir -p /etc/dendrite /var/dendrite

# Копируем шаблон конфига и entrypoint
COPY dendrite.yaml /etc/dendrite/dendrite.yaml.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]