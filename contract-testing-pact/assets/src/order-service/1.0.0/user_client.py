from dataclasses import dataclass

import requests


@dataclass
class User:
    id: int
    name: str


class UserClient:
    def __init__(self, base_url):
        self.base_url = base_url.rstrip("/")

    def get_user(self, user_id):
        response = requests.get(f"{self.base_url}/users/{user_id}", timeout=5)
        if response.status_code == 404:
            return None
        response.raise_for_status()
        data = response.json()
        return User(id=data["id"], name=data["name"])