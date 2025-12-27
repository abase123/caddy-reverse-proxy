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
    echo "GeoLite2-Country.mmdb not found, checking for license key..."
    
    # If MAXMIND_LICENSE_KEY is set, try to download the database
    if [ -n "${MAXMIND_LICENSE_KEY:-}" ]; then
        echo "MAXMIND_LICENSE_KEY found, downloading GeoLite2-Country database..."
        
        # Download to temp file first
        TEMP_FILE="/tmp/geolite2-country.tar.gz"
        
        curl -fsSL -o "$TEMP_FILE" \
            "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=${MAXMIND_LICENSE_KEY}&suffix=tar.gz"
        
        if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
            echo "Download successful, extracting..."
            
            # Extract the .mmdb file
            cd /tmp
            tar -xzf "$TEMP_FILE"
            
            # Find and move the .mmdb file
            find /tmp -name "GeoLite2-Country.mmdb" -exec mv {} /usr/share/GeoIP/ \;
            
            # Cleanup
            rm -rf "$TEMP_FILE" /tmp/GeoLite2-Country_*
            
            if [ -f /usr/share/GeoIP/GeoLite2-Country.mmdb ]; then
                echo "GeoLite2-Country database installed successfully!"
            else
                echo "ERROR: Failed to extract GeoLite2-Country database"
                exit 1
            fi
        else
            echo "ERROR: Failed to download GeoLite2-Country database"
            echo "Please check your MAXMIND_LICENSE_KEY"
            exit 1
        fi
    else
        echo "ERROR: MAXMIND_LICENSE_KEY not set!"
        echo "Geo-blocking requires the MaxMind GeoLite2-Country database."
        echo "Please set the MAXMIND_LICENSE_KEY environment variable."
        echo "Get a free license key at: https://www.maxmind.com/en/geolite2/signup"
        exit 1
    fi
else
    echo "GeoLite2-Country database found."
fi

exec caddy run --config Caddyfile --adapter caddyfile 2>&1