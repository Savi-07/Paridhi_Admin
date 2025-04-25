import requests
import json
import time
import os
import random
import argparse

# API configuration
BASE_URL = "http://localhost:8080"
EVENT_ENDPOINT = f"{BASE_URL}/api/events"
AUTH_VERIFY_ENDPOINT = f"{BASE_URL}/api/auth/check-token"

def is_token_valid(token):
    """Check if a JWT token is still valid"""
    if not token:
        return False
        
    try:
        response = requests.get(
            AUTH_VERIFY_ENDPOINT,
            headers={"Authorization": f"Bearer {token}"}
        )
        return response.status_code == 200
    except Exception as e:
        print(f"Error checking token validity: {str(e)}")
        return False

def create_event(token, event_data):
    """Create a new event using admin token"""
    
    print(f"Creating event: {event_data['name']} ({event_data['domain']})")
    
    response = requests.post(
        EVENT_ENDPOINT,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        },
        data=json.dumps(event_data)
    )
    
    if response.status_code == 201:
        print(f"✅ Successfully created event: {event_data['name']}")
        return True
    elif response.status_code == 409:
        print(f"⚠️ Event {event_data['name']} already exists")
        return True
    else:
        print(f"❌ Failed to create event: {response.status_code} - {response.text}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Create events using admin accounts")
    parser.add_argument('--events-file', default="json/events.json", help="Path to events JSON file")
    parser.add_argument('--admins-file', default="json/admins.json", help="Path to admins JSON file")
    parser.add_argument('--dry-run', action='store_true', help="Validate without making changes")
    args = parser.parse_args()
    
    events_file = args.events_file
    admins_file = args.admins_file
    dry_run = args.dry_run
    
    # Check if the files exist
    if not os.path.exists(events_file):
        print(f"Error: {events_file} not found!")
        return
        
    if not os.path.exists(admins_file):
        print(f"Error: {admins_file} not found!")
        return
    
    # Load events data
    try:
        with open(events_file, 'r') as f:
            events_data = json.load(f)
    except Exception as e:
        print(f"Error loading events file: {str(e)}")
        return
    
    # Load admins data
    try:
        with open(admins_file, 'r') as f:
            admins_data = json.load(f)
    except Exception as e:
        print(f"Error loading admins file: {str(e)}")
        return
    
    # Extract data
    if 'events' not in events_data:
        print("Error: JSON file must contain 'events' section")
        return
    
    events = events_data['events']
    
    # Collect all admin tokens (including superadmin)
    admin_tokens = []
    
    # Add superadmin token if valid
    superadmin = admins_data.get('superadmin', {})
    superadmin_token = superadmin.get('jwt', '')
    if is_token_valid(superadmin_token):
        admin_tokens.append({
            'name': superadmin.get('name', 'Superadmin'),
            'email': superadmin.get('email', 'unknown'),
            'token': superadmin_token
        })
    
    # Add regular admin tokens if valid
    admins = admins_data.get('admins', [])
    for admin in admins:
        admin_token = admin.get('jwt', '')
        if is_token_valid(admin_token):
            admin_tokens.append({
                'name': admin.get('name', 'Admin'),
                'email': admin.get('email', 'unknown'),
                'token': admin_token
            })
    
    if not admin_tokens:
        print("No valid admin tokens found. Cannot create events.")
        return
    
    print(f"Found {len(admin_tokens)} valid admin tokens")
    
    if dry_run:
        print("DRY RUN MODE: No changes will be made")
    
    # Create events using random admin tokens
    success_count = 0
    failed_count = 0
    
    print(f"\nProcessing {len(events)} events...")
    
    for index, event in enumerate(events, 1):
        # Select a random admin
        admin = random.choice(admin_tokens)
        
        print(f"\n[{index}/{len(events)}] Using admin: {admin['name']} ({admin['email']})")
        
        if not dry_run:
            if create_event(admin['token'], event):
                success_count += 1
            else:
                failed_count += 1
    
    # Print summary
    print("\n=== Event Creation Summary ===")
    print(f"Total events processed: {len(events)}")
    if not dry_run:
        print(f"Successfully created/validated: {success_count}")
        print(f"Failed: {failed_count}")
    else:
        print("Dry run completed, no changes were made.")

if __name__ == "__main__":
    main()