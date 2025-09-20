#!/usr/bin/env python3
"""
SurakshaPay Setup Script
Automates the setup process for the SurakshaPay application.
"""

import os
import sys
import subprocess
import platform
import json
from pathlib import Path

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed: {e.stderr}")
        return False

def check_flutter():
    """Check if Flutter is installed"""
    print("🔍 Checking Flutter installation...")
    try:
        result = subprocess.run(["flutter", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ Flutter is installed")
            return True
        else:
            print("❌ Flutter is not installed")
            return False
    except FileNotFoundError:
        print("❌ Flutter is not installed")
        return False

def check_python():
    """Check if Python is installed"""
    print("🔍 Checking Python installation...")
    if sys.version_info >= (3, 8):
        print(f"✅ Python {sys.version.split()[0]} is installed")
        return True
    else:
        print(f"❌ Python 3.8+ is required, found {sys.version.split()[0]}")
        return False

def install_flutter_dependencies():
    """Install Flutter dependencies"""
    if not check_flutter():
        print("Please install Flutter first: https://flutter.dev/docs/get-started/install")
        return False
    
    return run_command("flutter pub get", "Installing Flutter dependencies")

def install_python_dependencies():
    """Install Python dependencies"""
    if not check_python():
        print("Please install Python 3.8+ first")
        return False
    
    return run_command("pip install -r requirements.txt", "Installing Python dependencies")

def setup_database():
    """Setup database schema"""
    print("🗄️ Setting up database...")
    print("Please run the SQL commands from database_schema.sql in your Supabase dashboard")
    print("1. Go to your Supabase project dashboard")
    print("2. Navigate to SQL Editor")
    print("3. Copy and paste the contents of database_schema.sql")
    print("4. Execute the SQL commands")
    return True

def create_env_file():
    """Create environment configuration file"""
    print("📝 Creating environment configuration...")
    
    env_content = """# SurakshaPay Environment Configuration

# Supabase Configuration
SUPABASE_URL=https://ogrebetlhwzfywuvgijl.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ncmViZXRsaHd6Znl3dXZnaWpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyODQ0MTYsImV4cCI6MjA3Mzg2MDQxNn0.7ALejILrqoUH1CWbVN8GGBM2nE8PSsmdgBKEefdnYvw
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ncmViZXRsaHd6Znl3dXZnaWpsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODI4NDQxNiwiZXhwIjoyMDczODYwNDE2fQ.cQpCyx1skgzjRygANzutYLQwX2l14yErdcV0DuCLy40

# Fraud Detection Service
FRAUD_DETECTION_URL=http://localhost:8000
NLP_PROCESSING_URL=http://localhost:8000/process-voice

# App Configuration
DEFAULT_LANGUAGE=hi-IN
DAILY_TRANSACTION_LIMIT=50000
MAX_SINGLE_TRANSACTION=50000
"""
    
    with open('.env', 'w') as f:
        f.write(env_content)
    
    print("✅ Environment file created (.env)")
    return True

def create_run_scripts():
    """Create run scripts for different platforms"""
    print("📜 Creating run scripts...")
    
    # Windows batch file
    windows_script = """@echo off
echo Starting SurakshaPay Services...

echo Starting Fraud Detection Service...
start "Fraud Detection" python fraud_detection_service.py

timeout /t 3 /nobreak >nul

echo Starting Streamlit Dashboard...
start "Dashboard" streamlit run streamlit_dashboard.py

echo Starting Flutter App...
flutter run

pause
"""
    
    with open('run_windows.bat', 'w') as f:
        f.write(windows_script)
    
    # Unix shell script
    unix_script = """#!/bin/bash
echo "Starting SurakshaPay Services..."

echo "Starting Fraud Detection Service..."
python3 fraud_detection_service.py &
FRAUD_PID=$!

sleep 3

echo "Starting Streamlit Dashboard..."
streamlit run streamlit_dashboard.py &
DASHBOARD_PID=$!

echo "Starting Flutter App..."
flutter run

# Cleanup on exit
trap "kill $FRAUD_PID $DASHBOARD_PID" EXIT
"""
    
    with open('run_unix.sh', 'w') as f:
        f.write(unix_script)
    
    # Make Unix script executable
    if platform.system() != "Windows":
        os.chmod('run_unix.sh', 0o755)
    
    print("✅ Run scripts created")
    return True

def main():
    """Main setup function"""
    print("🛡️ SurakshaPay Setup Script")
    print("=" * 50)
    
    # Check prerequisites
    print("\n📋 Checking prerequisites...")
    flutter_ok = check_flutter()
    python_ok = check_python()
    
    if not flutter_ok or not python_ok:
        print("\n❌ Prerequisites not met. Please install the required software.")
        return False
    
    # Install dependencies
    print("\n📦 Installing dependencies...")
    flutter_deps_ok = install_flutter_dependencies()
    python_deps_ok = install_python_dependencies()
    
    if not flutter_deps_ok or not python_deps_ok:
        print("\n❌ Dependency installation failed.")
        return False
    
    # Setup database
    print("\n🗄️ Database setup...")
    setup_database()
    
    # Create configuration files
    print("\n⚙️ Creating configuration files...")
    create_env_file()
    create_run_scripts()
    
    # Final instructions
    print("\n🎉 Setup completed successfully!")
    print("\n📋 Next steps:")
    print("1. Set up your Supabase database using database_schema.sql")
    print("2. Update the Supabase configuration in lib/config/supabase_config.dart if needed")
    print("3. Run the application:")
    
    if platform.system() == "Windows":
        print("   - Double-click run_windows.bat")
    else:
        print("   - Run: ./run_unix.sh")
    
    print("\n4. Or run services individually:")
    print("   - Fraud Detection: python fraud_detection_service.py")
    print("   - Dashboard: streamlit run streamlit_dashboard.py")
    print("   - Flutter App: flutter run")
    
    print("\n📚 For more information, see README.md")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

