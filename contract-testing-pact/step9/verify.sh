#!/bin/bash
# Step 9: both services run 2.0.0, production works, and rolling OrderService
# back to 1.0.0 is blocked by the broker.
set -e
cd /root/workshop
grep -q "^USER_SERVICE_VERSION=2.0.0$" .env
grep -q "^ORDER_SERVICE_VERSION=2.0.0$" .env
curl -sf localhost:8080/orders/1001 | grep -q '"customer"'
# With UserService 2.0.0 recorded in production, a rollback of OrderService is unsafe
if pact-broker can-i-deploy --pacticipant OrderService --version 1.0.0 --to-environment production >/dev/null 2>&1; then
  exit 1
fi