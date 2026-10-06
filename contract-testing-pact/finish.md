# Done: a breaking change, released safely

You started with a field rename that broke production even though every test passed.
You ended by releasing the same rename in three steps, with a deployment gate checking
each one, and production never broke.

## What you did

- **Step 1.** Saw two green test suites miss a breaking change, because each one only
  checked its own side of the API.
- **Steps 2–3.** Wrote OrderService's expectations down as a Pact contract, and verified
  the real UserService against it using provider states. The verification caught the
  bug from step 1 in seconds, without deploying anything.
- **Steps 4–5.** Shared contracts and results through the Pact Broker, and built a
  compatibility matrix of two consumer versions against three provider versions.
- **Step 6.** Recorded what's in production, and let `can-i-deploy`{{}} guard every
  deployment through a Git hook.
- **Steps 7–9.** Released the rename as expand, migrate, contract, with the gate
  confirming each step, and blocking an unsafe rollback.

## Looking back at the learning outcomes

1. **Why separate test suites miss breaking changes:** each suite tests one service
   against its own *assumptions* about the other. Nothing checks those assumptions
   against the real thing (step 1).
2. **Writing and verifying a contract:** the consumer test generates the contract from
   real client code, with type matchers; the provider verifies it with provider states
   (steps 2–3).
3. **Reading the matrix:** compatibility is a property of a *pair of versions*, and the
   broker stores every verified pair (step 5).
4. **Deciding a safe deployment order:** `can-i-deploy`{{}} combines the matrix with
   what's in production, and turned "is this safe?" into a one-second lookup (steps 6–9).

## When is contract testing worth it?

**It pays off when:**

- **Several teams own services that call each other**, and each team wants to deploy on
  its own schedule. That's the situation contract testing was built for.
- **End-to-end test environments are slow or flaky.** Contract tests run in seconds,
  in each team's own pipeline, with no shared environment.
- **APIs change often.** Every change gets checked against the consumers that actually
  exist, instead of all possible ones.

**It's probably not worth it when:**

- **One team deploys a few services together**, or the system is a monolith. Ordinary
  integration tests are simpler and cover more.
- **The API is public, with unknown consumers.** Consumer-driven contracts need
  consumers who write tests and publish them. For a public API, schema-based checks
  (such as OpenAPI) and explicit versioning fit better.
- **The teams won't maintain it.** Contract tests, provider states and the broker all
  need care. Half-maintained contracts give a false sense of safety.

**For whom:** backend and platform teams in organisations with many internal services,
where the consumer teams can be asked to write and publish contracts.

## Limits to keep in mind

- **It only covers what the consumer tested.** An interaction nobody wrote a contract
  for is not checked at all.
- **It checks the shape of messages, not their meaning.** If UserService returned the
  *wrong* person's name, it would still be a string, and the contract would pass.
  Business logic, performance, and security need other tests.
- **Provider states are test data**, and can drift away from what real data looks like.
- **The broker becomes critical infrastructure.** If it's down, the deployment gate
  can't answer, and someone has to decide whether to wait or deploy without it.
- **It doesn't replace end-to-end tests entirely.** A few smoke tests after deployment
  still catch what contracts can't: configuration, networking, authentication.

This tutorial also simplified a few things. Versions were numbers like 1.0.0 instead of
Git commit SHAs, there was a single consumer, OrderService 2.0.0 was deployed straight
from its branch, and the deployment gate was a Git hook that can be skipped. In a real
setup, the same commands run as steps in a CI/CD pipeline, where nobody can skip them.

## Design decisions in this tutorial

- **Pact and consumer-driven contracts:** the contract is generated from real client
  code, so it describes what consumers actually use, not everything the provider offers.
- **Type matchers:** contracts pin down the *shape* consumers depend on, so they don't
  break when test data changes.
- **The Pact Broker:** shares contracts without shared repositories, and stores results
  per version, which is what makes the matrix and `can-i-deploy`{{}} possible.
- **Git hooks instead of a CI service:** no accounts needed, and the commands are the
  same ones a pipeline would run.
- **Docker for everything:** every tool runs from official images, so the environment
  is reproducible and nothing has to be installed.

## Further reading

- [Pact documentation](https://docs.pact.io): guides for other languages, message-based
  contracts, and running `can-i-deploy`{{}} in CI.
- [Consumer-Driven Contracts](https://martinfowler.com/articles/consumerDrivenContracts.html),
  Ian Robinson: the article that introduced the idea.
- [Parallel Change](https://martinfowler.com/bliki/ParallelChange.html), Danilo Sato:
  the expand-and-contract pattern you used in steps 7–9.