#!/usr/bin/env python3
"""
Simple test to initialize the Telegram bot without polling.
This will help isolate the AttributeError issue.
"""

import os
from dotenv import load_dotenv
from telegram.ext import Application

# Load environment variables
load_dotenv()

def test_bot_initialization():
    """Test if the bot can be initialized without polling."""
    try:
        # Get token
        token = os.getenv("TELEGRAM_TOKEN")
        if not token:
            print("❌ No TELEGRAM_TOKEN found!")
            return False

        print("🔧 Attempting to create Application...")

        # Try a simpler test first - just build the application
        app = Application.builder().token(token).build()
        print("✅ Application created successfully!")

        # Just test that the app has the right attributes, shouldn't call get_me()
        if hasattr(app, 'bot') and hasattr(app, 'run_polling'):
            print("✅ Bot attributes verified!")
            return True
        else:
            print("❌ Missing expected attributes!")
            return False

    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("🔍 Testing Telegram Bot Initialization...")
    print("=" * 50)
    success = test_bot_initialization()
    print("=" * 50)
    if success:
        print("🎉 Initialization test passed!")
    else:
        print("⚠️ Initialization test failed!")
