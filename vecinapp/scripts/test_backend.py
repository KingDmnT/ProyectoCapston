import requests
import json

# Test endpoint del backend
user_id = "eDluXRJ69jS37ChIm8YHazNGt6U2"  # Ana Torres

print("=" * 80)
print(f"🔍 Testing backend endpoint: /users/{user_id}")
print("=" * 80)

try:
    response = requests.get(f"http://localhost:8000/users/{user_id}")
    
    print(f"\nStatus Code: {response.status_code}")
    
    if response.status_code == 200:
        user_data = response.json()
        print(f"\n✅ Response received")
        print(f"\nUser: {user_data.get('name')}")
        print(f"Email: {user_data.get('email')}")
        
        memberships = user_data.get('memberships', [])
        print(f"\n📋 MEMBERSHIPS ({len(memberships)}):")
        
        for i, m in enumerate(memberships):
            print(f"\n   Membership {i}:")
            print(f"      community_id: {m.get('community_id')}")
            print(f"      unit_id: {m.get('unit_id')}")  # ← VERIFICAR
            print(f"      unit_number: {m.get('unit_number')}")  # ← VERIFICAR
            print(f"      roles: {m.get('roles')}")
    else:
        print(f"\n❌ Error: {response.status_code}")
        print(response.text)
        
except Exception as e:
    print(f"\n❌ Error: {e}")

print("\n" + "=" * 80)
