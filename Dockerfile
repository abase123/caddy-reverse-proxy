FROM caddy:2-builder-alpine AS builder

RUN xcaddy build \
    --with github.com/mholt/caddy-ratelimit

FROM alpine:latest

RUN apk add --no-cache ca-certificates

WORKDIR /app

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY Caddyfile ./
COPY --chmod=755 entrypoint.sh ./

RUN /usr/bin/caddy fmt --overwrite Caddyfile

ENTRYPOINT ["/bin/sh"]
CMD ["entrypoint.sh"]