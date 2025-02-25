import pytest
from conftest import BASE_URL, HEADERS

import json
import requests


@pytest.fixture
def register_b_c():
    username = 'b'
    email = 'b@b.b'
    pwd = 'b'
    data = {'username': username, 'email': email, 'pwd': pwd}
    params = {'latest': 5}
    response = requests.post(f'{BASE_URL}/register', data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok

    username = 'c'
    email = 'c@c.c'
    pwd = 'c'
    data = {'username': username, 'email': email, 'pwd': pwd}
    params = {'latest': 5}
    response = requests.post(f'{BASE_URL}/register', data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok


def test_follow_user(register_b_c):
    username = 'foo'
    url = f'{BASE_URL}/fllws/{username}'
    data = {'follow': 'b'}
    params = {'latest': 7}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok, f"Got {response.status_code} with {response.content}"

    data = {'follow': 'c'}
    params = {'latest': 8}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok

    query = {'no': 20, 'latest': 9}
    response = requests.get(url, headers=HEADERS, params=query)
    assert response.ok, f"Got {response.status_code} with {response.content}"

    json_data = response.json()
    assert "b" in json_data["follows"], f"b doesn't follow foo, {json_data}"
    assert "c" in json_data["follows"], f"c doesn't follow foo, {json_data}"

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 9, f"Expected 'latest == 9', got {response.content}"


def test_a_unfollows_b():
    username = 'a'
    url = f'{BASE_URL}/fllws/{username}'

    #  first send unfollow command
    data = {'unfollow': 'b'}
    params = {'latest': 10}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok, f"Got {response.status_code} with {response.content}"

    # then verify that b is no longer in follows list
    query = {'no': 20, 'latest': 11}
    response = requests.get(url, params=query, headers=HEADERS)
    assert response.ok, f"Got {response.status_code} with {response.content}"
    assert 'b' not in response.json()['follows'], \
        f"b still follows a, {response.json()}"

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 11, f"Expected 'latest == 11', got {response.content}"


