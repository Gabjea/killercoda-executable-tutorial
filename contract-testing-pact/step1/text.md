# The breaking change

The UserService team has decided that `name` is too vague: they want the field to be
called `full_name`. They made the change in version **2.0.0**:

`git -C user-service diff 1.0.0 2.0.0 -- app.py`{{exec}}

(There's also a version 1.1.0 in their history that was never deployed. Keep it in mind.)

## Both test suites pass

The user service's working copy is at 2.0.0. Run its tests:

`run-tests user-service`{{exec}}

Green. The order service's tests pass too:

`run-tests order-service`{{exec}}

Look at how the order service tests its endpoint:

`cat order-service/tests/test_app.py`{{exec}}

The real UserService is replaced by a **stub** that returns a `User` directly. That's
good practice for unit tests: they're fast and don't depend on another team's service.
But it means the tests only check the order service against *its own assumption* of what
UserService returns.

## Deploy to production

Right now production runs version 1.0.0 of both services:

`cat .env`{{exec}}

`curl -s localhost:8080/orders/1001; echo`{{exec}}

In this environment, **deploying means pushing a commit to a Git remote called
`production`**. A hook on that remote builds the pushed version and replaces the running
container. The `deploy` command does the push for you. Deploy the new user service:

`deploy user-service 2.0.0`{{exec}}

(Ignore the note about the Pact Broker for now; we'll get to it.)

Now try the order service again:

`curl -s localhost:8080/orders/1001; echo`{{exec}}

A `500 Internal Server Error`. The logs show why:

`docker compose logs order-service | tail -5`{{exec}}

The order service still reads `data["name"]`, and that field no longer exists.

## Roll back

Deploy the previous version to restore production:

`deploy user-service 1.0.0 && curl -s localhost:8080/orders/1001; echo`{{exec}}

## Why didn't the tests catch this?

Each test suite checked one side of the conversation:

- The **user service** tests check that it returns `full_name`. They have no idea anyone
  depends on `name`.
- The **order service** tests use a stub that returns whatever the order team *believes*
  UserService returns. Nothing checks that belief against the real service.

The bug lives in the gap between them. End-to-end tests that run both services together
would catch it, but they need a shared environment with every service deployed, they're
slow, and they tie the teams' release schedules together.

**Contract testing** closes the gap differently: the consumer writes down its
assumptions as a **contract**, and the provider checks that contract against its real
code. Each side still tests in isolation. In the next step you'll write that contract.

Click **CHECK** when you've deployed 2.0.0, seen the failure, and rolled back.