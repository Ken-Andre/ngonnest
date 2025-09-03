#!/usr/bin/env python3
"""
Simple test script to verify the Telegram bot setup and syntax.
This doesn't run the actual bot but verifies the code can be imported and set up correctly.
"""

import os
import sys
from dotenv import load_dotenv

def test_imports():
    """Test if all required modules can be imported."""
    try:
        import logging
        from telegram.ext import Application, CommandHandler, ContextTypes
        from telegram import Update
        print("✅ All Telegram imports successful")
        return True
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False

def test_env_config():
    """Test if environment configuration works."""
    try:
        # Load environment variables
        load_dotenv()

        # Check if token exists
        token = os.getenv("TELEGRAM_TOKEN")
        if token:
            print(f"✅ Token loaded successfully: {token[:20]}...")
            return True
        else:
            print("❌ No TELEGRAM_TOKEN found in environment")
            return False
    except Exception as e:
        print(f"❌ Environment configuration error: {e}")
        return False

def test_syntax():
    """Test if the main script has correct syntax."""
    try:
        # Try to parse the main.py file
        with open("main.py", "r", encoding="utf-8") as f:
            code = f.read()

        # Try to compile the code
        compile(code, "main.py", 'exec')
        print("✅ main.py syntax is valid")
        return True
    except Exception as e:
        print(f"❌ Syntax error in main.py: {e}")
        return False

def main():
    """Run all tests."""
    print("🔍 Running Telegram Bot Setup Tests...")
    print("=" * 50)

    tests = [
        ("Import Tests", test_imports),
        ("Environment Configuration", test_env_config),
        ("Syntax Check", test_syntax),
    ]

    passed = 0
    total = len(tests)

    for test_name, test_func in tests:
        print(f"\n📋 {test_name}:")
        if test_func():
            passed += 1

    print("\n" + "=" * 50)
    print(f"📊 Test Results: {passed}/{total} passed")

    if passed == total:
        print("🎉 All tests passed! Bot setup appears to be correct.")
        return 0
    else:
        print("⚠️  Some tests failed. Please review the errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
