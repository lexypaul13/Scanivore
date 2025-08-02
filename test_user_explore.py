#!/usr/bin/env python3
"""Test the user explore endpoint to debug 500 error"""

import requests
import json
from datetime import datetime

# API configuration
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
        print(f"Login failed: {response.status_code}")
        print(response.text)
        return None

def test_user_explore(token):
    """Test the user explore endpoint"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Test the user explore endpoint
    print("\n1. Testing /api/v1/users/explore endpoint:")
    print("-" * 50)
    
    response = requests.get(
        f"{BASE_URL}/api/v1/users/explore",
        headers=headers,
        params={"offset": 0, "limit": 10}
    )
    
    print(f"Status code: {response.status_code}")
    print(f"Response headers: {dict(response.headers)}")
    
    if response.status_code == 500:
        print("\nERROR: Server returned 500")
        print(f"Response text: {response.text}")
    elif response.status_code == 200:
        data = response.json()
        print(f"\nSuccess! Got {len(data.get('recommendations', []))} recommendations")
        print(f"Total matches: {data.get('totalMatches', 0)}")
        
        # Show first few recommendations
        for i, rec in enumerate(data.get('recommendations', [])[:3]):
            product = rec.get('product', {})
            print(f"\n{i+1}. {product.get('name')} - {product.get('brand')}")
            print(f"   Meat type: {product.get('meat_type')}")
            print(f"   Match score: {rec.get('matchScore')}")
    else:
        print(f"\nUnexpected status code: {response.status_code}")
        print(f"Response: {response.text}")

def test_recommendations_endpoint(token):
    """Test the generic recommendations endpoint for comparison"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    print("\n\n2. Testing /api/v1/products/recommendations endpoint (for comparison):")
    print("-" * 50)
    
    response = requests.get(
        f"{BASE_URL}/api/v1/products/recommendations",
        headers=headers,
        params={"offset": 0, "page_size": 10}
    )
    
    print(f"Status code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\nSuccess! Got {len(data.get('recommendations', []))} recommendations")
        print(f"Total matches: {data.get('totalMatches', 0)}")
        
        # Show first few recommendations
        for i, rec in enumerate(data.get('recommendations', [])[:3]):
            product = rec.get('product', {})
            print(f"\n{i+1}. {product.get('name')} - {product.get('brand')}")
            print(f"   Meat type: {product.get('meat_type')}")
            print(f"   Match score: {rec.get('matchScore')}")
    else:
        print(f"\nError: {response.status_code}")
        print(f"Response: {response.text}")

def check_user_preferences(token):
    """Check current user preferences"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    print("\n\n3. Checking current user preferences:")
    print("-" * 50)
    
    response = requests.get(
        f"{BASE_URL}/api/v1/users/preferences",
        headers=headers
    )
    
    if response.status_code == 200:
        prefs = response.json()
        print(f"Preferred meat types: {prefs.get('preferred_meat_types', [])}")
        print(f"Meat preferences: {prefs.get('meatPreferences', [])}")
        print(f"\nFull preferences:")
        print(json.dumps(prefs, indent=2))
    else:
        print(f"Error getting preferences: {response.status_code}")
        print(response.text)

def main():
    print(f"Testing user explore endpoint at {datetime.now()}")
    print("=" * 70)
    
    # Login
    token = login()
    if not token:
        print("Failed to login, exiting")
        return
    
    print(f"\nLogged in successfully, token: {token[:20]}...")
    
    # Test endpoints
    test_user_explore(token)
    test_recommendations_endpoint(token)
    check_user_preferences(token)

if __name__ == "__main__":
    main()