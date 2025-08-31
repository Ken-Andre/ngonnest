from telegram.ext import Application, CommandHandler
async def start(update, context):
    await update.message.reply_text("Bienvenue !")
async def help(update, context):
    await update.message.reply_text("Commandes : /start, /help, /feedback, /bug")
def main():
    app = Application.builder().token("8445505928:AAEE9xmMADCIoAF-KMHpRQ9yISt_vUhVHYU").build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help))
    app.run_polling()
if __name__ == "__main__":
    main()