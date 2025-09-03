#!/usr/bin/env python3
"""
NgonNest Telegram Bot - Main implementation using direct API calls.
This avoids the Updater issues while maintaining full functionality.
"""
import os
import json
import urllib.request
import urllib.error
import urllib.parse
import requests
import logging
from typing import Optional, Dict, Any
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

class GitHubIssueManager:
    def __init__(self):
        self.github_token = os.getenv("GITHUB_TOKEN")
        self.github_repo = os.getenv("GITHUB_REPO", "Ken-Andre/ngonnest")
        self.base_url = "https://api.github.com"

        if not self.github_token:
            logger.warning("GITHUB_TOKEN not set - GitHub integration will be disabled")

    def create_issue(self, title: str, body: str, labels: list[str] = None) -> Optional[Dict[str, Any]]:
        """Create a GitHub issue"""
        if not self.github_token:
            logger.error("GitHub token not available")
            return None

        headers = {
            "Authorization": f"token {self.github_token}",
            "Accept": "application/vnd.github.v3+json"
        }

        data = {
            "title": title,
            "body": body,
            "labels": labels or ["bug"]
        }

        url = f"{self.base_url}/repos/{self.github_repo}/issues"

        try:
            response = requests.post(url, headers=headers, json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to create GitHub issue: {e}")
            return None

github_manager = GitHubIssueManager()


class TelegramBot:
    """NgonNest Telegram bot using direct API calls."""

    def __init__(self, token: str):
        self.token = token
        self.base_url = f"https://api.telegram.org/bot{token}"
        self.last_update_id = 0
        self.user_states: Dict[int, str] = {}

    def api_call(self, method: str, data: Optional[Dict[str, Any]] = None):
        """Make an API call to Telegram."""
        url = f"{self.base_url}/{method}"
        req_data = urllib.parse.urlencode(data).encode("utf-8") if data else None
        req = urllib.request.Request(url, req_data)
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                result = json.loads(response.read().decode("utf-8"))
                if result.get("ok"):
                    return result.get("result")
                logger.error(f"API Error: {result.get('description')}")
                return None
        except urllib.error.URLError as e:
            logger.error(f"Network Error: {e}")
            return None

    def send_message(self, chat_id: int, text: str, parse_mode: str = "Markdown"):
        return self.api_call(
            "sendMessage",
            {"chat_id": chat_id, "text": text, "parse_mode": parse_mode},
        )

    def handle_command(self, message: Dict[str, Any]):
        text = message.get("text", "") or ""
        chat_id = message["chat"]["id"]
        user_id = message["from"]["id"]

        if text.startswith("/start"):
            self.send_message(
                chat_id,
                "🏠 *Bienvenue sur NgonNest Bot !*\n\n"
                "Je peux vous aider avec :\n"
                "• `/feedback` - Partager vos suggestions\n"
                "• `/bug` - Signaler un problème\n"
                "• `/help` - Voir toutes les commandes\n\n"
                "Utilisez ces commandes pour nous aider à améliorer l'application !",
            )
        elif text.startswith("/help"):
            self.send_message(
                chat_id,
                "🤖 *Commandes NgonNest Bot*\n\n"
                "*Feedback & Support :*\n"
                "• `/feedback` - Envoyer une suggestion d'amélioration\n"
                "• `/bug` - Signaler un bug ou problème\n\n"
                "*Informations :*\n"
                "• `/help` - Afficher cette aide\n"
                "• `/status` - État du bot et GitHub\n\n"
                "*Astuce :* Vous pouvez annuler une commande en cours avec `/cancel`",
            )
        elif text.startswith("/status"):
            github_ok = github_manager.github_token is not None
            status = "🟢 En ligne" if github_ok else "🟡 GitHub désactivé"
            github_status = "✅ Connecté" if github_ok else "❌ Token manquant"
            self.send_message(
                chat_id,
                f"📊 *État du Bot NgonNest*\n\n"
                f"🤖 Bot: {status}\n"
                f"🐙 GitHub: {github_status}\n"
                f"📝 Repo: `{github_manager.github_repo}`\n\n"
                f"*Integration active:* {'Oui' if github_ok else 'Non (nécessite GITHUB_TOKEN)'}",
            )
        elif text.startswith("/cancel"):
            if user_id in self.user_states:
                operation = self.user_states[user_id]
                del self.user_states[user_id]
                self.send_message(
                    chat_id,
                    f"❌ Opération *{operation}* annulée.\n\n"
                    "Vous pouvez recommencer avec `/feedback` ou `/bug`.",
                )
            else:
                self.send_message(
                    chat_id,
                    "ℹ️ Aucune opération en cours.\n\n"
                    "Utilisez `/feedback` ou `/bug` pour commencer.",
                )
        elif text.startswith("/feedback"):
            self.user_states[user_id] = "feedback"
            self.send_message(
                chat_id,
                "💡 *Envoyer un feedback*\n\n"
                "Pouvez-vous me décrire votre suggestion ou idée d'amélioration ?\n\n"
                "📝 *Exemple :* \"Il serait pratique d'avoir une fonction de recherche dans l'inventaire.\"\n\n"
                "_Tapez votre message ou utilisez /cancel pour annuler._",
            )
        elif text.startswith("/bug"):
            self.user_states[user_id] = "bug"
            self.send_message(
                chat_id,
                "🐛 *Signaler un bug*\n\n"
                "Pouvez-vous me décrire le problème rencontré ?\n\n"
                "📝 *Détails utiles :*\n"
                "• Ce qui s'est passé\n"
                "• Quand cela arrive\n"
                "• Sur quel appareil\n"
                "• Étapes pour reproduire\n\n"
                "_Tapez votre description ou utilisez /cancel pour annuler._",
            )
        else:
            self.send_message(
                chat_id,
                "❓ *Commande inconnue*\n\n"
                "Utilisez `/help` pour voir toutes les commandes disponibles.",
            )

    def handle_message(self, message: Dict[str, Any]):
        chat_id = message["chat"]["id"]
        user_id = message["from"]["id"]
        user = message["from"]
        text = message.get("text", "") or ""

        if user_id not in self.user_states:
            self.send_message(
                chat_id,
                "🤔 Je ne comprends pas ce message.\n\n"
                "Utilisez une commande comme `/feedback` ou `/bug`, "
                "ou consultez l'aide avec `/help`.",
            )
            return

        state = self.user_states[user_id]
        if state == "feedback":
            self.process_feedback(chat_id, user, text)
        elif state == "bug":
            self.process_bug_report(chat_id, user, text)

        if user_id in self.user_states:
            del self.user_states[user_id]

    def process_feedback(self, chat_id: int, user: Dict[str, Any], message: str):
        user_id = user["id"]
        user_name = user.get("username") or user.get("first_name", f"User_{user_id}")

        title = f"[FEEDBACK] Suggestion de {user_name}"
        body = (
            f"📝 **Feedback de l'utilisateur @{user_name}**\n\n"
            f"**Message :**\n{message}\n\n"
            f"**Informations :**\n- ID utilisateur: {user_id}"
        )

        issue = github_manager.create_issue(
            title=title,
            body=body,
            labels=["feedback", "user-request", "enhancement"],
        )

        if issue:
            self.send_message(
                chat_id,
                "✅ *Feedback envoyé avec succès !*\n\n"
                f"📋 **Numéro de suivi :** #{issue['number']}\n"
                f"🔗 **Lien :** {issue['html_url']}\n\n"
                "Merci pour votre contribution ! Nous étudierons votre suggestion.",
            )
        else:
            self.send_message(
                chat_id,
                "❌ *Erreur lors de l'envoi*\n\n"
                "Votre feedback n'a pas pu être envoyé à cause d'un problème technique.\n\n"
                "Réessayez plus tard ou contactez l'équipe de support.",
            )

    def process_bug_report(self, chat_id: int, user: Dict[str, Any], message: str):
        user_id = user["id"]
        user_name = user.get("username") or user.get("first_name", f"User_{user_id}")

        priority = "normal"
        priority_keywords = {
            "crash": "urgent",
            "plantage": "urgent",
            "bloque": "high",
            "erreur": "high",
            "ne fonctionne": "high",
            "bug critique": "urgent",
        }

        message_lower = message.lower()
        for keyword, prio in priority_keywords.items():
            if keyword in message_lower:
                priority = prio
                break

        title = f"[BUG-{priority.upper()}] Signalement de {user_name}"
        priority_emoji = {"urgent": "🚨", "high": "🔴", "normal": "🟡"}
        title = f"{priority_emoji.get(priority, '🟡')} {title}"

        body = (
            f"🐛 **Bug signalé par @{user_name}**\n\n"
            f"**Priorité:** {priority.upper()}\n\n"
            f"**Description du problème:**\n{message}\n\n"
            f"**Informations techniques:**\n- ID utilisateur: {user_id}\n\n"
            f"**Note pour les développeurs:**\n_Priorité détectée automatiquement basée sur les mots-clés dans le message._"
        )

        labels = ["bug"]
        if priority == "urgent":
            labels.extend(["urgent", "priority-urgent"])
        elif priority == "high":
            labels.extend(["high-priority"])

        issue = github_manager.create_issue(title=title, body=body, labels=labels)

        if issue:
            priority_text = {
                "urgent": "🔴 **URGENTE** - sera traitée rapidement",
                "high": "🟠 **ÉLEVÉE** - traitement prioritaire",
                "normal": "🟡 **NORMALE** - traitement standard",
            }
            self.send_message(
                chat_id,
                "✅ *Bug signalé avec succès !*\n\n"
                f"📋 **Numéro de suivi :** #{issue['number']}\n"
                f"🔗 **Lien :** {issue['html_url']}\n"
                f"🎯 **Priorité détectée :** {priority_text.get(priority, priority)}\n\n"
                "Nous examinerons le problème et vous tiendrons informé.",
            )
        else:
            self.send_message(
                chat_id,
                "❌ *Erreur lors du signalement*\n\n"
                "Votre rapport de bug n'a pas pu être transmis à cause d'un problème technique.\n\n"
                "Réessayez plus tard ou contactez l'équipe de support.",
            )

    def process_updates(self):
        updates = self.api_call("getUpdates", {"offset": self.last_update_id + 1, "timeout": 10})
        if not updates:
            return
        for update in updates:
            update_id = update.get("update_id")
            if update_id:
                self.last_update_id = max(self.last_update_id, update_id)

            message = update.get("message")
            if message and message.get("text", "").startswith("/"):
                self.handle_command(message)
            elif message:
                self.handle_message(message)

    def run(self):
        logger.info("🚀 Telegram Bot started! Press Ctrl+C to stop.")
        logger.info("📡 Bot is polling for messages...")
        while True:
            try:
                self.process_updates()
            except KeyboardInterrupt:
                logger.info("👋 Bot stopped by user.")
                break
            except Exception as e:
                if "timed out" not in str(e).lower():
                    logger.error(f"Error: {e}")


def main() -> None:
    telegram_token = os.getenv("TELEGRAM_TOKEN")
    if not telegram_token:
        logger.error("TELEGRAM_TOKEN environment variable not set!")
        return

    logger.info("Bot NgonNest v2.0 - Starting...")
    logger.info(f"GitHub integration: {'ENABLED' if github_manager.github_token else 'DISABLED'}")
    logger.info(f"GitHub repo: {github_manager.github_repo}")

    bot = TelegramBot(telegram_token)
    bot.run()


if __name__ == "__main__":
    main()
