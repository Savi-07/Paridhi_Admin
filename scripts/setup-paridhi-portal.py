import subprocess
import argparse
import sys
import os
import time
from datetime import datetime

def print_header(message):
    """Print a formatted header message"""
    line = "=" * 80
    print(f"\n{line}")
    print(f"{message.center(80)}")
    print(f"{line}\n")

def run_script(script_name, args=None, required=True):
    """Run a Python script and return True if successful, False otherwise"""
    if args is None:
        args = []
    
    command = [sys.executable, script_name] + args
    
    print_header(f"RUNNING: {script_name}")
    print(f"Command: {' '.join(command)}")
    
    try:
        # Run the script and capture output
        start_time = time.time()
        result = subprocess.run(command, check=True)
        elapsed_time = time.time() - start_time
        
        print(f"\nSUCCESS: {script_name} completed in {elapsed_time:.2f} seconds")
        return True
    except subprocess.CalledProcessError as e:
        print(f"\nERROR: {script_name} failed with exit code {e.returncode}")
        if required:
            print("This script is required for the setup process. Stopping.")
            return False
        else:
            print("This script is optional. Continuing with the setup process.")
            return True
    except Exception as e:
        print(f"\nEXCEPTION: {script_name} raised an exception: {str(e)}")
        if required:
            print("This script is required for the setup process. Stopping.")
            return False
        else:
            print("This script is optional. Continuing with the setup process.")
            return True

def main():
    parser = argparse.ArgumentParser(description="Setup Paridhi Portal with all necessary data")
    parser.add_argument('--start-step', type=int, default=1, help="Start from a specific step (1-9)")
    parser.add_argument('--end-step', type=int, default=9, help="End at a specific step (1-9)")
    parser.add_argument('--dry-run', action='store_true', help="Run all scripts in dry-run mode (no changes)")
    parser.add_argument('--skip-steps', type=str, help="Comma-separated list of steps to skip (e.g., '3,5,7')")
    args = parser.parse_args()
    
    start_step = args.start_step
    end_step = args.end_step
    dry_run = args.dry_run
    skip_steps = []
    
    if args.skip_steps:
        try:
            skip_steps = [int(step) for step in args.skip_steps.split(',')]
        except ValueError:
            print("Error: --skip-steps must be a comma-separated list of integers")
            return
    
    # Define the scripts in order
    scripts = [
        {
            "id": 1,
            "name": "register-admins.py",
            "description": "Register admin accounts",
            "required": True,
            "args": ["--file", "json/admins.json"]
        },
        {
            "id": 2,
            "name": "users-data-import.py",
            "description": "Register user accounts and create profiles",
            "required": True,
            "args": ["--file", "json/users.json"]
        },
        {
            "id": 3,
            "name": "mrd-registration.py",
            "description": "Register users for MRD and get GIDs",
            "required": False,
            "args": ["--file", "json/users.json", "--mrd-count", "10"]
        },
        {
            "id": 4,
            "name": "create-events.py",
            "description": "Create events using admin accounts",
            "required": True,
            "args": ["--events-file", "json/events.json", "--admins-file", "json/admins.json"]
        },
        {
            "id": 5,
            "name": "upload-event-posters.py",
            "description": "Upload event posters",
            "required": False,
            "args": ["--posters-dir", "event-posters", "--admins-file", "json/admins.json"]
        },
        {
            "id": 6,
            "name": "create-combos.py",
            "description": "Create event combos",
            "required": False,
            "args": ["--admins-file", "json/admins.json"]
        },
        {
            "id": 7,
            "name": "upload-combo-posters.py",
            "description": "Upload combo posters",
            "required": False,
            "args": ["--posters-dir", "event-posters", "--admins-file", "json/admins.json"]
        },
        {
            "id": 8,
            "name": "upload-gallery-images.py",
            "description": "Upload gallery images",
            "required": False,
            "args": ["--images-dir", "event-posters", "--admins-file", "json/admins.json"]
        },
        {
            "id": 9,
            "name": "create-megatronix-team.py",
            "description": "Create Megatronix team",
            "required": False,
            "args": ["--csv-file", "team-members/Contact Information.csv", "--admins-file", "json/admins.json"]
        }
    ]
    
    # Create log directory if it doesn't exist
    log_dir = "logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    # Setup log file
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(log_dir, f"setup_{timestamp}.log")
    
    # Redirect stdout and stderr to the log file
    original_stdout = sys.stdout
    original_stderr = sys.stderr
    
    # Print setup information
    start_time = time.time()
    print_header("PARIDHI PORTAL 2025 SETUP")
    print(f"Starting setup at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Dry run mode: {'Enabled' if dry_run else 'Disabled'}")
    print(f"Starting at step {start_step} and ending at step {end_step}")
    print(f"Skipping steps: {skip_steps if skip_steps else 'None'}")
    print(f"Log file: {log_file}")
    
    # Open log file
    with open(log_file, 'w') as log:
        # Redirect stdout and stderr to the log file
        sys.stdout = log
        sys.stderr = log
        
        # Print setup information to log
        print_header("PARIDHI PORTAL 2025 SETUP")
        print(f"Starting setup at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Dry run mode: {'Enabled' if dry_run else 'Disabled'}")
        print(f"Starting at step {start_step} and ending at step {end_step}")
        print(f"Skipping steps: {skip_steps if skip_steps else 'None'}")
        
        # Run each script in order
        successful_steps = 0
        failed_steps = 0
        skipped_steps = 0
        
        for script in scripts:
            script_id = script["id"]
            script_name = script["name"]
            script_desc = script["description"]
            script_required = script["required"]
            script_args = script["args"].copy()
            
            # Check if this step should be run
            if script_id < start_step or script_id > end_step or script_id in skip_steps:
                print_header(f"SKIPPING STEP {script_id}: {script_desc}")
                skipped_steps += 1
                continue
            
            # Add dry-run flag if needed
            if dry_run:
                script_args.append("--dry-run")
            
            # Run the script
            success = run_script(script_name, script_args, script_required)
            
            if success:
                successful_steps += 1
            else:
                failed_steps += 1
                if script_required:
                    print_header(f"STOPPING SETUP: Required script {script_name} failed")
                    break
    
    # Restore stdout and stderr
    sys.stdout = original_stdout
    sys.stderr = original_stderr
    
    # Print summary
    elapsed_time = time.time() - start_time
    print_header("SETUP SUMMARY")
    print(f"Total elapsed time: {elapsed_time:.2f} seconds")
    print(f"Steps successful: {successful_steps}")
    print(f"Steps failed: {failed_steps}")
    print(f"Steps skipped: {skipped_steps}")
    print(f"Log file: {log_file}")
    
    if failed_steps == 0:
        print("\nSetup completed successfully!")
    else:
        print(f"\nSetup completed with {failed_steps} failed steps. Check the log file for details.")

if __name__ == "__main__":
    main()