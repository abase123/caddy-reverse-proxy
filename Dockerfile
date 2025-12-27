FROM caddy:2-builder AS builder

# Build Caddy with rate limiting plugin
RUN xcaddy build \
    --with github.com/mholt/caddy-ratelimit

FROM caddy:latest

WORKDIR /app

# Copy the custom-built Caddy binary with rate limiting support
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY Caddyfile ./

COPY --chmod=755 entrypoint.sh ./

RUN caddy fmt --overwrite Caddyfile

ENTRYPOINT ["/bin/sh"]

CMD ["entrypoint.sh"]