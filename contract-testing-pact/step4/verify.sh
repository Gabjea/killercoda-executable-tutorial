#!/bin/bash
# Step 4: OrderService 1.0.0's contract is in the broker, and UserService 1.0.0
# has published a successful verification of it.
pact-broker can-i-deploy \
  --pacticipant OrderService --version 1.0.0 \
  --pacticipant UserService --version 1.0.0 >/dev/null 2>&1