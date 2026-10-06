# Write a consumer contract

In contract testing, the **consumer** (OrderService) writes down what it needs from the
**provider** (UserService). This is called *consumer-driven* contract testing: the
contract contains only what the consumer actually uses.

With Pact, you write the contract as an ordinary unit test. Instead of a hand-written
stub, the test runs your real client code against a **Pact mock server**. You tell the
mock server which request to expect and how to respond. Pact checks that your client
really sends that request, and records the interaction into a **pact file**: the contract.

## The test skeleton

Copy the skeleton into the order service's tests:

`cp skeletons/test_user_client_pact.py order-service/tests/`{{exec}}

Open `order-service/tests/test_user_client_pact.py` in the editor (or `cat` it). Each
interaction is described with a few calls:

| Call | Meaning |
|---|---|
| `upon_receiving(...)` | A name for the interaction |
| `given(...)` | A **provider state**: what must be true on the provider's side. You'll use these in step 3 |
| `with_request(...)` | The request the consumer sends |
| `will_respond_with(...)`, `with_body(...)` | The response the consumer expects |

Run the tests:

`run-tests order-service`{{exec}}

The "user does not exist" test passes: UserClient turns a 404 into `None`. The "existing
user" test fails, because the mock server returns an empty body and UserClient can't find
the fields it needs.

## Your task

You'll **read** one file and **edit** another:

- `order-service/user_client.py` is the code being tested. Don't change it.
- `order-service/tests/test_user_client_pact.py` is the test you complete.

**1. Find out what OrderService needs.** Open `order-service/user_client.py` and find
where it reads UserService's response. Which fields does it use? Those fields, and
nothing else, belong in the contract.

<details>
<summary>Hint</summary>

Look at the last line of `get_user`:

```python
return User(id=data["id"], name=data["name"])
```

OrderService reads `id` and `name`. It never touches `email`.

</details>

**2. Describe the response body.** In `test_get_existing_user`, replace `{}` in the
`.with_body(...)` line with those fields. For the values, use **matchers**:
`match.int(1)` means "any integer, for example 1", and `match.str("Alice Andersson")`
means "any string, for example Alice Andersson".

**3. Check the result.** At the end of the function, after the `with` block, assert that
`user.id` and `user.name` have the example values. The mock server responds with those
values, so the client should return them.

Run the tests until both pass:

`run-tests order-service`{{exec}}

## Look at the contract

The tests wrote a pact file:

`python3 -m json.tool order-service/pacts/OrderService-UserService.json`{{exec}}

A few things to notice:

- **Only `id` and `name` are in it.** UserService also returns `email`, but OrderService
  doesn't use it, so the provider is free to change or remove it.
- **`matchingRules`** record that `id` must be an integer and `name` a string. The example
  values are just what the mock server returned during the test. The provider only has
  to return values of the right *type*, not exactly `"Alice Andersson"`.
- **`providerStates`** name the preconditions ("user 1 exists"). The provider must be able
  to set these up before checking each interaction.

Why matchers? With exact values, the contract would break whenever the provider's test
data changed, even though nothing about the API changed. A good contract pins down the
*shape* the consumer depends on, and nothing more.

Click **CHECK** when both tests pass.