FROM ghcr.io/element-hq/dendrite-monolith:latest

# Ставим envsubst (gettext) для подстановки переменных в конфиг
USER root
RUN apk add --no-cache gettext && \
    mkdir -p /etc/dendrite /var/dendrite && \
    chown -R dendrite:dendrite /etc/dendrite /var/dendrite

# Копируем шаблон конфига и entrypoint
COPY dendrite.yaml.template /etc/dendrite/dendrite.yaml.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Возвращаемся к пользователю dendrite (если он есть в образе)
USER dendrite

ENTRYPOINT ["/entrypoint.sh"]