FROM debian:buster

RUN adduser admin && \
    apt-get clean && \
    apt-get update && \
    apt-get install -y --force-yes \
        sudo \
        bats \
        curl \
        nano \
        vim-nox \
        postgresql-client &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD . /home/admin/

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

CMD ["/bin/bash", "/home/admin/test.sh"]
