import app as order_app
from user_client import User


def test_order_includes_customer_name(monkeypatch):
    monkeypatch.setattr(order_app.users, "get_user", lambda uid: User(id=uid, name="Alice Andersson"))
    response = order_app.app.test_client().get("/orders/1001")
    assert response.status_code == 200
    assert response.get_json() == {
        "order_id": 1001,
        "item": "Mechanical keyboard",
        "customer": "Alice Andersson",
    }


def test_unknown_order_returns_404():
    assert order_app.app.test_client().get("/orders/9999").status_code == 404