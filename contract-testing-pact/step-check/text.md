# Infrastructure check

Temporary step for us authors.

**1. Broker and database are running**

`docker compose ps`{{exec}}

**2. Broker UI opens:** [open Pact Broker]({{TRAFFIC_HOST1_9292}})

**3. Broker CLI can reach the broker, and a "production" environment exists**

`pact-broker list-environments`{{exec}}