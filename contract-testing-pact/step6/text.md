# Environments and can-i-deploy

The broker now knows which versions work together. To decide whether a version can be
**deployed**, it also needs to know what's **already running** in production. That's
what environments are for.

## Tell the broker what's in production

Production currently runs version 1.0.0 of both services:

`cat .env`{{exec}}

The broker doesn't know that yet: so far, no deployment was ever recorded. Record both:

`pact-broker record-deployment --pacticipant OrderService --version 1.0.0 --environment production`{{exec}}

`pact-broker record-deployment --pacticipant UserService --version 1.0.0 --environment production`{{exec}}

In a real pipeline, this command runs automatically **after every successful
deployment**. Our *post-receive* hook does exactly that from now on. In step 1 it
printed *"the Pact Broker doesn't know this version"*, because no contracts had been
published yet.

You can see the result in the [Pact Broker]({{TRAFFIC_HOST1_9292}}): both versions are
now marked as deployed to production.

## Ask before deploying

`can-i-deploy`{{}} combines the two kinds of information the broker has: *which
versions are compatible* (the matrix) and *what's deployed where* (environments).

Can the UserService team deploy their rename?

`pact-broker can-i-deploy --pacticipant UserService --version 2.0.0 --to-environment production`{{exec}}

**Computer says no.** The table shows why: OrderService 1.0.0 is in production, and its
contract fails against UserService 2.0.0.

So maybe the OrderService team should go first?

`pact-broker can-i-deploy --pacticipant OrderService --version 2.0.0 --to-environment production`{{exec}}

**No again.** OrderService 2.0.0 needs `full_name`{{}}, and UserService 1.0.0 in
production doesn't send it.

Notice that `can-i-deploy`{{}} checks **both directions**. For a provider, it checks the
consumers in production. For a consumer, it checks the providers in production. And it
doesn't run any tests: it looks up results that were recorded earlier, so it answers
in about a second.

Neither side of the rename can be deployed first. You'll find the way out in the next
step. First, let's make sure nobody can repeat step 1's mistake.

## Add the deployment gate

In a real CI/CD pipeline, `can-i-deploy`{{}} runs as a step right before the deploy
job, and a "no" stops the pipeline. Here, a Git **pre-push hook** plays that role:

`cat hooks/pre-push`{{exec}}

Before every push to `production`{{}}, the hook reads the version being pushed and asks
`can-i-deploy`{{}}. If the answer is no, the push is cancelled. Enable it in both
repositories:

`git -C user-service config core.hooksPath /root/workshop/hooks`{{exec}}

`git -C order-service config core.hooksPath /root/workshop/hooks`{{exec}}

Now try step 1's deployment again:

`deploy user-service 2.0.0`{{exec}}

**Blocked.** The push never reached production, which still works:

`curl -s localhost:8080/orders/1001; echo`{{exec}}

## Why a gate, and why here?

- **Safety without coordination.** No team has to know which versions the other team
  has deployed, or ask before releasing. The broker knows, and the gate asks it.
- **Fast feedback at the right moment.** The check takes a second and runs exactly when
  a decision is made, instead of in a slow end-to-end environment hours earlier.
- **The loop is closed.** Contracts and verifications are published in CI,
  deployments are recorded after each release, and the gate reads both. Each piece
  depends on the others being automated.

One honest caveat: a Git hook runs on the developer's machine and can be skipped with
`git push --no-verify`{{}}. In a real setup the gate lives in the CI/CD pipeline, where
nobody can skip it. Here, the hook stands in for that pipeline step.

Click **CHECK** when production is recorded and the gate is enabled in both
repositories.