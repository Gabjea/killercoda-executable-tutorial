#!/bin/bash
# Step 5: all six OrderService x UserService combinations have been verified,
# with the expected results.
curl -sfg -H "Accept: application/hal+json" \
  "http://localhost:9292/matrix?q[][pacticipant]=OrderService&q[][pacticipant]=UserService" |
python3 -c '
import json, sys
expected = {
    ("1.0.0", "1.0.0"): True,  ("1.0.0", "1.1.0"): True, ("1.0.0", "2.0.0"): False,
    ("2.0.0", "1.0.0"): False, ("2.0.0", "1.1.0"): True, ("2.0.0", "2.0.0"): True,
}
seen = {}
for row in json.load(sys.stdin)["matrix"]:
    provider = (row.get("provider") or {}).get("version")
    verification = row.get("verificationResult")
    if provider and verification:
        seen[(row["consumer"]["version"]["number"], provider["number"])] = verification["success"]
sys.exit(0 if all(seen.get(k) == v for k, v in expected.items()) else 1)
'