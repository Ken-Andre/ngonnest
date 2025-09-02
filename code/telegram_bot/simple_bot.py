#!/usr/bin/env python3
"""
Alternative Telegram bot implementation using direct API calls instead of Application.
This avoids the Updater issues while maintaining the same functionality.
"""
import os
import json
import urllib.request
import urllib.error
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class TelegramBot:
    """Simple Telegram bot using direct API calls."""

    def __init__(self, token):
        self.token = token
        self.base_url = f"https://api.telegram.org/bot{token}"
        self.last_update_id = 0

    def api_call(self, method, data=None):
        """Make an API call to Telegram."""
        url = f"{self.base_url}/{method}"

        if data:
            req_data = urllib.parse.urlencode(data).encode('utf-8')
        else:
            req_data = None

        req = urllib.request.Request(url, req_data)

        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                result = json.loads(response.read().decode('utf-8'))
                if result.get('ok'):
                    return result.get('result')
                else:
                    print(f"API Error: {result.get('description')}")
                    return None
        except urllib.error.URLError as e:
            print(f"Network Error: {e}")
            return None

    def send_message(self, chat_id, text):
        """Send a message to a chat."""
        return self.api_call("sendMessage", {
            "chat_id": chat_id,
            "text": text,
            "parse_mode": "Markdown"
        })

    def send_message_with_keyboard(self, chat_id, text, keyboard=None):
        """Send a message with inline keyboard."""
        data = {
            "chat_id": chat_id,
            "text": text,
            "parse_mode": "Markdown"
        }
        if keyboard:
            data["reply_markup"] = json.dumps(keyboard)

        return self.api_call("sendMessage", data)

    def handle_command(self, message):
        """Handle a bot command."""
        text = message.get("text", "")
        chat_id = message["chat"]["id"]

        if text.startswith("/start"):
            self.send_menu(chat_id)

        elif text.startswith("/help"):
            response = "📋 Commandes NgonNest Bot :\n\n/start - Démarrer le bot avec le menu principal\n/help - Afficher cette aide"
            keyboard = {
                "inline_keyboard": [
                    [
                        {"text": "🏠 Menu principal", "callback_data": "start"}
                    ]
                ]
            }
            self.send_message_with_keyboard(chat_id, response, keyboard)

        else:
            response = "❓ Commande non reconnue. Utilisez /help ou cliquez sur les boutons ci-dessous:"
            keyboard = {
                "inline_keyboard": [
                    [
                        {"text": "📋 Liste commandes", "callback_data": "help"}
                    ],
                    [
                        {"text": "🏠 Menu principal", "callback_data": "start"}
                    ]
                ]
            }
            self.send_message_with_keyboard(chat_id, response, keyboard)

    def send_menu(self, chat_id):
        """Send the main menu with buttons."""
        response = "Bienvenue sur NgonNest Bot! 🚀"
        keyboard = {
            "inline_keyboard": [
                [
                    {"text": "📋 Commandes", "callback_data": "help"},
                    {"text": "🚀 Quick Start", "callback_data": "quickstart"}
                ],
                [
                    {"text": "❓ FAQ", "callback_data": "faq"}
                ]
            ]
        }
        self.send_message_with_keyboard(chat_id, response, keyboard)

    def handle_callback_query(self, callback_query):
        """Handle button callbacks."""
        callback_data = callback_query.get("data")
        chat_id = callback_query["message"]["chat"]["id"]

        if callback_data == "start":
            self.send_menu(chat_id)
        elif callback_data == "help":
            response = "📋 Commandes NgonNest Bot :\n\n/start - Démarrer le bot\n/help - Afficher cette aide"
            keyboard = {
                "inline_keyboard": [
                    [
                        {"text": "🏠 Menu principal", "callback_data": "start"}
                    ]
                ]
            }
            self.send_message_with_keyboard(chat_id, response, keyboard)
        elif callback_data == "quickstart":
            response = "🚀 Quick Start - Commencez par explorer les fonctionnalités du bot!"
            keyboard = {
                "inline_keyboard": [
                    [
                        {"text": "📋 Toutes les commandes", "callback_data": "help"}
                    ],
                    [
                        {"text": "🏠 Retour au menu", "callback_data": "start"}
                    ]
                ]
            }
            self.send_message_with_keyboard(chat_id, response, keyboard)
        elif callback_data == "faq":
            response = "❓ FAQ NgonNest Bot :\n\nQ: Comment utiliser le bot?\nR: Cliquez sur les boutons ci-dessous ou tapez des commandes!"
            keyboard = {
                "inline_keyboard": [
                    [
                        {"text": "🚀 Guide rapide", "callback_data": "quickstart"}
                    ],
                    [
                        {"text": "🏠 Menu principal", "callback_data": "start"}
                    ]
                ]
            }
            self.send_message_with_keyboard(chat_id, response, keyboard)

        # Acknowledge the callback query
        self.api_call("answerCallbackQuery", {"callback_query_id": callback_query["id"]})

    def process_updates(self):
        """Process incoming updates."""
        updates = self.api_call("getUpdates", {
            "offset": self.last_update_id + 1,
            "timeout": 5  # Reduced timeout for better responsiveness
        })

        if updates:
            for update in updates:
                update_id = update.get("update_id")
                if update_id:
                    self.last_update_id = max(self.last_update_id, update_id)

                # Handle regular messages
                message = update.get("message")
                if message:
                    self.handle_command(message)

                # Handle callback queries from inline keyboards
                callback_query = update.get("callback_query")
                if callback_query:
                    self.handle_callback_query(callback_query)

    def run(self):
        """Run the bot polling loop."""
        print("🚀 Telegram Bot started! Press Ctrl+C to stop.")
        print("📡 Bot is polling for messages...")

        while True:
            try:
                self.process_updates()
            except KeyboardInterrupt:
                print("\n👋 Bot stopped by user.")
                break
            except Exception as e:
                # Improve error handling - don't show timeout errors
                if "timed out" not in str(e).lower():
                    print(f"Error: {e}")

def main():
    """Main function."""
    # Get token from environment
    token = os.getenv("TELEGRAM_TOKEN")
    if not token:
        print("❌ TELEGRAM_TOKEN environment variable not set!")
        return

    # Create and run bot
    bot = TelegramBot(token)
    bot.run()

if __name__ == "__main__":
    import urllib.parse
    main()
