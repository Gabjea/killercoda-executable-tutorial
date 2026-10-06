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

git config --global user.name  "Workshop Learner"
git config --global user.email "learner@example.com"
git config --global init.defaultBranch main
git config --global advice.detachedHead false

echo "== Installing Docker Compose plugin (not preinstalled on this image)"
if ! docker compose version >/dev/null 2>&1; then
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi
docker compose version

echo "== Pulling images (in parallel)"
pids=()
for img in postgres:16-alpine pactfoundation/pact-broker:latest pactfoundation/pact-cli:latest \
           python:3.12-slim; do
  docker pull -q "$img" & pids+=($!)
done
for p in "${pids[@]}"; do wait "$p"; done

echo "== Building dev image (pytest + pact-python)"
docker build -q -t workshop-dev "$W/dev"

# make_repo <service> <pacticipant> <versions...>
# Builds a Git history with one commit + tag per version, and an image per version.
make_repo() {
  local svc=$1 pacticipant=$2; shift 2
  local repo=$W/$svc
  git init -q "$repo"
  for v in "$@"; do
    cp -r "$ASSETS/src/$svc/$v/." "$repo/"
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "$(cat "$ASSETS/src/$svc/$v.msg")"
    git -C "$repo" tag "$v"
    git -C "$repo" archive "$v" | docker build -q -t "$svc:$v" -
  done
  git -C "$repo" config pact.pacticipant "$pacticipant"
}

echo "== Creating repositories and building service images"
make_repo user-service  UserService  1.0.0
make_repo order-service OrderService 1.0.0

echo "== Starting production stack"
cat > "$W/.env" <<ENV
USER_SERVICE_VERSION=1.0.0
ORDER_SERVICE_VERSION=1.0.0
ENV
docker compose -f "$W/docker-compose.yml" up -d

echo "== Waiting for the Pact Broker"
for i in $(seq 1 90); do
  curl -sf http://localhost:9292/diagnostic/status/heartbeat >/dev/null && break
  sleep 2
done
curl -sf http://localhost:9292/diagnostic/status/heartbeat >/dev/null

# Newer brokers ship with "production" already; ignore the error if it exists
pact-broker create-environment --name production --production || true

echo "== Setup complete"
touch /tmp/.setup-done