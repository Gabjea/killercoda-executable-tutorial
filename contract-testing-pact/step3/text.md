# Verify the provider

The pact file is the consumer's half of the contract. Now the **provider** team checks
their real service against it. The **Pact verifier** reads the contract and, for each
interaction:

```
Pact verifier                                     UserService (real code)
  1. "Set up provider state: user 1 exists"  ───▶  prepares test data
  2. GET /users/1                            ───▶
                                             ◀───  200 {"id": 1, "name": "...", ...}
  3. Compare the response with the contract:
     is "id" an integer? Is "name" a string?
```

No OrderService is involved. The provider is checked on its own, against the
consumer's written-down expectations.

## Provider states

The contract says *given "user 1 exists"*. The verifier can't make that true on its own;
only UserService knows how its data works. So UserService has a small endpoint that is
only enabled during verification:

`sed -n '/Provider states/,$p' user-service/app.py`{{exec}}

The verifier calls this endpoint with the state's name before each interaction. The
endpoint looks the state up in a file of test data:

`cat provider-states/states.json`{{exec}}

## Run the verification

`verify-provider 1.0.0 order-service/pacts/OrderService-UserService.json`{{exec}}

This starts UserService 1.0.0 in a container with provider states enabled, and runs the
Pact verifier against it.

The "user that does not exist" interaction passes. The "existing user" interaction
fails before the request is even sent:

    Provider setup state change for 'user 1 exists' has failed - ... Invalid status code: 400

Before checking the interaction, the verifier asked UserService to set up the state
*user 1 exists*. UserService looked for it in `states.json`{{}}, didn't find it, and
answered with **400 Bad Request**. The verifier can't check an interaction whose
precondition couldn't be set up, so it fails it.

## Your task: add the missing state

Edit `provider-states/states.json`{{}} and add a state called `user 1 exists`{{}},
with one user whose `id`{{}} is `1`{{}}.

Users in this file use UserService's **internal** format: `id`{{}}, `name`{{}} and
`email`{{}} (the same as `DEFAULT_USERS`{{}} in `user-service/app.py`{{}}).

The name can be anything. Try something different from the contract's example, like
`Ada Lovelace`{{}}: the contract uses a type matcher, so any string is fine.

<details>
<summary>Solution</summary>

`provider-states/states.json` should look like this:

```json
{
  "no users exist": {
    "users": []
  },
  "user 1 exists": {
    "users": [
      {"id": 1, "name": "Ada Lovelace", "email": "ada@example.com"}
    ]
  }
}
```

What this does:

- **Each key is a state name** exactly as written in the contract's `given(...)`{{}}.
  Spelling matters: `"user 1 exists"`{{}} must match character for character.
- **`users` is the test data** that UserService loads when the verifier asks for that
  state. `"no users exist"`{{}} loads an empty list, so `GET /users/99`{{}} returns 404.
- **The name differs from the contract's example**, and the verification still passes.
  That's the type matcher at work: the contract only requires *a string*.
- **Watch the comma** between the two states. JSON doesn't allow a missing or trailing
  comma.

</details>

Run the verification again:

`verify-provider 1.0.0 order-service/pacts/OrderService-UserService.json`{{exec}}

Both interactions pass: UserService 1.0.0 fulfils OrderService's contract.

## Catch the breaking change

Now verify version **2.0.0**, the one that broke production in step 1, against the same
contract:

`verify-provider 2.0.0 order-service/pacts/OrderService-UserService.json`{{exec}}

It fails. Look for this line in the output:

    $ -> Actual map is missing the following keys: name

The `$`{{}} means "the top level of the response body". UserService 2.0.0 returns
`full_name`{{}}, but the contract requires `name`{{}}.

That's step 1's bug, caught in seconds, without deploying anything and without running
OrderService at all. The UserService team could run this in their CI on every commit.

There's one catch. To run the verification, the provider needed the pact file from the
*consumer's* repository. Copying files between teams doesn't scale, and it doesn't tell
you which version of the consumer the contract belongs to. That's the job of the
**Pact Broker**, in the next step.

Click **CHECK** when UserService 1.0.0 passes the verification.