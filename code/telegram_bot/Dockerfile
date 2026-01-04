# Dockerfile pour NgonNest Telegram Bot
FROM python:3.11-slim

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY requirements.txt .

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code de l'application
COPY main.py .
COPY .env* ./

# Variables d'environnement (à surcharger au runtime)
ENV TELEGRAM_TOKEN=""
ENV GITHUB_TOKEN=""
ENV GITHUB_REPO="Ken-Andre/ngonnest"

# Commande de démarrage
CMD ["python", "main.py"]
