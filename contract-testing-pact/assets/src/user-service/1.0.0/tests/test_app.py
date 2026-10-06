import app as user_app


def client():
    user_app.load_users(user_app.DEFAULT_USERS)
    return user_app.app.test_client()


def test_get_user():
    response = client().get("/users/1")
    assert response.status_code == 200
    assert response.get_json() == {
        "id": 1,
        "name": "Alice Andersson",
        "email": "alice@example.com",
    }


def test_unknown_user_returns_404():
    assert client().get("/users/99").status_code == 404