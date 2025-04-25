# Paridhi Portal 2025 Setup Guide

This guide explains how to set up the Paridhi Portal 2025 system and provides an overview of the project structure and scripts.

## Project Overview

Paridhi Portal is a system for managing events, users, teams, and other aspects of the Paridhi technical fest. This setup toolkit automates the process of initializing and populating the portal with data.

## Directory Structure

- **json/**: Contains configuration files
  - `admins.json`: Admin user definitions
  - `users.json`: Regular user data
  - `events.json`: Event definitions
- **event-posters/**: Directory for event poster images
- **team-members/**: Contains team member information (CSV files)
- **logs/**: Generated log files from setup processes

## Setup Scripts

### Main Setup Script

The main script that orchestrates the entire setup process is `setup-paridhi-portal.py`. This script runs all other scripts in sequence.

#### Usage:

```bash
python setup-paridhi-portal.py [options]
```

#### Options:

- `--start-step INT`: Start from a specific step (1-9, default: 1)
- `--end-step INT`: End at a specific step (1-9, default: 9)
- `--dry-run`: Run all scripts in verification mode without making actual changes
- `--skip-steps "X,Y,Z"`: Comma-separated list of steps to skip (e.g., "3,5,7")

### Individual Scripts

The setup is broken down into the following scripts, which can also be run individually:

1. **register-admins.py**: Register admin accounts
   ```bash
   python register-admins.py --file json/admins.json [--dry-run]
   ```

2. **users-data-import.py**: Register user accounts and create profiles
   ```bash
   python users-data-import.py --file json/users.json [--dry-run]
   ```

3. **mrd-registration.py**: Register users for MRD and get GIDs
   ```bash
   python mrd-registration.py --file json/users.json --mrd-count 10 [--dry-run]
   ```

4. **create-events.py**: Create events using admin accounts
   ```bash
   python create-events.py --events-file json/events.json --admins-file json/admins.json [--dry-run]
   ```

5. **upload-event-posters.py**: Upload event posters
   ```bash
   python upload-event-posters.py --posters-dir event-posters --admins-file json/admins.json [--events-file json/events.json] [--dry-run]
   ```

6. **create-combos.py**: Create event combos
   ```bash
   python create-combos.py --admins-file json/admins.json [--dry-run]
   ```

7. **upload-combo-posters.py**: Upload combo posters
   ```bash
   python upload-combo-posters.py --posters-dir event-posters --admins-file json/admins.json [--dry-run]
   ```

8. **upload-gallery-images.py**: Upload gallery images
   ```bash
   python upload-gallery-images.py --images-dir event-posters --admins-file json/admins.json [--dry-run]
   ```

9. **create-megatronix-team.py**: Create Megatronix team
   ```bash
   python create-megatronix-team.py --csv-file "team-members/Contact Information.csv" --admins-file json/admins.json [--dry-run]
   ```

## Common Setup Scenarios

### Complete Setup

To run the complete setup process:

```bash
python setup-paridhi-portal.py
```

### Dry Run Mode

To validate all setup steps without making actual changes:

```bash
python setup-paridhi-portal.py --dry-run
```

### Running Only Specific Steps

To run only steps 3-5:

```bash
python setup-paridhi-portal.py --start-step 3 --end-step 5
```

### Skipping Certain Steps

To run the full process but skip steps 2 and 6:

```bash
python setup-paridhi-portal.py --skip-steps "2,6"
```

## Logs

All setup operations are logged to the `logs/` directory with timestamps. Log files follow the naming convention `setup_YYYYMMDD_HHMMSS.log`.

## Required vs Optional Steps

Some setup steps are marked as required, while others are optional:

- **Required steps**: If these fail, the setup process will stop
- **Optional steps**: If these fail, the setup process will continue to the next step

## Troubleshooting

If the setup fails, check the generated log file for detailed error messages. The most common issues include:
- Missing JSON configuration files
- Invalid JSON format
- Missing directories for images
- Authentication or permission issues with admin accounts

For specific issues with individual scripts, you can run them separately with the `--dry-run` option to diagnose problems.
