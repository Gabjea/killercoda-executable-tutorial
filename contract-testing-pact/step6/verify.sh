#!/bin/bash
# Step 6: production is recorded in the broker, the gate is enabled in both
# repositories, and nothing unsafe was deployed.
set -e
cd /root/workshop

# The gate is enabled in both repositories
for repo in user-service order-service; do
  [ "$(git -C "$repo" config --get core.hooksPath)" = /root/workshop/hooks ]
done

# Production still runs 1.0.0 of both services
grep -q "^USER_SERVICE_VERSION=1.0.0$" .env
grep -q "^ORDER_SERVICE_VERSION=1.0.0$" .env

# The broker knows what's in production: both 2.0.0 versions are blocked,
# while UserService 1.1.0 is allowed (which also proves the broker is reachable)
pact-broker can-i-deploy --pacticipant UserService --version 1.1.0 --to-environment production >/dev/null 2>&1
for pacticipant in UserService OrderService; do
  if pact-broker can-i-deploy --pacticipant "$pacticipant" --version 2.0.0 --to-environment production >/dev/null 2>&1; then
    exit 1
  fi
done