import csv
import requests
import json
import argparse
import os
import re

# API configuration
BASE_URL = "http://localhost:8080"
TEAM_ENDPOINT = f"{BASE_URL}/api/megatronix-team"
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

def convert_year_format(year_str):
    """Convert '4th Year' to 'FOURTH' etc."""
    year_mapping = {
        "1st year": "FIRST",
        "1st Year": "FIRST",
        "first year": "FIRST",
        "First Year": "FIRST",
        "2nd year": "SECOND",
        "2nd Year": "SECOND",
        "second year": "SECOND",
        "Second Year": "SECOND",
        "3rd year": "THIRD",
        "3rd Year": "THIRD",
        "third year": "THIRD", 
        "Third Year": "THIRD",
        "4th year": "FOURTH",
        "4th Year": "FOURTH",
        "fourth year": "FOURTH",
        "Fourth Year": "FOURTH"
    }
    
    return year_mapping.get(year_str, "FOURTH")  # Default to FOURTH if mapping not found

def clean_link(link):
    """Clean and validate links, return empty string if invalid"""
    if not link or link.lower() in ["", "n/a", "null", "none", "n/ a"]:
        return ""
    
    # Ensure links start with http:// or https://
    if link and not link.startswith(("http://", "https://")):
        if re.match(r'^www\.', link):
            return f"https://{link}"
        elif re.match(r'^[a-zA-Z0-9]', link):
            return f"https://www.{link}"
    
    return link

def extract_google_drive_id(drive_link):
    """Extract the file ID from a Google Drive link"""
    if not drive_link:
        return ""
    
    # Extract ID from forms_web format
    match = re.search(r'id=([a-zA-Z0-9_-]+)', drive_link)
    if match:
        file_id = match.group(1)
        return f"https://drive.google.com/uc?export=view&id={file_id}"
    
    return ""

def create_team_member(token, member_data):
    """Create a Megatronix team member entry"""
    print(f"Creating team member: {member_data['name']} ({member_data['email']})...")
    
    response = requests.post(
        TEAM_ENDPOINT,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        },
        data=json.dumps(member_data)
    )
    
    if response.status_code == 201:
        print(f"✅ Successfully added {member_data['name']} to Megatronix team")
        return True
    elif response.status_code == 409:
        print(f"⚠️ Team member {member_data['email']} already exists")
        return True
    else:
        print(f"❌ Failed to add team member: {response.status_code} - {response.text}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Import Megatronix team members from CSV")
    parser.add_argument('--csv-file', default="team-members/Contact Information.csv", help="Path to CSV file")
    parser.add_argument('--admins-file', default="json/admins.json", help="Path to admins JSON file")
    parser.add_argument('--dry-run', action='store_true', help="Validate without making changes")
    args = parser.parse_args()
    
    csv_file = args.csv_file
    admins_file = args.admins_file
    dry_run = args.dry_run
    
    # Check if the files exist
    if not os.path.exists(csv_file):
        print(f"Error: CSV file {csv_file} not found!")
        return
        
    if not os.path.exists(admins_file):
        print(f"Error: Admin JSON file {admins_file} not found!")
        return
    
    # Load admin data to get superadmin token
    try:
        with open(admins_file, 'r') as f:
            admins_data = json.load(f)
            
        superadmin = admins_data.get('superadmin', {})
        superadmin_token = superadmin.get('jwt', '')
        
        if not is_token_valid(superadmin_token):
            print("Error: Superadmin token is invalid or expired.")
            print("Please run register-admins.py to refresh the token.")
            return
    except Exception as e:
        print(f"Error loading admins file: {str(e)}")
        return
    
    # Read CSV file
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            team_members = list(reader)
    except Exception as e:
        print(f"Error reading CSV file: {str(e)}")
        return
    
    print(f"Found {len(team_members)} team members in CSV file")
    
    if dry_run:
        print("DRY RUN MODE: No changes will be made")
    
    # Process each team member
    success_count = 0
    failed_count = 0
    
    for index, member in enumerate(team_members, 1):
        print(f"\n[{index}/{len(team_members)}] Processing: {member['Name']}")
        
        # Prepare member data for API
        member_data = {
            "name": member['Name'].strip(),
            "email": member['Email'].strip(),
            "year": convert_year_format(member['Year'].strip()),
            "linkedInLink": clean_link(member['LinkedIn Profile Link']),
            "facebookLink": clean_link(member['Facebook Profile Link']),
            "instagramLink": clean_link(member['Instagram Profile Link']),
            "githubLink": clean_link(member['GitHub Account Link']),
            "imageLink": extract_google_drive_id(member['Profile Picture']),
            "designation": "MEMBER"  # Default designation
        }
        
        if dry_run:
            print(json.dumps(member_data, indent=2))
            continue
        
        # Create team member
        if create_team_member(superadmin_token, member_data):
            success_count += 1
        else:
            failed_count += 1
    
    # Print summary
    print("\n=== Megatronix Team Creation Summary ===")
    print(f"Total team members processed: {len(team_members)}")
    if not dry_run:
        print(f"Successfully added: {success_count}")
        print(f"Failed: {failed_count}")
    else:
        print("Dry run completed, no changes were made.")

if __name__ == "__main__":
    main()