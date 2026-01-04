import os
import json
import requests
import logging
from typing import Optional, Dict, Any

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

# État global (attention: reset à chaque invocation serverless !)
user_states: Dict[int, str] = {}

def api_call(method: str, data: Optional[Dict[str, Any]] = None):
    """Make an API call to Telegram."""
    token = os.getenv("TELEGRAM_TOKEN")
    if not token:
        logger.error("TELEGRAM_TOKEN not set")
        return None
    base_url = f"https://api.telegram.org/bot{token}"
    url = f"{base_url}/{method}"
    try:
        response = requests.post(url, json=data) if data else requests.get(url)
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

def handle_command(message: Dict[str, Any]):
    text = message.get("text", "") or ""
    chat_id = message["chat"]["id"]
    user_id = message["from"]["id"]

    if text.startswith("/start"):
        send_message(
            chat_id,
            "🏠 *Bienvenue sur NgonNest Bot !*\n\n"
            "Je peux vous aider avec :\n"
            "• `/feedback` - Partager vos suggestions\n"
            "• `/bug` - Signaler un problème\n"
            "• `/help` - Voir toutes les commandes\n\n"
            "Utilisez ces commandes pour nous aider à améliorer l'application !",
        )
    elif text.startswith("/help"):
        send_message(
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
        send_message(
            chat_id,
            f"📊 *État du Bot NgonNest*\n\n"
            f"🤖 Bot: {status}\n"
            f"🐙 GitHub: {github_status}\n"
            f"📝 Repo: `{github_manager.github_repo}`\n\n"
            f"*Integration active:* {'Oui' if github_ok else 'Non (nécessite GITHUB_TOKEN)'}",
        )
    elif text.startswith("/cancel"):
        if user_id in user_states:
            operation = user_states[user_id]
            del user_states[user_id]
            send_message(
                chat_id,
                f"❌ Opération *{operation}* annulée.\n\n"
                "Vous pouvez recommencer avec `/feedback` ou `/bug`.",
            )
        else:
            send_message(
                chat_id,
                "ℹ️ Aucune opération en cours.\n\n"
                "Utilisez `/feedback` ou `/bug` pour commencer.",
            )
    elif text.startswith("/feedback"):
        user_states[user_id] = "feedback"
        send_message(
            chat_id,
            "💡 *Envoyer un feedback*\n\n"
            "Pouvez-vous me décrire votre suggestion ou idée d'amélioration ?\n\n"
            "📝 *Exemple :* \"Il serait pratique d'avoir une fonction de recherche dans l'inventaire.\"\n\n"
            "_Tapez votre message ou utilisez /cancel pour annuler._",
        )
    elif text.startswith("/bug"):
        user_states[user_id] = "bug"
        send_message(
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
        send_message(
            chat_id,
            "❓ *Commande inconnue*\n\n"
            "Utilisez `/help` pour voir toutes les commandes disponibles.",
        )

def handle_message(message: Dict[str, Any]):
    chat_id = message["chat"]["id"]
    user_id = message["from"]["id"]
    user = message["from"]
    text = message.get("text", "") or ""
    if user_id not in user_states:
        send_message(
            chat_id,
            "🤔 Je ne comprends pas ce message.\n\n"
            "Utilisez une commande comme `/feedback` ou `/bug`, "
            "ou consultez l'aide avec `/help`.",
        )
        return
    state = user_states[user_id]
    if state == "feedback":
        process_feedback(chat_id, user, text)
    elif state == "bug":
        process_bug_report(chat_id, user, text)
    if user_id in user_states:
        del user_states[user_id]

def process_feedback(chat_id: int, user: Dict[str, Any], message: str):
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
        send_message(
            chat_id,
            "✅ *Feedback envoyé avec succès !*\n\n"
            f"📋 **Numéro de suivi :** #{issue['number']}\n"
            f"🔗 **Lien :** {issue['html_url']}\n\n"
            "Merci pour votre contribution ! Nous étudierons votre suggestion.",
        )
    else:
        send_message(
            chat_id,
            "❌ *Erreur lors de l'envoi*\n\n"
            "Votre feedback n'a pas pu être envoyé à cause d'un problème technique.\n\n"
            "Réessayez plus tard ou contactez l'équipe de support.",
        )

def process_bug_report(chat_id: int, user: Dict[str, Any], message: str):
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
        send_message(
            chat_id,
            "✅ *Bug signalé avec succès !*\n\n"
            f"📋 **Numéro de suivi :** #{issue['number']}\n"
            f"🔗 **Lien :** {issue['html_url']}\n"
            f"🎯 **Priorité détectée :** {priority_text.get(priority, priority)}\n\n"
            "Nous examinerons le problème et vous tiendrons informé.",
        )
    else:
        send_message(
            chat_id,
            "❌ *Erreur lors du signalement*\n\n"
            "Votre rapport de bug n'a pas pu être transmis à cause d'un problème technique.\n\n"
            "Réessayez plus tard ou contactez l'équipe de support.",
        )

def handler(event, context):
    """Fonction serverless pour Vercel."""
    if event['httpMethod'] != 'POST':
        return {"statusCode": 405, "body": "Méthode non autorisée"}

    try:
        update = json.loads(event['body'])
        message = update.get("message")
        if message:
            if message.get("text", "").startswith("/"):
                handle_command(message)
            else:
                handle_message(message)
        return {"statusCode": 200, "body": json.dumps({"ok": True})}
    except Exception as e:
        logger.error(f"Erreur: {e}")
        return {"statusCode": 500, "body": "Erreur interne"}
