FROM alpine:latest

COPY entrypoint.sh /entrypoint.sh

COPY configs /raw_configs

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]