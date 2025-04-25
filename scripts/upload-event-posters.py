import requests
import json
import time
import os
import random
import argparse
import re

# API configuration
BASE_URL = "http://localhost:8080"
EVENTS_ENDPOINT = f"{BASE_URL}/api/events"
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

def get_all_events(token):
    """Get all events from the API"""
    print("Fetching all events...")
    
    response = requests.get(
        EVENTS_ENDPOINT,
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code == 200:
        events = response.json()
        print(f"✅ Successfully retrieved {len(events)} events")
        return events
    else:
        print(f"❌ Failed to retrieve events: {response.status_code} - {response.text}")
        return None

def upload_poster(token, event_id, image_path):
    """Upload a poster image for an event"""
    upload_endpoint = f"{EVENTS_ENDPOINT}/{event_id}/upload"
    
    try:
        with open(image_path, 'rb') as image_file:
            files = {'file': (os.path.basename(image_path), image_file, 'image/jpeg')}
            
            response = requests.put(
                upload_endpoint,
                headers={"Authorization": f"Bearer {token}"},
                files=files
            )
            
            if response.status_code == 200:
                print(f"✅ Successfully uploaded poster for event ID {event_id}")
                return True
            else:
                print(f"❌ Failed to upload poster for event ID {event_id}: {response.status_code} - {response.text}")
                return False
    except Exception as e:
        print(f"❌ Error uploading poster for event ID {event_id}: {str(e)}")
        return False

def normalize_name(name):
    """Normalize event name for filename matching"""
    # Remove special characters and spaces, convert to lowercase
    return re.sub(r'[^a-zA-Z0-9]', '', name).lower()

def find_event_poster(posters_dir, domain, event_name):
    """Find a poster for an event with fallback to domain poster"""
    # Normalize event name for matching
    normalized_event_name = normalize_name(event_name)
    
    # Try different file extensions
    extensions = ['.jpeg', '.jpg', '.png', '.gif']
    
    # 1. First, check for exact domain_eventName match (case-insensitive)
    for ext in extensions:
        # Check exact format: DOMAIN_EventName.ext
        specific_poster = os.path.join(posters_dir, f"{domain}_{event_name.replace(' ', '')}{ext}")
        if os.path.exists(specific_poster):
            return specific_poster, "event"
        
        # Try with underscores: DOMAIN_Event_Name.ext
        specific_poster = os.path.join(posters_dir, f"{domain}_{event_name.replace(' ', '_')}{ext}")
        if os.path.exists(specific_poster):
            return specific_poster, "event"
    
    # 2. Search for any file that contains domain + event name
    for filename in os.listdir(posters_dir):
        if os.path.isfile(os.path.join(posters_dir, filename)):
            filename_normalized = normalize_name(os.path.splitext(filename)[0])
            if domain.lower() in filename_normalized and normalized_event_name in filename_normalized:
                return os.path.join(posters_dir, filename), "event"
    
    # 3. Fall back to domain-level poster
    for ext in extensions:
        domain_poster = os.path.join(posters_dir, f"{domain}{ext}")
        if os.path.exists(domain_poster):
            return domain_poster, "domain"
    
    # 4. No matching poster found
    return None, None

def main():
    parser = argparse.ArgumentParser(description="Upload event posters")
    parser.add_argument('--posters-dir', default="event-posters", help="Directory containing poster images")
    parser.add_argument('--admins-file', default="json/admins.json", help="Path to admins JSON file")
    parser.add_argument('--events-file', default="json/events.json", help="Path to events JSON file (optional)")
    args = parser.parse_args()
    
    posters_dir = args.posters_dir
    admins_file = args.admins_file
    events_file = args.events_file
    
    # Check if posters directory exists
    if not os.path.exists(posters_dir):
        print(f"Error: Posters directory {posters_dir} not found!")
        print("Please create the directory and add poster images before running this script.")
        return
    
    # Check if admins file exists
    if not os.path.exists(admins_file):
        print(f"Error: {admins_file} not found!")
        return
    
    # Load admin data to get tokens
    try:
        with open(admins_file, 'r') as f:
            admins_data = json.load(f)
    except Exception as e:
        print(f"Error loading admins file: {str(e)}")
        return
    
    # Get valid admin tokens
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
        print("No valid admin tokens found. Cannot upload posters.")
        return
    
    # Select a random admin to use
    admin = random.choice(admin_tokens)
    print(f"Using admin: {admin['name']} ({admin['email']})")
    
    # Get all events from the API
    events = get_all_events(admin['token'])
    if not events:
        return
    
    # Load events file for additional domain info if available
    local_events_map = {}
    if events_file and os.path.exists(events_file):
        try:
            with open(events_file, 'r') as f:
                events_data = json.load(f)
                local_events = events_data.get('events', [])
                
                # Create a map for easier lookup
                for event in local_events:
                    local_events_map[event['name']] = event
                print(f"Loaded {len(local_events)} events from local file for domain information")
        except Exception as e:
            print(f"Warning: Could not load events file: {str(e)}")
    
    # Process each event
    print(f"\nProcessing {len(events)} events...")
    event_success = 0
    domain_fallback = 0
    no_poster = 0
    
    # Display available poster files
    poster_files = [f for f in os.listdir(posters_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.gif'))]
    print(f"\nFound {len(poster_files)} poster files in {posters_dir}:")
    for i, poster in enumerate(sorted(poster_files)):
        print(f"  {i+1}. {poster}")
    
    for index, event in enumerate(events, 1):
        event_id = event.get('id')
        event_name = event.get('name', 'Unknown')
        
        # Get domain from local file if available, otherwise use placeholder
        domain = "UNKNOWN"
        if event_name in local_events_map:
            domain = local_events_map[event_name].get('domain', 'UNKNOWN')
        
        print(f"\n[{index}/{len(events)}] Processing: {domain} - {event_name} (ID: {event_id})")
        
        # Find appropriate poster with fallback logic
        poster_path, poster_type = find_event_poster(posters_dir, domain, event_name)
        
        if poster_path and poster_type == "event":
            print(f"  Found event-specific poster: {os.path.basename(poster_path)}")
            event_success += 1
        elif poster_path and poster_type == "domain":
            print(f"  Using domain fallback poster: {os.path.basename(poster_path)}")
            domain_fallback += 1
        else:
            print(f"  ⚠️ No matching poster found for '{domain} - {event_name}'")
            print(f"  Suggested filename: {domain}_{event_name.replace(' ', '')}.jpeg")
            no_poster += 1
            continue
        
        # Upload the chosen poster
        upload_poster(admin['token'], event_id, poster_path)
    
    # Print summary
    print("\n=== Poster Upload Summary ===")
    print(f"Total events processed: {len(events)}")
    print(f"Event-specific posters used: {event_success}")
    print(f"Domain fallback posters used: {domain_fallback}")
    print(f"Events with no poster available: {no_poster}")

if __name__ == "__main__":
    main()