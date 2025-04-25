import requests
import json
import time
import os
import argparse

# API configuration
BASE_URL = "http://localhost:8080"
REGISTER_ENDPOINT = f"{BASE_URL}/api/auth/register"
LOGIN_ENDPOINT = f"{BASE_URL}/api/auth/login"
PROFILE_ENDPOINT = f"{BASE_URL}/api/profiles"

def login_user(credentials):
    """Login as a user and get JWT token"""
    print(f"Logging in as {credentials['email']}...")
    
    response = requests.post(
        LOGIN_ENDPOINT, 
        headers={"Content-Type": "application/json"},
        data=json.dumps(credentials)
    )
    
    if response.status_code == 200:
        token = response.json().get("token")
        print(f"✅ Successfully logged in as {credentials['email']}")
        return token
    else:
        print(f"❌ Failed to login: {response.status_code} - {response.text}")
        return None

def register_user(user_data):
    """Register a new user and get JWT token"""
    print(f"Registering user: {user_data['name']} ({user_data['email']})...")
    
    registration_data = {
        "name": user_data["name"],
        "email": user_data["email"],
        "password": user_data["password"]
    }
    
    response = requests.post(
        REGISTER_ENDPOINT,
        headers={"Content-Type": "application/json"},
        data=json.dumps(registration_data)
    )
    
    if response.status_code == 201:
        print(f"✅ Successfully registered user {user_data['name']}")
        # Extract JWT token from response
        jwt_token = response.json().get("token")
        return jwt_token
    elif response.status_code == 409:
        print(f"⚠️ User {user_data['email']} already exists")
        # For existing users, we'll try to login instead
        return "existing"
    else:
        print(f"❌ Failed to register user: {response.status_code} - {response.text}")
        return None

def create_profile(token, profile_data):
    """Create a profile for a registered user"""
    print(f"Creating profile for: {profile_data['email']}...")
    
    response = requests.post(
        PROFILE_ENDPOINT,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        },
        data=json.dumps(profile_data)
    )
    
    if response.status_code == 201:
        print(f"✅ Successfully created profile for {profile_data['email']}")
        return True
    elif response.status_code == 409:
        print(f"⚠️ Profile for {profile_data['email']} already exists")
        return True  # Consider it a success since the profile exists
    else:
        print(f"❌ Failed to create profile: {response.status_code} - {response.text}")
        return False

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Register users from JSON and create profiles")
    parser.add_argument('--file', default="json/users.json", help="Path to users JSON file")
    parser.add_argument('--dry-run', action='store_true', help="Validate without making changes")
    args = parser.parse_args()
    
    json_file = args.file
    dry_run = args.dry_run
    
    # Check if the JSON file exists
    if not os.path.exists(json_file):
        print(f"Error: {json_file} not found!")
        return
    
    # Load user data from JSON file
    try:
        with open(json_file, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError:
        print(f"Error: {json_file} is not a valid JSON file")
        return
    except Exception as e:
        print(f"Error reading {json_file}: {str(e)}")
        return
    
    # Extract data
    if 'users' not in data:
        print("Error: JSON file must contain 'users' section")
        return
    
    users = data['users']
    updated_users = False
    
    if dry_run:
        print("DRY RUN MODE: No changes will be made")
    
    # Register users and create profiles
    success_count_registration = 0
    success_count_profile = 0
    jwt_tokens_updated = 0
    
    print(f"\nProcessing {len(users)} user accounts...")
    
    for index, user in enumerate(users, 1):
        print(f"\n[{index}/{len(users)}] Processing user: {user['name']}")
        
        if dry_run:
            continue
            
        # Step 1: Register the user and get JWT token
        token = register_user(user)
        is_new_user = token != "existing"
        
        # If user already exists, try to login instead
        if token == "existing":
            token = login_user({
                "email": user["email"],
                "password": user["password"]
            })
        
        if token:
            # Store JWT token in user data
            user["jwt"] = token
            updated_users = True
            jwt_tokens_updated += 1
            success_count_registration += 1
            
            # Step 2: Create profile ONLY for newly registered users
            if is_new_user:
                profile_data = {
                    "email": user["email"],
                    "contact": user["contact"],
                    "college": user["college"],
                    "year": user["year"],
                    "department": user["department"],
                    "rollNo": user["rollNo"]
                }
                
                if create_profile(token, profile_data):
                    success_count_profile += 1
            else:
                print(f"ℹ️ Skipping profile creation for existing user: {user['email']}")
    
    # Save updated user data with JWT tokens
    if updated_users and not dry_run:
        try:
            with open(json_file, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"✅ Updated {json_file} with JWT tokens")
        except Exception as e:
            print(f"❌ Error updating {json_file}: {str(e)}")
    
    # Print summary
    print("\n=== User Registration and Profile Creation Summary ===")
    print(f"Total user accounts processed: {len(users)}")
    if not dry_run:
        print(f"Successfully registered/validated: {success_count_registration}")
        print(f"Successfully created profiles: {success_count_profile}")
        print(f"JWT tokens updated: {jwt_tokens_updated}")
        print(f"Failed: {len(users) - success_count_registration}")
    else:
        print("Dry run completed, no changes were made.")

if __name__ == "__main__":
    main()