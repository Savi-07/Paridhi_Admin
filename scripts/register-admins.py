import requests
import json
import time
import os
import argparse

# API configuration
BASE_URL = "http://localhost:8080"
LOGIN_ENDPOINT = f"{BASE_URL}/api/auth/login"
ADMIN_ENDPOINT = f"{BASE_URL}/api/admin"

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

def is_token_valid(token):
    """Check if a JWT token is still valid"""
    if not token:
        return False
        
    # Make a simple request to check token validity
    test_endpoint = f"{BASE_URL}/api/auth/verify"
    try:
        response = requests.get(
            test_endpoint,
            headers={"Authorization": f"Bearer {token}"}
        )
        return response.status_code == 200
    except:
        return False

def create_admin(token, admin_data):
    """Create a new admin user"""
    print(f"Creating admin: {admin_data['name']} ({admin_data['email']})...")
    
    # Extract only the needed fields for admin creation
    create_data = {
        "name": admin_data["name"],
        "email": admin_data["email"],
        "password": admin_data["password"]
    }
    
    # Add role if present
    if "role" in admin_data:
        create_data["role"] = admin_data["role"]
    
    # Add department if present
    if "department" in admin_data:
        create_data["department"] = admin_data["department"]
    
    response = requests.post(
        ADMIN_ENDPOINT,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        },
        data=json.dumps(create_data)
    )
    
    if response.status_code == 201:
        print(f"✅ Successfully created admin {admin_data['name']}")
        # Extract JWT token directly from the response
        admin_token = response.json().get("token")
        return admin_token
    elif response.status_code == 409:
        print(f"⚠️ Admin {admin_data['email']} already exists")
        # For existing admins, we can still try to get their token
        return "existing"
    else:
        print(f"❌ Failed to create admin: {response.status_code} - {response.text}")
        return None

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Register admin users from JSON")
    parser.add_argument('--file', default="json/admins.json", help="Path to admins JSON file")
    parser.add_argument('--dry-run', action='store_true', help="Validate without making changes")
    args = parser.parse_args()
    
    json_file = args.file
    dry_run = args.dry_run
    
    # Check if the JSON file exists
    if not os.path.exists(json_file):
        print(f"Error: {json_file} not found!")
        return
    
    # Load admin data from JSON file
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
    if 'superadmin' not in data or 'admins' not in data:
        print("Error: JSON file must contain 'superadmin' and 'admins' sections")
        return
    
    superadmin = data['superadmin']
    admins = data['admins']
    updated_data = False
    
    if dry_run:
        print("DRY RUN MODE: No changes will be made")
        
    # Check if superadmin token is valid, otherwise login
    superadmin_token = superadmin.get("jwt", "")
    if not is_token_valid(superadmin_token):
        print("Superadmin token is missing or invalid. Getting a new one...")
        superadmin_token = login_user(superadmin)
        if not superadmin_token:
            print("Exiting due to superadmin login failure")
            return
        
        if not dry_run:
            # Store JWT token for superadmin
            superadmin["jwt"] = superadmin_token
            updated_data = True
    
    # Create admin users
    success_count = 0
    admin_tokens_updated = 0
    
    print(f"\nProcessing {len(admins)} admin accounts...")
    
    for index, admin in enumerate(admins, 1):
        print(f"\n[{index}/{len(admins)}] Processing admin: {admin['name']}")
        
        if not dry_run:
            admin_token = create_admin(superadmin_token, admin)
            
            if admin_token:
                success_count += 1
                
                # If we got a token directly from the creation response, store it
                if admin_token != "existing":
                    admin["jwt"] = admin_token
                    admin_tokens_updated += 1
                    updated_data = True
                # If admin already exists, we might need to login to get their token
                elif admin_token == "existing":
                    login_token = login_user({
                        "email": admin["email"],
                        "password": admin["password"]
                    })
                    if login_token:
                        admin["jwt"] = login_token
                        admin_tokens_updated += 1
                        updated_data = True
    
    # Save updated admin data with JWT tokens
    if updated_data and not dry_run:
        try:
            # Update the original file directly without backup
            with open(json_file, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"✅ Updated {json_file} with JWT tokens")
        except Exception as e:
            print(f"❌ Error updating {json_file}: {str(e)}")
    
    # Print summary
    print("\n=== Admin Creation Summary ===")
    print(f"Total admin accounts processed: {len(admins)}")
    if not dry_run:
        print(f"Successfully created/validated: {success_count}")
        print(f"JWT tokens updated: {admin_tokens_updated}")
        print(f"Failed: {len(admins) - success_count}")
    else:
        print("Dry run completed, no changes were made.")

if __name__ == "__main__":
    main()