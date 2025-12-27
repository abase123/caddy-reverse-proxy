# Build stage - compile Caddy with required plugins
FROM caddy:builder-alpine AS builder

RUN xcaddy build \
    --with github.com/mholt/caddy-ratelimit \
    --with github.com/porech/caddy-maxmind-geolocation

# Runtime stage
FROM caddy:latest

WORKDIR /app

# Install curl for downloading GeoIP database
RUN apk add --no-cache curl ca-certificates

# Copy the custom-built Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Copy configuration files
COPY Caddyfile ./
COPY --chmod=755 entrypoint.sh ./

# Create directory for GeoIP database
RUN mkdir -p /usr/share/GeoIP

# Copy GeoIP database (you need to download this from MaxMind)
# COPY GeoLite2-Country.mmdb /usr/share/GeoIP/

RUN caddy fmt --overwrite Caddyfile

ENTRYPOINT ["/bin/sh"]
CMD ["entrypoint.sh"]