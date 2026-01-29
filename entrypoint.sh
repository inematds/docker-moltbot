#!/bin/bash
set -e

# Config directory: clawdbot runtime uses ~/.clawdbot
CONFIG_DIR="$HOME/.clawdbot"
CONFIG_FILE="$CONFIG_DIR/clawdbot.json"
TEMPLATE_FILE="$CONFIG_DIR/clawdbot.json.template"

# Create config directory if needed
mkdir -p "$CONFIG_DIR"

# Create config from template if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
  echo "🤖 First run — creating config from template..."
  if [ -f "$TEMPLATE_FILE" ]; then
    cp "$TEMPLATE_FILE" "$CONFIG_FILE"
  else
    echo '{"gateway":{"port":18789},"channels":{}}' > "$CONFIG_FILE"
  fi
fi

# Helper: inject JSON value using Node.js
inject_json() {
  local file="$1" script="$2"
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$file', 'utf8'));
    $script
    fs.writeFileSync('$file', JSON.stringify(cfg, null, 2));
  "
}

# Inject GATEWAY_AUTH_TOKEN
if [ -n "$GATEWAY_AUTH_TOKEN" ]; then
  echo "🔑 Setting gateway auth token..."
  inject_json "$CONFIG_FILE" "
    cfg.gateway = cfg.gateway || {};
    cfg.gateway.auth = cfg.gateway.auth || {};
    cfg.gateway.auth.token = process.env.GATEWAY_AUTH_TOKEN;
  "
fi

# Inject Telegram bot token
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  echo "📱 Enabling Telegram..."
  inject_json "$CONFIG_FILE" "
    cfg.channels = cfg.channels || {};
    cfg.channels.telegram = cfg.channels.telegram || {};
    cfg.channels.telegram.enabled = true;
    cfg.channels.telegram.botToken = process.env.TELEGRAM_BOT_TOKEN;
    cfg.channels.telegram.dmPolicy = cfg.channels.telegram.dmPolicy || 'pairing';
    cfg.channels.telegram.groupPolicy = cfg.channels.telegram.groupPolicy || 'allowlist';
  "
fi

# Configure OpenRouter as LLM provider
if [ -n "$OPENROUTER_API_KEY" ] && [ "$OPENROUTER_API_KEY" != "sk-or-your-key-here" ]; then
  echo "🧠 OpenRouter configured — multi-model gateway active"

  # Set default model from env var or use Claude Sonnet 4.5
  DEFAULT_MODEL="${DEFAULT_MODEL:-anthropic/claude-sonnet-4-5}"

  inject_json "$CONFIG_FILE" "
    cfg.auth = cfg.auth || {};
    cfg.auth.profiles = cfg.auth.profiles || {};
    cfg.auth.profiles['openrouter:default'] = { provider: 'openrouter', mode: 'token' };
    cfg.agents = cfg.agents || {};
    cfg.agents.defaults = cfg.agents.defaults || {};
    if (!cfg.agents.defaults.model) {
      cfg.agents.defaults.model = { primary: 'openrouter/${process.env.DEFAULT_MODEL}' };
    }
  "
  echo "   Model: $DEFAULT_MODEL"
else
  echo "⚠️  OPENROUTER_API_KEY not set! Please configure it in .env"
  echo "   Get your key at: https://openrouter.ai/"
fi

# Docker requires binding to 0.0.0.0 inside the container for port mapping to work.
# The docker-compose.yml restricts external access to 127.0.0.1 on the host.
echo "🌐 Setting gateway bind to lan (required for Docker port mapping)..."
inject_json "$CONFIG_FILE" "
  cfg.gateway = cfg.gateway || {};
  cfg.gateway.bind = 'lan';
"

# Configure logging
echo "📝 Configuring logging..."
inject_json "$CONFIG_FILE" "
  cfg.logging = cfg.logging || {};
  cfg.logging.level = cfg.logging.level || 'info';
"

# Set proper permissions on config (secrets inside)
chmod 600 "$CONFIG_FILE" 2>/dev/null || true

echo "🤖 Starting Moltbot..."
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  🌐 Webchat: http://localhost:18789/chat                ║"
echo "║  🔑 Token: use your GATEWAY_AUTH_TOKEN from .env        ║"
echo "║  🧠 Model: ${DEFAULT_MODEL:-anthropic/claude-sonnet-4-5} ║"
echo "║  📋 Status: docker exec moltbot clawdbot status          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
exec "$@"
