#!/bin/bash
# Step 3: the "user 1 exists" state is defined, and UserService 1.0.0
# passes verification against the consumer's contract.
set -e
cd /root/workshop
python3 -c "
import json
states = json.load(open('provider-states/states.json'))
assert any(u['id'] == 1 for u in states['user 1 exists']['users'])
"
verify-provider 1.0.0 order-service/pacts/OrderService-UserService.json >/dev/null 2>&1