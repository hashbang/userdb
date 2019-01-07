FROM python:alpine AS gen_schemas
RUN pip install --no-cache-dir PyYAML
ADD . /userdb
WORKDIR  /userdb
RUN /userdb/json-schemas.py

FROM alpine:latest
RUN apk --no-cache add make postgresql-client
ADD . /userdb
COPY --from=gen_schemas /userdb/json-schemas.sql.tmp /userdb/json-schemas.sql.tmp
WORKDIR  /userdb
ENTRYPOINT ["make"]
