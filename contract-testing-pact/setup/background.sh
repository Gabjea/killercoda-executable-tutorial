#!/bin/bash
set -Eeuo pipefail
exec > >(tee -a /var/log/workshop-setup.log) 2>&1
trap 'echo "SETUP FAILED at line $LINENO"; touch /tmp/.setup-failed' ERR

ASSETS=/opt/workshop-assets
W=/root/workshop

echo "== Checking assets"
find "$ASSETS" -maxdepth 3 | head -40
[ -f "$ASSETS/workshop/docker-compose.yml" ] || { echo "Assets not where expected"; false; }

echo "== Installing workshop files"
mkdir -p "$W"
cp -r "$ASSETS/workshop/." "$W/"
install -m 0755 "$W"/bin/* /usr/local/bin/
echo 'cd /root/workshop' >> /root/.bashrc

echo "== Pulling images (in parallel)"
pids=()
for img in postgres:16-alpine pactfoundation/pact-broker:latest pactfoundation/pact-cli:latest; do
  docker pull -q "$img" & pids+=($!)
done
for p in "${pids[@]}"; do wait "$p"; done

echo "== Starting the Pact Broker"
docker compose -f "$W/docker-compose.yml" up -d

for i in $(seq 1 90); do
  curl -sf http://localhost:9292/diagnostic/status/heartbeat >/dev/null && break
  sleep 2
done
curl -sf http://localhost:9292/diagnostic/status/heartbeat >/dev/null

# Newer brokers ship with "production" already; ignore the error if it exists
pact-broker create-environment --name production --production || true

echo "== Setup complete"
touch /tmp/.setup-done