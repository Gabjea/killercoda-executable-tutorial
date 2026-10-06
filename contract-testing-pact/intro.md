# Contract Testing with Pact

Two teams own two microservices. **OrderService** shows orders, and calls
**UserService** to get the customer's name. Both teams have good test suites, and both
deploy on their own schedule.

In this tutorial, a harmless-looking field rename in UserService breaks production,
even though every test passes. You'll then use **contract testing** with **Pact** and
the **Pact Broker** to catch that kind of breakage in seconds, and to work out a safe
order for releasing the change.

## Intended learning outcomes

After this tutorial, you can:

1. **Explain** why separate test suites for each service miss breaking API changes
   between them.
2. **Write** a consumer contract with Pact, and **verify** a provider against it.
3. **Read** the Pact Broker's compatibility matrix to tell which versions of two
   services work together.
4. **Use** `can-i-deploy`{{}} to decide whether, and in which order, versions can be
   deployed safely.

## Why this matters for DevOps

A core goal of DevOps is that teams can deploy **independently and often**. With
microservices, that creates a risk: one team's change can break another team's service,
and nobody notices until production.

The classic safety net is a shared end-to-end test environment, where every service is
deployed together and tested as a whole. It's slow, it's fragile, and it ties all teams
to a common release schedule, which is exactly what independent deployment was supposed
to avoid.

Contract testing keeps the safety without the coupling. API compatibility is checked in
**seconds, in each team's own CI pipeline**, and `can-i-deploy`{{}} acts as an
**automated deployment gate**: a version only reaches production if it's known to work
with what's already there.

## The setup

![Architecture of the tutorial environment](./images/architecture.svg)

Everything runs in this browser environment, in Docker. Nothing to install, no accounts.

- **Development.** Each service has its own Git repository in `/root/workshop`{{}},
  like two separate teams would. OrderService is the **consumer** of the API,
  UserService the **provider**.
- **Production.** Docker Compose runs the currently deployed version of each service.
  OrderService is reachable on port 8080 and calls UserService internally.
- **Deployment.** There is no CI server. Instead, **deploying means pushing a commit to
  a Git remote called `production`{{}}**. Git hooks play the role of the pipeline: a
  *post-receive* hook rolls out the new version, and in step 6 you'll add a *pre-push*
  hook that blocks unsafe deployments.
- **Pact Broker.** A server, backed by PostgreSQL, that stores the contracts, the
  results of verifying them, and which version of each service is deployed where.
  You can open its web UI during the tutorial.

You'll use four helper commands. They wrap the real tools, so you don't have to type
long Docker commands:

    run-tests <service>        run a service's tests (including Pact contract tests)
    verify-provider <version>  check a UserService version against its contracts
    deploy <service> <version> deploy a version to production (a git push)
    pact-broker <command>      the official Pact Broker command-line tool

## Why these tools?

- **Pact** is the most widely used tool for *consumer-driven* contract testing. The
  contract is generated from the consumer's real client code, so it describes what the
  consumer actually uses. An API schema such as OpenAPI, by contrast, describes
  everything the provider offers, but not who depends on which part.
- **The Pact Broker** lets the two teams share contracts and results without sharing a
  repository, and remembers which versions are compatible. You'll see why that matters
  in step 4.
- **Git hooks instead of a CI service** keep the tutorial free of accounts. The commands
  they run are the same ones a real CI pipeline would run.

## Before you start

You should be comfortable reading basic Python and using a terminal. The tutorial takes
about X minutes.

The environment is being prepared while you read this: starting the Pact Broker and
building every version of both services. When the terminal says
**Environment ready**, click **START**.