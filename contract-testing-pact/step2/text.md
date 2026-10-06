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

Open `order-service/tests/test_user_client_pact.py` in the editor. Each interaction is
described as a chain of calls:

```python
pact.upon_receiving("a request for an existing user")  # a name for the interaction
    .given("user 1 exists")           # provider state: what must be true on the provider (step 3)
    .with_request("GET", "/users/1")  # the request OrderService sends
    .will_respond_with(200)           # the status OrderService expects back...
    .with_body({...})                 # ...and the response body
```

Run the tests:

`run-tests order-service`{{exec}}

The "user does not exist" test passes: UserClient turns a 404 into `None`. The "existing
user" test fails, because the mock server returns an empty body and UserClient can't find
the fields it needs.

## Your task

You will **read** one file and **edit** another:

- `order-service/user_client.py` is the code being tested. Don't change it.
- `order-service/tests/test_user_client_pact.py` is the test you complete.

### 1. Find the fields OrderService uses

Open `order-service/user_client.py` and find where it reads UserService's response.
Which fields does it use? Those fields, and nothing else, belong in the contract.

<details>
<summary>Hint</summary>

Look at the last line of `get_user`:

```python
return User(id=data["id"], name=data["name"])
```

OrderService reads `id` and `name`. It never touches `email`.

</details>

### 2. Describe the response body

In `test_get_existing_user`, replace the `{}` in the `.with_body(...)` line with those
fields. Don't write fixed values; use **matchers**:

```python
match.int(1)                  # any integer; 1 is just an example
match.str("Alice Andersson")  # any string; "Alice Andersson" is just an example
```

### 3. Check the result

At the end of the function, after the `with` block, assert that `user.id` and
`user.name` have the example values.

Run the tests until both pass:

`run-tests order-service`{{exec}}

<details>
<summary>Solution</summary>

The complete `test_get_existing_user` function:

```python
def test_get_existing_user(pact):
    (
        pact.upon_receiving("a request for an existing user")
        .given("user 1 exists")
        .with_request("GET", "/users/1")
        .will_respond_with(200)
        .with_body(
            {"id": match.int(1), "name": match.str("Alice Andersson")},
            content_type="application/json",
        )
    )

    with pact.serve() as srv:
        user = UserClient(str(srv.url)).get_user(1)

    assert user.id == 1
    assert user.name == "Alice Andersson"
```

What each part does:

- **The body has only `id` and `name`** because those are the only fields `get_user`
  reads. The contract describes what OrderService needs, not everything UserService
  returns.
- **The matchers** make the contract say "an integer" and "a string" instead of exact
  values. During this test the mock server responds with the examples. When the real
  provider is checked against the contract (step 3), only the types must match.
- **`pact.serve()`** starts the mock server. The real `UserClient` sends a real HTTP
  request to it. If the request doesn't match what you described, for example a wrong
  path, the test fails.
- **The assertions** check that UserClient turns the response into the right `User`.
  The mock server returned the example values, so those are what you expect.
- **After the test**, the `pact` fixture writes the interaction to the pact file.

</details>

## Look at the contract

The tests wrote a pact file:

`python3 -m json.tool order-service/pacts/OrderService-UserService.json`{{exec}}

A few things to notice:

- **Only `id` and `name` are in it.** UserService also returns `email`, but OrderService
  doesn't use it, so the provider is free to change or remove it.
- **`matchingRules`** record that `id` must be an integer and `name` a string.
- **`providerStates`** name the preconditions, such as "user 1 exists". The provider must
  be able to set these up before checking each interaction.

Why matchers? With exact values, the contract would break whenever the provider's test
data changed, even though nothing about the API changed. A good contract pins down the
*shape* the consumer depends on, and nothing more.

Click **CHECK** when both tests pass.