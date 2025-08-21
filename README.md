# Paridhi Portal 2025 – Admin & Event Management System

Welcome to the **Paridhi Portal 2025** repository! This project is a comprehensive, cross-platform event management system designed for the Paridhi technical fest. It provides robust tools for managing users, admins, events, teams, media assets, and more, with a modern Flutter frontend and a flexible backend.

---

## 🚀 Project Overview

Paridhi Portal is built to automate and streamline the setup and management of a large-scale technical festival. It supports:

- **Admin and user registration**
- **Event creation and management**
- **Team formation and management**
- **Poster and gallery image uploads**
- **Combo event management**
- **Detailed logging and troubleshooting**

The project leverages **Flutter** for a beautiful, responsive UI across web, desktop (Windows, Linux, macOS), and mobile platforms. The backend is containerized for easy deployment and scalability.

---

## 🏗️ Directory Structure

- **lib/**: Main Flutter application code (models, providers, screens, services, widgets, utils)
- **assets/**: Images, animations, and other static assets
- **backend/**: Backend configuration and Docker setup
- **scripts/**: Python setup scripts for automating portal initialization
  - `json/`: Configuration files (admins, users, events)
  - `event-posters/`: Event poster images
  - `team-members/`: Team member CSVs
  - Individual Python scripts for each setup step
- **test/**: Flutter/Dart unit and widget tests
- **web/**: Web build assets (HTML, manifest, icons)
- **android/**, **ios/**, **linux/**, **macos/**, **windows/**: Platform-specific build and runner files
- **.dart_tool/**, **build/**: Build artifacts and tool configs
- **.vscode/**: Editor configuration for VS Code

---

## 💡 Features & Complexity

This project demonstrates advanced engineering and architectural practices:

- **Multi-platform support**: Runs seamlessly on web, desktop, and mobile
- **Automated setup toolkit**: Modular Python scripts for stepwise portal initialization
- **Robust error handling**: Required/optional steps, detailed logs, dry-run mode for safe testing
- **Asset management**: Bulk upload and validation of images and posters
- **Scalable backend**: Dockerized for easy deployment and integration
- **Extensible codebase**: Well-organized Flutter modules for rapid feature addition
- **Modern build system**: CMake integration for desktop, Gradle/Xcode for mobile

The complexity lies in orchestrating multiple setup steps, handling large datasets, and ensuring reliability across platforms. The modular design allows for easy maintenance and future expansion.

---

## 🛠️ Setup & Usage

### 1. **Clone the Repository**

```sh
git clone https://github.com/<your-org>/Paridhi_Admin.git
cd Paridhi_Admin
```
### 2. **Install Dependencies**

Flutter: 
```sh 
Install Flutter
```
Python 3.x: 
```sh 
For setup scripts
```
Docker: 
```sh
For backend (optional)
```

### 3. **Run the Setup Scripts**
Automate portal initialization using the main script:

```sh
cd scripts
python setup-paridhi-portal.py
```
### 4. **Run the Flutter App**
```sh
flutter pub get
flutter run
```
