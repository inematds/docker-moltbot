FROM node:22-slim

LABEL maintainer="inematds"
LABEL description="Moltbot - AI Personal Assistant with security hardening"

# System dependencies (git is required for npm install)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    python3 \
    python3-pip \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Moltbot
# Install Moltbot (currently installs clawdbot as the runtime engine)
# The 'moltbot' npm package will become the full runtime in a future release
RUN npm install -g clawdbot

# Install Faster Whisper for audio transcription (optional, may fail on some architectures)
RUN pip3 install --break-system-packages --no-cache-dir \
    faster-whisper \
    torch --index-url https://download.pytorch.org/whl/cpu \
    || true

# Create non-root user
RUN useradd -m -s /bin/bash moltbot

# Create directories with proper permissions
# Create .clawdbot (runtime uses this until moltbot npm fully ships)
RUN mkdir -p /home/moltbot/.clawdbot /home/moltbot/workspace /home/moltbot/logs

# Copy files BEFORE switching to non-root user (need root for sed/chmod)
COPY config/moltbot.json.template /home/moltbot/.clawdbot/clawdbot.json.template
COPY entrypoint.sh /home/moltbot/entrypoint.sh

# Fix Windows CRLF line endings + set permissions
RUN sed -i 's/\r$//' /home/moltbot/entrypoint.sh \
    && chmod +x /home/moltbot/entrypoint.sh \
    && chown -R moltbot:moltbot /home/moltbot

# Switch to non-root user
USER moltbot
WORKDIR /home/moltbot/workspace

EXPOSE 18789

ENTRYPOINT ["/home/moltbot/entrypoint.sh"]
# Use clawdbot CLI until moltbot npm package ships the full runtime
CMD ["clawdbot", "gateway", "run"]
