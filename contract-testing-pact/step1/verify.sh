#!/bin/bash
# Step 1: the learner deployed user-service 2.0.0, saw it break, and rolled back.
set -e
grep -q " user-service 2.0.0$" /var/log/workshop-deployments.log
grep -q "^USER_SERVICE_VERSION=1.0.0$" /root/workshop/.env
curl -sf localhost:8080/orders/1001 | grep -q '"customer"'