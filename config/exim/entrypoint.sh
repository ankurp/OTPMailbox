#!/bin/bash
set -e

# The config template is bind-mounted at /etc/exim4/exim4.conf.template
# Substitute env vars and write to the actual config path
sed "s|\${RELAY_URL}|${RELAY_URL}|g; s|\${RELAY_HOST}|${RELAY_HOST}|g; s|\${INGRESS_PASSWORD}|${ACTION_MAILBOX_INGRESS_PASSWORD}|g" \
  /etc/exim4/exim4.conf.template > /etc/exim4/exim4.conf

echo "Exim configured to relay to: ${RELAY_URL}"

# Ensure log directory/files exist and stream them to stdout so
# `docker logs` shows received mail and relay attempts
mkdir -p /var/log/exim4
touch /var/log/exim4/mainlog /var/log/exim4/rejectlog /var/log/exim4/paniclog
chown -R Debian-exim:Debian-exim /var/log/exim4
tail -F -n 0 /var/log/exim4/mainlog /var/log/exim4/rejectlog /var/log/exim4/paniclog &

exec "$@"
