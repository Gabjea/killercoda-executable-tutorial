# Expand: add the new field

You ended step 6 stuck. UserService 2.0.0 can't be deployed while OrderService 1.0.0
is in production, and OrderService 2.0.0 can't be deployed while UserService 1.0.0 is.
Neither side of the rename can go first.

The way out is in the matrix:

`show-matrix`{{exec}}

**Your task:** find a UserService version that works with OrderService 1.0.0 (which is
in production now) *and* with OrderService 2.0.0 (the version that should come next).

<details>
<summary>Hint</summary>

Look at the column for each UserService version. Which column says `ok` in **both**
rows?

</details>

<details>
<summary>Solution</summary>

**UserService 1.1.0.** It sends both `name` and `full_name`, so it satisfies both
contracts. Deploying it doesn't break OrderService 1.0.0, and it makes room for
OrderService 2.0.0.

</details>

Ask the gate first:

`pact-broker can-i-deploy --pacticipant UserService --version 1.1.0 --to-environment production`{{exec}}

**Computer says yes.** Deploy it:

`deploy user-service 1.1.0`{{exec}}

Read the output from top to bottom. The pre-push hook asks `can-i-deploy`{{}} and gets a
yes, then the production remote's hook rolls out the new version and **records the
deployment** in the broker. The note from step 1 (*"the Pact Broker doesn't know this
version"*) is gone: the broker knows UserService 1.1.0 now.

Production still works:

`curl -s localhost:8080/orders/1001; echo`{{exec}}

`cat .env`{{exec}}

## What just happened

This first phase is called **expand**: the provider adds the new field *next to* the
old one. The change is purely additive, so every existing consumer keeps working, and
the provider can release it on its own schedule.

Click **CHECK** when UserService 1.1.0 is in production.