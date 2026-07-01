#!/bin/bash
set -e

# Substitute environment variables into exim config
sed -i "s|\${RELAY_URL}|${RELAY_URL}|g" /etc/exim4/exim4.conf
sed -i "s|\${INGRESS_PASSWORD}|${INGRESS_PASSWORD}|g" /etc/exim4/exim4.conf

echo "Exim configured to relay to: ${RELAY_URL}"

exec "$@"
