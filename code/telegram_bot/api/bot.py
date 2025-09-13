import os
import json
import requests
import logging
from typing import Optional, Dict, Any

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

