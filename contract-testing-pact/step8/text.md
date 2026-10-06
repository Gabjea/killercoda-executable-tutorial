# Migrate: move the consumer

In step 6, the OrderService team asked whether they could deploy version 2.0.0, and the
answer was no. Ask the same question again:

`pact-broker can-i-deploy --pacticipant OrderService --version 2.0.0 --to-environment production`{{exec}}

**This time, yes.** The question is the same, but the answer depends on what's in
production, and production has changed: UserService 1.1.0 now sends `full_name`{{}}.

Deploy OrderService 2.0.0. It lives on the `use-full-name`{{}} branch you created in
step 5:

`deploy order-service use-full-name`{{exec}}

(In a real project, you would merge the branch into `main`{{}} first and deploy from
there. We deploy the branch directly to keep the tutorial short.)

Check production:

`curl -s localhost:8080/orders/1001; echo`{{exec}}

`cat .env`{{exec}}

The order still shows the customer's name, but OrderService now reads it from
`full_name`{{}}.

## What just happened

This phase is called **migrate**: consumers move to the new field, one at a time, each
on its own schedule. Here there was only one consumer. With ten consumers, this phase
lasts until the slowest one has migrated.

That raises a question the provider team can't answer on its own: *has every consumer
in production stopped using `name`{{}}?* With contract testing, it's a lookup:

`pact-broker can-i-deploy --pacticipant UserService --version 2.0.0 --to-environment production`{{exec}}

Yes: no consumer in production still needs `name`{{}}.

Click **CHECK** when OrderService 2.0.0 is in production.