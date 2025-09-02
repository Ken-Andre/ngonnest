import os
import logging
from dotenv import load_dotenv
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Send a message when the command /start is issued."""
    await update.message.reply_text("Bienvenue !")

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Send a message when the command /help is issued."""
    await update.message.reply_text(
        "Commandes disponibles :\n"
        "/start - Démarrer le bot\n"
        "/help - Afficher cette aide"
    )

def main() -> None:
    """Start the bot."""
    # Get token from environment variable
    token = os.getenv("TELEGRAM_TOKEN")
    if not token:
        logger.error("TELEGRAM_TOKEN environment variable not set!")
        return

    # Create the Application and pass it your bot's token.
    # Use simpler configuration for v20.7
    app = Application.builder().token(token).build()

    # Add command handlers
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help_command))

    # Start the Bot
    logger.info("Bot started and running...")
    app.run_polling()

if __name__ == "__main__":
    main()
