import os

from flask import Flask, jsonify

from user_client import UserClient

app = Flask(__name__)

ORDERS = {
    1001: {"user_id": 1, "item": "Mechanical keyboard"},
    1002: {"user_id": 2, "item": "USB-C cable"},
}

users = UserClient(os.environ.get("USER_SERVICE_URL", "http://localhost:5001"))


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/orders/<int:order_id>")
def get_order(order_id):
    order = ORDERS.get(order_id)
    if order is None:
        return jsonify(error=f"order {order_id} not found"), 404
    customer = users.get_user(order["user_id"])
    if customer is None:
        return jsonify(error="customer not found"), 502
    return jsonify(order_id=order_id, item=order["item"], customer=customer.name)