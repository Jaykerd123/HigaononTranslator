#!/usr/bin/env python3
"""
Setup script for Bisaya TTS Demo
This script helps install the required dependencies for the Facebook MMS TTS model.
"""

import subprocess
import sys
import os

def install_package(package):
    """Install a package using pip"""
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])
        print(f"✅ Successfully installed {package}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install {package}: {e}")
        return False

def check_package(package_name):
    """Check if a package is installed"""
    try:
        __import__(package_name)
        return True
    except ImportError:
        return False

def main():
    print("🔧 Setting up Bisaya TTS Environment")
    print("=" * 40)
    
    required_packages = [
        ("torch", "PyTorch"),
        ("transformers", "🤗 Transformers"),
        ("scipy", "SciPy")
    ]
    
    print("📦 Checking required packages...")
    
    missing_packages = []
    for package_name, display_name in required_packages:
        if check_package(package_name):
            print(f"✅ {display_name} is already installed")
        else:
            print(f"❌ {display_name} is missing")
            missing_packages.append(package_name)
    
    if not missing_packages:
        print("\n🎉 All required packages are already installed!")
        print("\n🚀 You can now run the demo:")
        print("   python bisaya_tts_demo.py")
        return True
    
    print(f"\n📥 Installing {len(missing_packages)} missing packages...")
    
    success_count = 0
    for package in missing_packages:
        print(f"\n📦 Installing {package}...")
        if install_package(package):
            success_count += 1
    
    print(f"\n📊 Installation Summary:")
    print(f"   ✅ Successfully installed: {success_count}/{len(missing_packages)} packages")
    print(f"   ❌ Failed: {len(missing_packages) - success_count} packages")
    
    if success_count == len(missing_packages):
        print("\n🎉 Setup completed successfully!")
        print("\n🚀 You can now run the demo:")
        print("   python bisaya_tts_demo.py")
        return True
    else:
        print("\n⚠️  Some packages failed to install.")
        print("\n💡 Manual installation instructions:")
        for package in missing_packages:
            print(f"   pip install {package}")
        return False

if __name__ == "__main__":
    main()
