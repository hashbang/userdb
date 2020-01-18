ARG DEBIAN_REF=f19be6b8095d6ea46f5345e2651eec4e5ee9e84fc83f3bc3b73587197853dc9e
ARG POSTGRES_REF=3657548977d593c9ab6d70d1ffc43ceb3b5164ae07ac0f542d2ea139664eb6b3

FROM debian@sha256:${DEBIAN_REF} as schema
RUN apt update \
    && apt install -y python3 python3-yaml \
    && rm -rf /var/lib/apt/lists/*
ADD . /userdb
RUN /userdb/scripts/build /userdb/schema /out

FROM postgres@sha256:${POSTGRES_REF}
COPY --from=schema /out /docker-entrypoint-initdb.d/
