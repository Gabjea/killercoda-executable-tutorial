#!/bin/bash
# Step 7: UserService 1.1.0 is deployed and recorded; OrderService is still 1.0.0.
set -e
cd /root/workshop
grep -q "^USER_SERVICE_VERSION=1.1.0$" .env
grep -q "^ORDER_SERVICE_VERSION=1.0.0$" .env
curl -sf localhost:8080/orders/1001 | grep -q '"customer"'
# With 1.1.0 recorded in production, OrderService 2.0.0 is now allowed
pact-broker can-i-deploy --pacticipant OrderService --version 2.0.0 --to-environment production >/dev/null 2>&1