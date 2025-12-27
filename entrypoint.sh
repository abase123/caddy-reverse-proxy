#!/bin/sh

set -euo pipefail

# for backwards compatibility, seperates host and port from url
export FRONTEND_DOMAIN=${FRONTEND_DOMAIN:-${FRONTEND_HOST%:*}}
export FRONTEND_PORT=${FRONTEND_PORT:-${FRONTEND_HOST##*:}}

export BACKEND_DOMAIN=${BACKEND_DOMAIN:-${BACKEND_HOST%:*}}
export BACKEND_PORT=${BACKEND_PORT:-${BACKEND_HOST##*:}}

# strip https:// or https:// from domain if necessary
FRONTEND_DOMAIN=${FRONTEND_DOMAIN##*://}
BACKEND_DOMAIN=${BACKEND_DOMAIN##*://}

echo "Using frontend: ${FRONTEND_DOMAIN} with port: ${FRONTEND_PORT}"
echo "Using backend: ${BACKEND_DOMAIN} with port: ${BACKEND_PORT}"

# Check if GeoIP database exists
if [ ! -f /usr/share/GeoIP/GeoLite2-Country.mmdb ]; then
    echo "WARNING: GeoLite2-Country.mmdb not found!"
    echo "Geo-blocking will not work without the MaxMind database."
    echo "Please download it from https://www.maxmind.com/en/geolite2/signup"
    
    # If MAXMIND_LICENSE_KEY is set, try to download the database
    if [ -n "${MAXMIND_LICENSE_KEY:-}" ]; then
        echo "MAXMIND_LICENSE_KEY found, attempting to download GeoLite2-Country database..."
        cd /usr/share/GeoIP
        curl -s -L "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=${MAXMIND_LICENSE_KEY}&suffix=tar.gz" | tar -xzf - --strip-components=1 --wildcards '*.mmdb'
        if [ -f /usr/share/GeoIP/GeoLite2-Country.mmdb ]; then
            echo "GeoLite2-Country database downloaded successfully!"
        else
            echo "ERROR: Failed to download GeoLite2-Country database"
        fi
    fi
fi

exec caddy run --config Caddyfile --adapter caddyfile 2>&1