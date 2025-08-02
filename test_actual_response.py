#!/usr/bin/env python3
"""Test what the actual response format is from the user explore endpoint"""

import requests
import json

BASE_URL = "https://clear-meat-api-production.up.railway.app"
EMAIL = "ahhhlexli@gmail.com"
PASSWORD = "Stupidpassword!23"

def login():
    """Login and get access token"""
    response = requests.post(
        f"{BASE_URL}/api/v1/auth/login",
        data={"username": EMAIL, "password": PASSWORD},
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    
    if response.status_code == 200:
        data = response.json()
        return data.get("access_token")
    else:
        print(f"Login failed: {response.status_code} - {response.text}")
        return None

def test_explore_response():
    """Get actual response format from explore endpoint"""
    token = login()
    if not token:
        return
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(
        f"{BASE_URL}/api/v1/users/explore",
        headers=headers,
        params={"offset": 0, "limit": 5}
    )
    
    print(f"Status: {response.status_code}")
    print(f"Headers: {dict(response.headers)}")
    
    if response.status_code == 200:
        try:
            data = response.json()
            print(f"\nResponse type: {type(data)}")
            if isinstance(data, list):
                print(f"Array length: {len(data)}")
                if data:
                    print(f"First item keys: {list(data[0].keys()) if isinstance(data[0], dict) else 'Not a dict'}")
                    print(f"First item: {json.dumps(data[0], indent=2)}")
            elif isinstance(data, dict):
                print(f"Object keys: {list(data.keys())}")
                print(f"Full response: {json.dumps(data, indent=2)}")
            else:
                print(f"Unexpected type: {data}")
        except Exception as e:
            print(f"JSON decode error: {e}")
            print(f"Raw response: {response.text}")
    else:
        print(f"Error: {response.text}")

if __name__ == "__main__":
    test_explore_response()