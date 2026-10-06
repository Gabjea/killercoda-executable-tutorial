"""Consumer contract tests: what OrderService needs from UserService.

These tests run UserClient against a Pact mock server instead of the real
UserService. Every interaction is recorded into a contract (pact file).
"""
import shutil
from pathlib import Path

import pytest
from pact import Pact, match

from user_client import UserClient

PACT_DIR = Path(__file__).parent.parent / "pacts"
shutil.rmtree(PACT_DIR, ignore_errors=True)  # start from a clean contract on every run


@pytest.fixture
def pact():
    pact = Pact("OrderService", "UserService").with_specification("V4")
    yield pact
    pact.write_file(str(PACT_DIR))


def test_get_user_that_does_not_exist(pact):
    (
        pact.upon_receiving("a request for a user that does not exist")
        .given("no users exist")
        .with_request("GET", "/users/99")
        .will_respond_with(404)
    )

    with pact.serve() as srv:
        user = UserClient(str(srv.url)).get_user(99)

    assert user is None


def test_get_existing_user(pact):
    (
        pact.upon_receiving("a request for an existing user")
        .given("user 1 exists")
        .with_request("GET", "/users/1")
        .will_respond_with(200)
        # TODO 1: replace {} with the fields UserClient reads, using match.int / match.str
        .with_body({}, content_type="application/json")
    )

    with pact.serve() as srv:
        user = UserClient(str(srv.url)).get_user(1)

    # TODO 2: assert that user.id and user.name have the example values