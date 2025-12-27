# Stage 1: Build Caddy with plugins
FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/mholt/caddy-ratelimit \
    --with github.com/porech/caddy-maxmind-geolocation

# Stage 2: Final image
FROM caddy:latest

WORKDIR /app

# Copy the custom binary from the builder
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY Caddyfile ./
COPY --chmod=755 entrypoint.sh ./

RUN caddy fmt --overwrite Caddyfile

ENTRYPOINT ["/bin/sh"]
CMD ["entrypoint.sh"]