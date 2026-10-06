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

Complete `test_get_existing_user`:

1. Replace the empty body with the fields UserClient reads. Check `order-service/user_client.py`
   to see which ones those are.
2. Use **matchers** for the values: `match.int(1)` means "any integer, for example 1",
   and `match.str("Alice Andersson")` means "any string, for example Alice Andersson".
3. Assert that the returned `user` has the expected `id` and `name`.

Run the tests again until both pass:

`run-tests order-service`{{exec}}

<details>
<summary>Show solution</summary>

```python
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

</details>

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