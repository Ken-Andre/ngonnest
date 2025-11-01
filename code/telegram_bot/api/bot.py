import os
import json
import requests
import logging
import time
from typing import Optional, Dict, Any
from dotenv import load_dotenv
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GitHubIssueManager:
    def __init__(self):
        self.github_token = os.getenv("GITHUB_TOKEN")
        self.github_repo = os.getenv("GITHUB_REPO", "Ken-Andre/ngonnest")
        self.base_url = "https://api.github.com"

    def create_issue(self, title: str, body: str, labels: list[str] = None) -> Optional[Dict[str, Any]]:
        if not self.github_token:
            logger.error("GitHub token not available")
            return None
        headers = {
            "Authorization": f"token {self.github_token}",
            "Accept": "application/vnd.github.v3+json",
        }
        data = {"title": title, "body": body, "labels": labels or ["bug"]}
        url = f"{self.base_url}/repos/{self.github_repo}/issues"
        try:
            response = requests.post(url, headers=headers, json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to create GitHub issue: {e}")
            return None

github_manager = GitHubIssueManager()

def api_call(method: str, data: Optional[Dict[str, Any]] = None):
    token = os.getenv("TELEGRAM_TOKEN")
    if not token:
        logger.error("TELEGRAM_TOKEN not set")
        return None
    base_url = f"https://api.telegram.org/bot{token}"
    url = f"{base_url}/{method}"
    try:
        response = requests.post(url, json=data)
        result = response.json()
        if result.get("ok"):
            return result.get("result")
        logger.error(f"API Error: {result.get('description')}")
        return None
    except Exception as e:
        logger.error(f"Network Error: {e}")
        return None

def send_message(chat_id: int, text: str, parse_mode: str = "Markdown"):
    return api_call("sendMessage", {"chat_id": chat_id, "text": text, "parse_mode": parse_mode})

def handler(event, context):
    if event['httpMethod'] == 'GET':
        return {"statusCode": 200, "body": json.dumps({"status": "OK"})}

def handle_update(update: Dict[str, Any]):
    message = update.get("message")
    if not message:
        return

    text = message.get("text", "")
    chat_id = message["chat"]["id"]

    # Pour l'instant, on ne gère que les commandes simples sans état
    if text.startswith("/start"):
        send_message(
            chat_id,
            "🏠 *Bienvenue sur NgonNest Bot !*\n\n"
            "Je peux vous aider avec :\n"
            "• `/help` - Voir toutes les commandes\n"
            "• `/status` - État du bot",
        )
    elif text.startswith("/help"):
        send_message(
            chat_id,
            "🤖 *Commandes NgonNest Bot*\n\n"
            "• `/help` - Afficher cette aide\n"
            "• `/status` - État du bot et GitHub\n\n"
            "Les commandes `/feedback` et `/bug` sont en cours de développement pour l'environnement serverless.",
        )
    elif text.startswith("/status"):
        github_ok = github_manager.github_token is not None
        status = "🟢 En ligne"
        github_status = "✅ Connecté" if github_ok else "❌ Token manquant"
        send_message(
            chat_id,
            f"📊 *État du Bot NgonNest*\n\n"
            f"🤖 Bot: {status}\n"
            f"🐙 GitHub: {github_status}\n"
            f"📝 Repo: `{github_manager.github_repo}`",
        )
    else:
        send_message(
            chat_id,
            "🤔 Je ne comprends pas ce message.\n\n"
            "Utilisez `/help` pour voir les commandes disponibles.",
        )

def handler(request, context):
    """Vercel serverless function handler."""
    try:
        if request.method != 'POST':
            return {"statusCode": 405, "body": "Method Not Allowed"}
        
        update = json.loads(request.body)
        handle_update(update)
        
        return {"statusCode": 200, "body": "ok"}
    except Exception as e:
        logger.error(f"Error handling request: {e}")
        return {"statusCode": 500, "body": "Internal Server Error"}

def polling_loop():
    """
    Polling loop with error handling, exponential backoff, and rate limiting
    according to Telegram's guidelines.
    """
    token = os.getenv("TELEGRAM_TOKEN")
    if not token:
        logger.error("TELEGRAM_TOKEN not set. Cannot start polling.")
        return
    
    offset = 0
    error_count = 0
    max_errors = 10  # Maximum consecutive errors before exiting
    
    logger.info("Starting polling loop")
    
    while True:
        try:
            # According to Telegram's guidelines, we should not make more than 
            # one request per second, and getUpdates timeout shouldbe between 1-25 seconds
            updates = api_call("getUpdates", {
                "offset": offset, 
                "timeout": 30,  # Long polling
                "allowed_updates": ["message"]  # Only receive message updates
            })
            
            # Reset error count on successful requesterror_count = 0
            
            if updates:
                for update in updates:
                    try:
                        handle_update(update)
                        offset = update["update_id"] + 1
                    except Exception as e:
                        logger.error(f"Error handling update {update.get('update_id')}: {e}")
                        # Continue processing other updates even if one fails
                        offset = update["update_id"] + 1  # Move to next update
            
            # Small delay to prevent excessive requests
            time.sleep(0.1)
            
        except KeyboardInterrupt:
            logger.info("Polling loop interrupted by user")
            break
        exceptException as e:
            error_count += 1
            logger.error(f"Error in polling loop: {e}")
            
            # Implement exponential backoff
            if error_count <= max_errors:
                # Exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s, 64s, max 64s
                backoff_time = min(64, 2 ** (error_count - 1))
                logger.warning(f"Backing off for {backoff_time} seconds due to {error_count} consecutive errors")
                time.sleep(backoff_time)
            else:
                logger.error(f"Too many consecutive errors ({error_count}). Exiting polling loop.")
                break
    
    logger.info("Polling loop stopped")

if __name__ == "__main__":
    polling_loop()