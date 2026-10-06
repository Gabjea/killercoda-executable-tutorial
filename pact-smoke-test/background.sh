#!/bin/bash
docker network create pact
docker run -d --name pg --network pact -e POSTGRES_PASSWORD=pw postgres:16-alpine
sleep 10
docker run -d --name broker --network pact -p 9292:9292 \
  -e PACT_BROKER_DATABASE_URL=postgres://postgres:pw@pg/postgres \
  pactfoundation/pact-broker
touch /tmp/setup-done