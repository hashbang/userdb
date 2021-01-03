FROM debian:buster

RUN adduser admin && \
    apt-get clean && \
    apt-get update && \
    apt-get install -y --force-yes \
        curl \
        nano \
        postgresql-client \
        python3-jwt \
        python3-psycopg2 \
        python3-requests \
        sudo \
        vim-nox \
        &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
    chown -R admin:admin /home/admin && \
    echo '%admin ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER admin

WORKDIR /home/admin

ENV LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color \
    USER="admin" \
    HOME="/home/admin"

COPY --chown=admin:admin . /home/admin/

CMD ["/bin/bash", "/home/admin/test.sh"]
