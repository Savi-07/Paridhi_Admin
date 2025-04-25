import requests
import json
import time
import os
import argparse

# API configuration
BASE_URL = "http://localhost:8080"
MRD_ENDPOINT = f"{BASE_URL}/api/mrd/register"

def register_mrd(email):
    """Register a user for MRD and get their GID"""
    print(f"Registering MRD for: {email}...")
    
    request_data = {
        "email": email
    }
    
    response = requests.post(
        MRD_ENDPOINT,
        headers={"Content-Type": "application/json"},
        data=json.dumps(request_data)
    )
    
    if response.status_code == 201:
        mrd_data = response.json()
        gid = mrd_data.get("gid")
        print(f"✅ Successfully registered MRD for {email} - GID: {gid}")
        return gid, mrd_data
    else:
        print(f"❌ Failed to register MRD: {response.status_code} - {response.text}")
        return None, None

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Register users for MRD and store GIDs")
    parser.add_argument('--file', default="json/users.json", help="Path to users JSON file")
    parser.add_argument('--mrd-count', type=int, default=10, help="Number of MRD registrations per user")
    args = parser.parse_args()
    
    json_file = args.file
    mrd_count = args.mrd_count
    
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
    all_mrd_data = []
    total_successful = 0
    
    print(f"\nProcessing {len(users)} users, {mrd_count} MRD registrations each...")
    
    # Process each user
    for user_index, user in enumerate(users, 1):
        print(f"\n[User {user_index}/{len(users)}] Processing: {user['name']} ({user['email']})")
        
        # Initialize gids array if it doesn't exist
        if "gids" not in user:
            user["gids"] = []
        
        # Perform MRD registrations for this user
        successful_registrations = 0
        
        for mrd_index in range(mrd_count):
            print(f"  MRD registration {mrd_index+1}/{mrd_count}")
            gid, mrd_data = register_mrd(user["email"])
            
            if gid:
                user["gids"].append(gid)
                all_mrd_data.append(mrd_data)
                successful_registrations += 1
                updated_users = True
        
        total_successful += successful_registrations
        print(f"  Completed {successful_registrations}/{mrd_count} MRD registrations for {user['email']}")
    
    # Save updated user data with GIDs
    if updated_users:
        try:
            with open(json_file, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"✅ Updated {json_file} with GIDs")
        except Exception as e:
            print(f"❌ Error updating {json_file}: {str(e)}")
        
    # Save detailed MRD data to a separate file for reference
    try:
        mrd_file = "json/mrd_data.json"
        with open(mrd_file, 'w') as f:
            json.dump(all_mrd_data, f, indent=2)
        print(f"✅ Saved detailed MRD data to {mrd_file}")
    except Exception as e:
        print(f"❌ Error saving MRD data: {str(e)}")
    
    # Print summary
    print("\n=== MRD Registration Summary ===")
    print(f"Total users processed: {len(users)}")
    print(f"MRD registrations per user: {mrd_count}")
    print(f"Total MRD registrations attempted: {len(users) * mrd_count}")
    print(f"Total successful registrations: {total_successful}")
    print(f"Failed registrations: {(len(users) * mrd_count) - total_successful}")

if __name__ == "__main__":
    main()