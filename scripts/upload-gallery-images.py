import requests
import json
import os
import random
import argparse

# API configuration
BASE_URL = "http://localhost:8080"
GALLERIES_ENDPOINT = f"{BASE_URL}/api/galleries"
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

def upload_gallery_image(token, image_path):
    """Upload an image to the gallery"""
    # Generate a random Paridhi year between 2020-2024
    paridhi_year = random.randint(2020, 2024)
    
    print(f"Uploading {os.path.basename(image_path)} (Paridhi {paridhi_year})...")
    
    try:
        with open(image_path, 'rb') as image_file:
            files = {'image': (os.path.basename(image_path), image_file, 'image/jpeg')}
            data = {'paridhiYear': str(paridhi_year)}
            
            response = requests.post(
                GALLERIES_ENDPOINT,
                headers={"Authorization": f"Bearer {token}"},
                files=files,
                data=data
            )
            
            if response.status_code == 201:
                print(f"✅ Successfully uploaded {os.path.basename(image_path)} to gallery")
                return True
            else:
                print(f"❌ Failed to upload to gallery: {response.status_code} - {response.text}")
                return False
    except Exception as e:
        print(f"❌ Error uploading to gallery: {str(e)}")
        return False

def collect_all_images(posters_dir):
    """Collect all image files from directory and subdirectories"""
    image_files = []
    
    for root, _, files in os.walk(posters_dir):
        for file in files:
            if file.lower().endswith(('.png', '.jpg', '.jpeg', '.gif')):
                image_files.append(os.path.join(root, file))
    
    return image_files

def main():
    parser = argparse.ArgumentParser(description="Upload images to gallery")
    parser.add_argument('--images-dir', default="event-posters", help="Directory containing images")
    parser.add_argument('--admins-file', default="json/admins.json", help="Path to admins JSON file")
    parser.add_argument('--max-images', type=int, default=None, help="Maximum number of images to upload (default: all)")
    args = parser.parse_args()
    
    posters_dir = args.images_dir
    admins_file = args.admins_file
    max_images = args.max_images
    
    # Check if posters directory exists
    if not os.path.exists(posters_dir):
        print(f"Error: Images directory {posters_dir} not found!")
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
        print("No valid admin tokens found. Cannot upload images.")
        return
    
    # Select a random admin to use
    admin = random.choice(admin_tokens)
    print(f"Using admin: {admin['name']} ({admin['email']})")
    
    # Collect all images from the directory
    all_images = collect_all_images(posters_dir)
    random.shuffle(all_images)  # Randomize images for variety
    
    if max_images and max_images < len(all_images):
        print(f"Limiting upload to {max_images} of {len(all_images)} available images")
        images_to_upload = all_images[:max_images]
    else:
        images_to_upload = all_images
    
    print(f"\nFound {len(images_to_upload)} images to upload to gallery:")
    for i, image in enumerate(images_to_upload, 1):
        print(f"  {i}. {os.path.basename(image)}")
    
    # Upload images to gallery
    print(f"\nUploading {len(images_to_upload)} images to gallery...")
    success_count = 0
    
    for index, image_path in enumerate(images_to_upload, 1):
        print(f"\n[{index}/{len(images_to_upload)}] Processing: {os.path.basename(image_path)}")
        
        if upload_gallery_image(admin['token'], image_path):
            success_count += 1
    
    # Print summary
    print("\n=== Gallery Upload Summary ===")
    print(f"Total images processed: {len(images_to_upload)}")
    print(f"Successfully uploaded to gallery: {success_count}")
    print(f"Failed uploads: {len(images_to_upload) - success_count}")

if __name__ == "__main__":
    main()