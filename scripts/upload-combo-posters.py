import requests
import json
import os
import random
import argparse

# API configuration
BASE_URL = "http://localhost:8080"
COMBOS_ENDPOINT = f"{BASE_URL}/api/combos"
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

def get_all_combos(token):
    """Get all combos from the API"""
    print("Fetching all combos...")
    
    response = requests.get(
        COMBOS_ENDPOINT,
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code == 200:
        combos = response.json()
        print(f"✅ Successfully retrieved {len(combos)} combos")
        return combos
    else:
        print(f"❌ Failed to retrieve combos: {response.status_code} - {response.text}")
        return None

def upload_combo_poster(token, combo_id, image_path):
    """Upload a poster image for a combo"""
    upload_endpoint = f"{COMBOS_ENDPOINT}/{combo_id}/upload"
    
    try:
        with open(image_path, 'rb') as image_file:
            files = {'file': (os.path.basename(image_path), image_file, 'image/jpeg')}
            
            response = requests.put(
                upload_endpoint,
                headers={"Authorization": f"Bearer {token}"},
                files=files
            )
            
            if response.status_code == 200:
                print(f"✅ Successfully uploaded poster for combo ID {combo_id}")
                return True
            else:
                print(f"❌ Failed to upload poster for combo ID {combo_id}: {response.status_code} - {response.text}")
                return False
    except Exception as e:
        print(f"❌ Error uploading poster for combo ID {combo_id}: {str(e)}")
        return False

def find_domain_poster(posters_dir, domain):
    """Find a poster for a domain"""
    # Try different file extensions
    extensions = ['.jpeg', '.jpg', '.png', '.gif']
    
    for ext in extensions:
        domain_poster = os.path.join(posters_dir, f"{domain}{ext}")
        if os.path.exists(domain_poster):
            return domain_poster
    
    return None

def main():
    parser = argparse.ArgumentParser(description="Upload combo posters")
    parser.add_argument('--posters-dir', default="event-posters", help="Directory containing poster images")
    parser.add_argument('--admins-file', default="json/admins.json", help="Path to admins JSON file")
    args = parser.parse_args()
    
    posters_dir = args.posters_dir
    admins_file = args.admins_file
    
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
    
    # Get all combos from the API
    combos = get_all_combos(admin['token'])
    if not combos:
        return
    
    # Display available domain poster files
    poster_files = [f for f in os.listdir(posters_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.gif'))]
    print(f"\nFound {len(poster_files)} poster files in {posters_dir}:")
    for i, poster in enumerate(sorted(poster_files)):
        print(f"  {i+1}. {poster}")
    
    # Process each combo
    print(f"\nProcessing {len(combos)} combos...")
    success_count = 0
    no_poster_count = 0
    
    for index, combo in enumerate(combos, 1):
        combo_id = combo.get('id')
        combo_name = combo.get('name', 'Unknown')
        domain = combo.get('domain', 'Unknown')
        
        print(f"\n[{index}/{len(combos)}] Processing: {domain} - {combo_name} (ID: {combo_id})")
        
        # Find domain poster
        domain_poster = find_domain_poster(posters_dir, domain)
        
        if domain_poster:
            print(f"  Using domain poster: {os.path.basename(domain_poster)}")
            
            # Upload the poster
            if upload_combo_poster(admin['token'], combo_id, domain_poster):
                success_count += 1
        else:
            print(f"  ⚠️ No domain poster found for '{domain}'")
            print(f"  Suggested filename: {domain}.jpeg")
            no_poster_count += 1
    
    # Print summary
    print("\n=== Combo Poster Upload Summary ===")
    print(f"Total combos processed: {len(combos)}")
    print(f"Successfully uploaded posters: {success_count}")
    print(f"Combos with no poster available: {no_poster_count}")
    print(f"Failed uploads: {len(combos) - success_count - no_poster_count}")

if __name__ == "__main__":
    main()