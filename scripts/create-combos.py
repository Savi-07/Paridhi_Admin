import requests
import json
import os
import random
import argparse

# API configuration
BASE_URL = "http://localhost:8080"
EVENTS_ENDPOINT = f"{BASE_URL}/api/events"
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

def create_combo(token, combo_data):
    """Create a new combo using admin token"""
    print(f"Creating combo: {combo_data['name']}")
    
    response = requests.post(
        COMBOS_ENDPOINT,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        },
        data=json.dumps(combo_data)
    )
    
    if response.status_code == 201:
        print(f"✅ Successfully created combo: {combo_data['name']}")
        return True
    elif response.status_code == 409:
        print(f"⚠️ Combo {combo_data['name']} already exists")
        return True
    else:
        print(f"❌ Failed to create combo: {response.status_code} - {response.text}")
        return False

def main():
    # Setup argument parser
    parser = argparse.ArgumentParser(description="Create event combos")
    parser.add_argument('--admins-file', default="json/admins.json", help="Path to admins JSON file")
    parser.add_argument('--dry-run', action='store_true', help="Validate without making changes")
    args = parser.parse_args()
    
    admins_file = args.admins_file
    dry_run = args.dry_run
    
    # Check if files exist
    if not os.path.exists(admins_file):
        print(f"Error: {admins_file} not found!")
        return
    
    # Load admin data
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
        print("No valid admin tokens found. Cannot create combos.")
        return
    
    # Select a random admin
    admin = random.choice(admin_tokens)
    print(f"Using admin: {admin['name']} ({admin['email']})")
    
    # Get all events
    events = get_all_events(admin['token'])
    if not events:
        return
    
    # Create a map of events by domain
    events_by_domain = {}
    events_by_name = {}
    
    for event in events:
        domain = event.get('domain')
        name = event.get('name')
        event_id = event.get('id')
        
        if domain:
            if domain not in events_by_domain:
                events_by_domain[domain] = []
            events_by_domain[domain].append(event)
        
        if name:
            events_by_name[name] = event
    
    # Define combos
    combos = []
    
    # ROBOTICS combos
    if 'ROBOTICS' in events_by_domain:
        robotics_events = events_by_domain['ROBOTICS']
        
        # Throne of Bots combo (8kg and 15kg)
        throne_8kg = next((e for e in robotics_events if "8kg" in e.get('name', '')), None)
        throne_15kg = next((e for e in robotics_events if "15kg" in e.get('name', '')), None)
        
        if throne_8kg and throne_15kg:
            combos.append({
                "name": "Robo Battle Combo",
                "description": "Register for both Throne of Bots weight classes at a discounted price!",
                "domain": "ROBOTICS",
                "eventIds": [throne_8kg['id'], throne_15kg['id']],
                "registrationFee": 800  # Instead of 500 + 600 = 1100
            })
        
        # Triathlon + Chakravyuh
        triathlon = next((e for e in robotics_events if "Triathlon" in e.get('name', '')), None)
        chakravyuh = next((e for e in robotics_events if "Chakravyuh" in e.get('name', '')), None)
        
        if triathlon and chakravyuh:
            combos.append({
                "name": "Robot Challenge Pack",
                "description": "Master both Triathlon and Chakravyuh challenges with one registration!",
                "domain": "ROBOTICS",
                "eventIds": [triathlon['id'], chakravyuh['id']],
                "registrationFee": 500  # Instead of 300 + 350 = 650
            })
    
    # CODING combos
    if 'CODING' in events_by_domain:
        coding_events = events_by_domain['CODING']
        
        # Code Quest + Bug Blitz
        code_quest = next((e for e in coding_events if "Code Quest" in e.get('name', '')), None)
        bug_blitz = next((e for e in coding_events if "Bug Blitz" in e.get('name', '')), None)
        
        if code_quest and bug_blitz:
            combos.append({
                "name": "Pro Coder Pack",
                "description": "Showcase your coding skills in both competitive programming and debugging!",
                "domain": "CODING",
                "eventIds": [code_quest['id'], bug_blitz['id']],
                "registrationFee": 300  # Instead of 250 + 150 = 400
            })
    
    # GAMING combos
    if 'GAMING' in events_by_domain:
        gaming_events = events_by_domain['GAMING']
        
        # Valorant + BGMI combo
        valorant = next((e for e in gaming_events if "Valorant" in e.get('name', '')), None)
        bgmi = next((e for e in gaming_events if "BGMI" in e.get('name', '')), None)
        
        if valorant and bgmi:
            combos.append({
                "name": "Shooter Games Bundle",
                "description": "Join both Valorant and BGMI tournaments at a reduced price!",
                "domain": "GAMING",
                "eventIds": [valorant['id'], bgmi['id']],
                "registrationFee": 700  # Instead of 500 + 400 = 900
            })
        
        # EA FC24 + E-Football
        ea_fc24 = next((e for e in gaming_events if "EA FC24" in e.get('name', '')), None)
        efootball = next((e for e in gaming_events if "E-Football" in e.get('name', '')), None)
        
        if ea_fc24 and efootball:
            combos.append({
                "name": "Football Gaming Bundle",
                "description": "Experience both EA FC24 and E-Football tournaments!",
                "domain": "GAMING",
                "eventIds": [ea_fc24['id'], efootball['id']],
                "registrationFee": 250  # Instead of 200 + 150 = 350
            })
    
    # CIVIL combos
    if 'CIVIL' in events_by_domain:
        civil_events = events_by_domain['CIVIL']
        
        # Mega-Arch + CAD-O-Mania
        mega_arch = next((e for e in civil_events if "Mega-Arch" in e.get('name', '')), None)
        cad_o_mania = next((e for e in civil_events if "CAD-O-Mania" in e.get('name', '')), None)
        
        if mega_arch and cad_o_mania:
            combos.append({
                "name": "Design Master Combo",
                "description": "Showcase your civil design skills in both physical and digital formats!",
                "domain": "CIVIL",
                "eventIds": [mega_arch['id'], cad_o_mania['id']],
                "registrationFee": 400  # Instead of 300 + 200 = 500
            })
    
    # GENERAL combos
    if 'GENERAL' in events_by_domain:
        general_events = events_by_domain['GENERAL']
        
        # Chess + Carrom
        chess = next((e for e in general_events if "Chess" in e.get('name', '')), None)
        carrom = next((e for e in general_events if "Carrom" in e.get('name', '')), None)
        
        if chess and carrom:
            combos.append({
                "name": "Board Games Pack",
                "description": "Participate in both Chess and Carrom competitions!",
                "domain": "GENERAL",
                "eventIds": [chess['id'], carrom['id']],
                "registrationFee": 150  # Instead of 100 + 100 = 200
            })
    
    # ELECTRICAL combos
    if 'ELECTRICAL' in events_by_domain and len(events_by_domain['ELECTRICAL']) >= 2:
        electrical_events = events_by_domain['ELECTRICAL']
        
        # Power-Blitz + Electri-Quest
        if len(electrical_events) >= 2:
            combos.append({
                "name": "Electrical Engineering Bundle",
                "description": "Complete package for electrical engineering enthusiasts!",
                "domain": "ELECTRICAL",
                "eventIds": [electrical_events[0]['id'], electrical_events[1]['id']],
                "registrationFee": 250  # Instead of 200 + 150 = 350
            })
    
    # Create the combos
    print(f"\nCreating {len(combos)} combo events...")
    
    success_count = 0
    failed_count = 0
    
    for index, combo in enumerate(combos, 1):
        print(f"\n[{index}/{len(combos)}] Processing combo: {combo['name']}")
        
        if not dry_run:
            if create_combo(admin['token'], combo):
                success_count += 1
            else:
                failed_count += 1
    
    # Print summary
    print("\n=== Combo Creation Summary ===")
    print(f"Total combos processed: {len(combos)}")
    if not dry_run:
        print(f"Successfully created/validated: {success_count}")
        print(f"Failed: {failed_count}")
    else:
        print("Dry run completed, no changes were made.")

if __name__ == "__main__":
    main()