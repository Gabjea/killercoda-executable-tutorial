# Contract Testing with Pact

Two teams own two microservices:

- **UserService** returns users: `GET /users/{id}`
- **OrderService** shows orders, and calls UserService to get the customer's name

Both teams have good test suites, and both deploy independently. In this tutorial you'll
see how that setup lets a harmless-looking field rename break production, and how
**contract testing** with Pact and the **Pact Broker** catches it in seconds.

While you read this, the environment is being prepared in the background. The terminal
will say **Environment ready** when it's done (about 1–2 minutes).