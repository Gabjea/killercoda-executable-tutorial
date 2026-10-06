#!/bin/bash
# Runs hidden while the learner reads the intro.
# Errors are visible in the Killercoda creator debug section and in /var/log/workshop-setup.log
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
chmod +x "$W"/hooks/* "$W"/server-hooks/*
echo 'cd /root/workshop' >> /root/.bashrc

git config --global user.name  "Workshop Learner"
git config --global user.email "learner@example.com"
git config --global init.defaultBranch main
git config --global advice.detachedHead false

echo "== Installing Docker Compose plugin (not preinstalled on this image)"
if ! docker compose version >/dev/null 2>&1; then
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -fsSL "https://github.com/docker/compose/releases/download/v5.6.0/docker-compose-linux-$(uname -m)" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi
docker compose version

echo "== Pulling images (in parallel)"
pids=()
for img in \
  postgres:16-alpine@sha256:721873c34ceb9f8d8fc265984940dc982404c105f19ad51be9fdc5970a6080ea \
  pactfoundation/pact-broker@sha256:420341d4fbfb00a621c313f47e530ad75703f969bbc7520d0d72bc71bb53cef9 \
  pactfoundation/pact-cli@sha256:72f1df83a7c42abd02e69a0fa21c3adc037d72c2852daa9f2910bb35617b207b \
  pactfoundation/pact-ref-verifier@sha256:514b680cd0ad2fa95c6df7a541e3b03c8dd1176de26e84e58a349de96e305bce \
  python:3.12-slim@sha256:05cda9777409a9c3ffddd94a4c476b79f0769a0b4857f0c7ed9226b6800b0d6f; do
  docker pull -q "$img" & pids+=($!)
done
for p in "${pids[@]}"; do wait "$p"; done

echo "== Building dev image (pytest + pact-python)"
docker build -q -t workshop-dev "$W/dev"

# make_repo <service> <pacticipant> <env var> <versions...>
# Builds a Git history with one commit + tag per version, builds an image per version,
# and creates a bare "production" remote whose main branch starts at the first version.
make_repo() {
  local svc=$1 pacticipant=$2 envvar=$3; shift 3
  local repo=$W/$svc bare=/srv/git/$svc.git first=$1
  git init -q "$repo"
  for v in "$@"; do
    cp -r "$ASSETS/src/$svc/$v/." "$repo/"
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "$(cat "$ASSETS/src/$svc/$v.msg")"
    git -C "$repo" tag "$v"
    git -C "$repo" archive "$v" | docker build -q -t "$svc:$v" -
  done
  git -C "$repo" config pact.pacticipant "$pacticipant"

  mkdir -p /srv/git
  git init -q --bare "$bare"
  git -C "$repo" remote add production "$bare"
  git -C "$repo" push -q production "$(git -C "$repo" rev-parse "$first"):refs/heads/main"
  git -C "$bare" config workshop.service "$svc"
  git -C "$bare" config workshop.envvar "$envvar"
  git -C "$bare" config pact.pacticipant "$pacticipant"
  # Installed after the initial push, so that push doesn't count as a deployment
  cp "$W/server-hooks/post-receive" "$bare/hooks/post-receive"
}

echo "== Creating repositories and building service images"
make_repo user-service  UserService  USER_SERVICE_VERSION  1.0.0 1.1.0 2.0.0
make_repo order-service OrderService ORDER_SERVICE_VERSION 1.0.0

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