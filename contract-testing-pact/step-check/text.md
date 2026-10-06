# Infrastructure check

Temporary step for us authors.

**1. Stack is up**

`docker compose ps`{{exec}}

**2. Broker UI opens:** [open Pact Broker]({{TRAFFIC_HOST1_9292}})

**3. Broker CLI works**

`pact-broker list-environments`{{exec}}

**4. Order service works end to end** (expect `"customer": "Alice Andersson"`)

`curl -s localhost:8080/orders/1001; echo`{{exec}}

**5. Unit tests pass**

`run-tests user-service`{{exec}}

`run-tests order-service`{{exec}}

**6. Git repos**

`git -C user-service log --oneline --decorate`{{exec}}

**7. pact-python is installed**

`docker run --rm workshop-dev pip show pact-python`{{exec}}

**8. User-service history: three tagged versions, production at 1.0.0**

`git -C user-service log --oneline --decorate`{{exec}}

**9. Deploying 2.0.0 breaks the order service** (expect a 500)

`deploy user-service 2.0.0`{{exec}}

`curl -s localhost:8080/orders/1001; echo`{{exec}}

`docker compose logs order-service | tail -5`{{exec}}

**10. Rolling back fixes it**

`deploy user-service 1.0.0 && curl -s localhost:8080/orders/1001; echo`{{exec}}

`cat .env`{{exec}}