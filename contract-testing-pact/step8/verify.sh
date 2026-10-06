#!/bin/bash
# Step 8: OrderService 2.0.0 is deployed next to UserService 1.1.0.
set -e
cd /root/workshop
grep -q "^USER_SERVICE_VERSION=1.1.0$" .env
grep -q "^ORDER_SERVICE_VERSION=2.0.0$" .env
curl -sf localhost:8080/orders/1001 | grep -q '"customer"'
# With OrderService 2.0.0 recorded in production, UserService 2.0.0 is now allowed
pact-broker can-i-deploy --pacticipant UserService --version 2.0.0 --to-environment production >/dev/null 2>&1