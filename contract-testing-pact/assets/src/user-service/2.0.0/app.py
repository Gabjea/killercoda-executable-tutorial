import json
import os

from flask import Flask, jsonify, request

app = Flask(__name__)

USERS = {}

DEFAULT_USERS = [
    {"id": 1, "name": "Alice Andersson", "email": "alice@example.com"},
    {"id": 2, "name": "Bob Berg", "email": "bob@example.com"},
]


def user_to_json(user):
    return {
        "id": user["id"],
        "full_name": user["name"],
        "email": user["email"],
    }


def load_users(users):
    USERS.clear()
    USERS.update({u["id"]: u for u in users})


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/users/<int:user_id>")
def get_user(user_id):
    user = USERS.get(user_id)
    if user is None:
        return jsonify(error=f"user {user_id} not found"), 404
    return jsonify(user_to_json(user))


STATES_FILE = os.environ.get("PROVIDER_STATES_FILE")

if STATES_FILE:

    @app.post("/_pact/provider-states")
    def provider_state():
        body = request.get_json(force=True)
        if body.get("action", "setup") != "setup":
            return jsonify({})
        with open(STATES_FILE) as f:
            states = json.load(f)
        state = body.get("state")
        if state not in states:
            return jsonify(
                error=f"Unknown provider state '{state}'. Add it to provider-states/states.json"
            ), 400
        load_users(states[state].get("users", []))
        return jsonify({})

else:
    load_users(DEFAULT_USERS)