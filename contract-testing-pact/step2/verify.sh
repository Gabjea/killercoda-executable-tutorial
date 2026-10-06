#!/bin/bash
# Step 2: both consumer tests pass, and the contract for "existing user"
# contains exactly id and name, both with matching rules.
set -e
cd /root/workshop
run-tests order-service >/dev/null

python3 - <<'EOF'
import json, sys

pact = json.load(open("order-service/pacts/OrderService-UserService.json"))
existing = [i for i in pact["interactions"] if i["response"]["status"] == 200]
if not existing:
    sys.exit("No interaction with a 200 response")

response = existing[0]["response"]
body = response.get("body", {}).get("content", {})
rules = response.get("matchingRules", {}).get("body", {})

if set(body) != {"id", "name"}:
    sys.exit(f"Body should contain exactly id and name, got {sorted(body)}")
for field in ("id", "name"):
    if f"$.{field}" not in rules:
        sys.exit(f"No matcher for {field}")
EOF