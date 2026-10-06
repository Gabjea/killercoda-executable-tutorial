# Share contracts through the Pact Broker

At the end of step 3, the provider needed a file from the consumer's repository. The
**Pact Broker** removes that dependency: it's a server that both teams talk to, instead
of talking to each other.

![The contract-testing workflow through the Pact Broker](./contract-workflow.svg)

1. The consumer team **publishes** its contract to the broker.
2. The provider team **fetches** the contracts it must fulfil.
3. The provider team **publishes the verification results** back.

The broker then knows which consumer versions and which provider versions work
together. In step 6, a deployment gate will ask it exactly that.

## 1. Publish the contract

A contract is always published together with the **version of the consumer** that
produced it. OrderService's version is in its `VERSION`{{}} file:

`cat order-service/VERSION`{{exec}}

Publish the pact file from step 2:

`pact-broker publish order-service/pacts --consumer-app-version 1.0.0 --branch main`{{exec}}

    --consumer-app-version 1.0.0   which OrderService version this contract belongs to
    --branch main                  which Git branch that version was built from

In a real project, OrderService's CI pipeline runs this after every successful build,
usually with the Git commit SHA as the version. Here, you've added contract tests to
version 1.0.0, which is already in production, so you publish the contract as 1.0.0.

Now open the broker: [Open the Pact Broker]({{TRAFFIC_HOST1_9292}})

You'll see a row for the pact between **OrderService** and **UserService**. The
*Last verified* column is empty: nobody has checked this contract against the provider
yet. Click the pact to see the contract rendered as readable documentation.

## 2 & 3. Verify against the broker

Run the provider verification again, but this time **without a pact file**:

`verify-provider 1.0.0`{{exec}}

The script now asks the broker for OrderService's contracts, verifies UserService 1.0.0
against them, and publishes the result to the broker as *UserService version 1.0.0*.

Refresh the broker page. The pact now has a *Last verified* time, marked as successful.
The broker has recorded a fact: **OrderService 1.0.0 and UserService 1.0.0 are
compatible.**

## Why a broker?

- **Teams stay decoupled.** No shared repository and no copying files. Each team's
  pipeline only talks to the broker.
- **Contracts are versioned.** The broker knows which consumer version produced which
  contract. The provider can verify the versions that matter, like the one in
  production, instead of whichever file someone last copied.
- **Results are remembered.** Verification results are stored per provider version.
  Later, the question "do these two versions work together?" can be answered without
  running any tests again. That's what makes the deployment gate in step 6 possible.

Pact files could also be shared through a common repository or an artifact store. That
works for small setups, but you lose the versioning and the stored results. There's
also a hosted, commercial broker (PactFlow) with extra features; this tutorial uses the
open-source broker, which you can host yourself without an account.

Click **CHECK** when UserService 1.0.0's verification is published.