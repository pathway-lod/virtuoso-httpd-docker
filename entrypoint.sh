#!/bin/bash
set -e

# Optional: configure Snorql (endpoint, examples repo, title, etc.)
if [ -x /script.sh ]; then
  /script.sh || echo "Warning: script.sh failed, continuing anyway"
fi

echo "Starting Virtuoso (openlink image)..."
/virtuoso-entrypoint.sh start &

# Give Virtuoso a few seconds to come up
sleep 5

echo "Preparing Apache run directory..."
mkdir -p /var/run/apache2
chown -R www-data:www-data /var/run/apache2

echo "Starting Apache..."
source /etc/apache2/envvars
exec apache2 -D FOREGROUND