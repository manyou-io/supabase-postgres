ARG VERSION="14.6-bullseye"

FROM postgres:$VERSION

ENV DEBIAN_FRONTEND noninteractive

RUN --mount=type=bind,source=ansible,target=/ansible \
    set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends ansible sudo; \
    cd /ansible; \
    ansible-playbook -e '{"async_mode": false}' playbook-docker.yml; \
    apt-get install -y --no-install-recommends locales; \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen; \
    locale-gen; \
    apt-get purge --auto-remove -y ansible; \
    apt-get clean; \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

COPY ansible/files/pgbouncer_config/pgbouncer_auth_schema.sql /docker-entrypoint-initdb.d/00-schema.sql
COPY ansible/files/stat_extension.sql /docker-entrypoint-initdb.d/01-extension.sql
COPY ansible/files/sodium_extension.sql /docker-entrypoint-initdb.d/02-sodium-extension.sql
COPY migrations/db/ /docker-entrypoint-initdb.d/

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
