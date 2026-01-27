<p align="center">
  <img src="assets/moltbot-banner.jpg" alt="Moltbot - AI Assistant" width="100%">
</p>

# 🤖 Docker Moltbot

[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Node.js](https://img.shields.io/badge/Node.js-22-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Security Hardened](https://img.shields.io/badge/Security-Hardened-green?logo=shieldsdotio)](SECURITY.md)
[![Docs](https://img.shields.io/badge/Docs-docs.molt.bot-blue)](https://docs.molt.bot)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/clawd)

Docker setup for [Moltbot](https://molt.bot) — an AI personal assistant with security hardening out of the box.

> **Moltbot** is an AI assistant that runs on your own machine. It connects to LLMs (Claude, GPT, Gemini, etc.), has tools (web search, code execution, file management, browser control), and talks to you via Telegram, WhatsApp, Discord, webchat, and more. This repo gives you a ready-to-run Docker setup with security best practices baked in.

---

## ✨ Features

- 🔒 **Security hardened** — follows the [Top 10 Security Checklist](SECURITY.md)
- 🐳 **One command setup** — `docker compose up -d`
- 🔐 **Secrets via env vars** — no plaintext credentials in config files
- 👤 **Non-root container** — runs as unprivileged `moltbot` user
- 📝 **Logging enabled** — audit trail by default
- 📱 **Multi-channel** — Telegram, WhatsApp, Discord, Slack, webchat, and more
- 🎙️ **Audio transcription** — Faster Whisper included (optional)
- 🛠️ **Tool-capable** — shell access, web search, browser control, code execution
- 🧠 **Multi-LLM** — Claude, GPT, Gemini, Llama, DeepSeek via OpenRouter
- 🪟 **Windows compatible** — `.gitattributes` enforces LF endings, Dockerfile fixes CRLF
- 🔄 **Auto-restart** — `unless-stopped` restart policy
- 🌐 **Network secure** — gateway binds to loopback, Docker network isolation available

---

## 📋 Prerequisites

| Platform | Requirement | Install |
|----------|------------|---------|
| **Windows** | Docker Desktop | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **Windows** | Git | [git-scm.com](https://git-scm.com/download/win) |
| **Mac** | Docker Desktop | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **Linux** | Docker Engine + Compose | `curl -fsSL https://get.docker.com \| sh` |

> ⚠️ **Windows users:** Make sure **Docker Desktop is running** before proceeding. Check the system tray for the Docker icon (🐳). If WSL shows `docker-desktop Stopped`, open Docker Desktop from the Start menu and wait until it says "Docker is running".

> ⚠️ **Windows users:** If you've never used Docker before, you may need to enable **WSL 2** first. Docker Desktop will prompt you to install it — just follow the instructions and restart your computer when asked.

---

## 🚀 Quick Start

### Step 1: Clone the repo

**Linux / Mac:**
```bash
git clone https://github.com/inematds/docker-moltbot.git
cd docker-moltbot
```

**Windows (CMD):**
```cmd
git clone https://github.com/inematds/docker-moltbot.git
cd docker-moltbot
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/inematds/docker-moltbot.git
cd docker-moltbot
```

### Step 2: Configure environment

**Linux / Mac:**
```bash
cp .env.example .env
nano .env  # Fill in your API keys
```

**Windows (CMD):**
```cmd
copy .env.example .env
notepad .env
```

**Windows (PowerShell):**
```powershell
Copy-Item .env.example .env
notepad .env
```

> ⚠️ **IMPORTANT:** You **MUST** create AND edit the `.env` file before running `docker compose up`. The container will not work with placeholder values.

Open the `.env` file and replace the placeholder values with your real keys:

```env
# ❌ WRONG — these are placeholders, they won't work:
ANTHROPIC_API_KEY=sk-ant-your-key-here
GATEWAY_AUTH_TOKEN=your-secure-token-here

# ✅ RIGHT — your actual keys:
ANTHROPIC_API_KEY=sk-ant-abc123-your-actual-real-key
GATEWAY_AUTH_TOKEN=a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6
```

### Step 3: Generate a secure gateway token

The `GATEWAY_AUTH_TOKEN` protects your gateway API from unauthorized access. Generate a random one:

**Linux / Mac:**
```bash
openssl rand -hex 24
```

**Windows (PowerShell):**
```powershell
-join ((1..48) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) })
```

**Or** just use any long random string (at least 24 characters). You can use a password manager to generate one.

Copy the generated token into your `.env` file as `GATEWAY_AUTH_TOKEN`.

### Step 4: Choose your LLM provider

You need **at least one** LLM provider API key. Here are your options:

| Provider | Env Variable | Get Key | Notes |
|----------|-------------|---------|-------|
| Anthropic (Claude) | `ANTHROPIC_API_KEY` | [console.anthropic.com](https://console.anthropic.com/) | Best for conversations and complex tasks |
| OpenAI (GPT) | `OPENAI_API_KEY` | [platform.openai.com](https://platform.openai.com/api-keys) | Great for code generation |
| OpenRouter (multi-model) | `OPENROUTER_API_KEY` | [openrouter.ai](https://openrouter.ai/) | Access to many models, **free tier available** |
| Google (Gemini) | `GOOGLE_API_KEY` | [ai.google.dev](https://ai.google.dev/) | Good free tier |

> 💡 **Tip:** OpenRouter gives access to multiple models (Claude, GPT, Llama, Gemini, DeepSeek) with a single API key — including **free models**. Great for getting started without spending money.

### Step 5: Build and run

```bash
docker compose up -d
```

> 💡 **First run** takes a few minutes to build the image (downloads Node.js, FFmpeg, Python, etc). Subsequent runs start instantly.

> ⚠️ **Windows error `open //./pipe/dockerDesktopLinuxEngine`?** Docker Desktop is not running. Open it from the Start menu and wait until it shows "Docker is running", then retry.

### Step 6: Check status

```bash
# Watch the logs (Ctrl+C to stop watching)
docker compose logs -f

# Or check just the last 50 lines
docker compose logs --tail 50
```

You should see output like:
```
🤖 First run — creating config from template...
🔑 Setting gateway auth token...
📱 Enabling Telegram...
🌐 Setting gateway bind to lan (required for Docker port mapping)...
📝 Enabling logging...
🤖 Starting Moltbot...
```

### Step 7: Post-install setup

After the container is running, use these commands to fine-tune your setup:

```bash
# Run the interactive setup wizard (API keys, channels, preferences)
docker compose exec -it moltbot moltbot configure

# Auto-detect and fix config issues
docker compose exec -it moltbot moltbot doctor --fix

# Check overall health
docker compose exec moltbot moltbot status

# Run a security audit
docker compose exec moltbot moltbot security audit
```

| Command | What it does |
|---------|-------------|
| `moltbot configure` | Interactive wizard — set up API keys, channels (Telegram, WhatsApp, etc.), model preferences |
| `moltbot doctor --fix` | Auto-detect and fix config issues (e.g. Telegram configured but not enabled) |
| `moltbot doctor` | Same check, but only **shows** issues without fixing |
| `moltbot status` | Show gateway status, connected channels, model info |
| `moltbot security audit` | Check your setup against security best practices |

---

## 📱 Telegram Setup

Telegram is the easiest way to talk to your Moltbot from anywhere.

### Step-by-step:

1. **Create a bot** — Open Telegram and message [@BotFather](https://t.me/BotFather)
2. **Send `/newbot`** — Follow the prompts to name your bot
3. **Copy the token** — BotFather gives you a token like `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`
4. **Add to `.env`:**
   ```env
   TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
   ```
5. **Restart the container:**
   ```bash
   docker compose restart
   ```
6. **Message your bot** on Telegram — it will give you a **pairing code**
7. **Approve the pairing** inside the container:
   ```bash
   docker compose exec moltbot moltbot pairing approve telegram <code>
   ```

> 💡 The pairing system ensures that only approved users can talk to your bot. This is a security feature — without approval, the bot won't respond to random strangers.

### Optional: Configure BotFather settings

While in BotFather, you can also:
- `/setdescription` — Add a description for your bot
- `/setabouttext` — Add "About" text
- `/setuserpic` — Set a profile picture
- `/setcommands` — Define bot commands (optional)

---

## 📲 WhatsApp Setup

You can connect Moltbot to WhatsApp via QR code pairing.

### Step-by-step:

1. **Run the login command:**
   ```bash
   docker compose exec -it moltbot moltbot channels login whatsapp
   ```
2. **Scan the QR code** with your WhatsApp (Settings → Linked Devices → Link a Device)
3. **Done!** Your Moltbot is now connected to WhatsApp

### ⚠️ Personal Number vs. Dedicated Number

**Using your personal number:**
- The bot will see messages from all your contacts
- By default, DM policy is `pairing` — others may receive a pairing prompt
- **Recommended:** Set `dmPolicy: allowlist` with only your number:

```json
{
  "channels": {
    "whatsapp": {
      "selfChatMode": true,
      "dmPolicy": "allowlist",
      "allowFrom": ["+5511999999999"]
    }
  }
}
```

**Using a dedicated number (recommended):**
- Get a cheap prepaid SIM or Google Voice number
- Install WhatsApp on a secondary phone or use WhatsApp Web
- Cleaner separation between personal and bot messages

> 💡 **Self-chat mode:** Talk to yourself on WhatsApp — messages to your own number go to Moltbot. No one else is affected.

---

## 🔒 Security

This Docker setup implements **7 out of 10** security hardening measures automatically. See [SECURITY.md](SECURITY.md) for the full checklist.

### What Docker does automatically:
| Protection | Status |
|-----------|--------|
| Gateway binds to `127.0.0.1` only (host side) | ✅ Automatic |
| DM policy requires pairing approval | ✅ Automatic |
| Config files are `chmod 600` | ✅ Automatic |
| Container runs as non-root user | ✅ Automatic |
| No privilege escalation (`no-new-privileges`) | ✅ Automatic |
| Logging and diagnostics enabled | ✅ Automatic |
| Secrets via environment variables | ✅ Automatic |

### What YOU should do:
- [ ] Set up `AGENTS.md` to block dangerous commands (see [SECURITY.md](SECURITY.md))
- [ ] Review MCP tool access and restrict to minimum needed
- [ ] Consider `internal: true` network if you don't need internet (blocks API calls too)

### Security audit:
```bash
docker compose exec moltbot moltbot security audit
```

### Threat model (simplified)

**What Moltbot can do:**
- Execute shell commands on the container
- Read/write files in the workspace
- Make HTTP requests (API calls, web search)
- Control a browser (if configured)
- Send messages on connected channels

**What attackers might try:**
- **Prompt injection:** Tricking the bot via crafted web content or messages
- **Shell escape:** Getting the bot to run dangerous commands (`rm -rf /`, `curl | bash`)
- **Token theft:** Stealing API keys from config or logs
- **Unauthorized access:** Messaging the bot without approval
- **Network exposure:** Accessing the gateway from outside localhost

### Common vulnerabilities and mitigations:

| Vulnerability | Risk | Mitigation |
|--------------|------|------------|
| **Prompt injection** | Medium | Moltbot wraps untrusted content in safety tags; configure AGENTS.md to block dangerous patterns |
| **Shell access** | Medium | Container isolation + non-root user; block `rm -rf`, `curl \| bash` in AGENTS.md |
| **Session logs in plaintext** | Low | Logs are inside Docker volumes with restricted permissions; enable `redactSensitive` in config |
| **Unverified plugins** | Low | Only install plugins from trusted sources; review MCP tool permissions |
| **WhatsApp personal number** | Medium | Use `allowlist` dmPolicy or a dedicated number |
| **Network exposure** | Low | Gateway binds to 127.0.0.1; use SSH tunnel or Tailscale for remote access |
| **Browser control** | Medium | Browser runs sandboxed; restrict to trusted sites only |

---

## 📦 Volumes

Docker volumes persist your data across container restarts and rebuilds.

| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `moltbot-data` | `/home/moltbot/.moltbot` | Config, session data, auth tokens, pairing info |
| `moltbot-workspace` | `/home/moltbot/workspace` | Agent workspace — AGENTS.md, memory files, project files |
| `moltbot-logs` | `/home/moltbot/logs` | Log files (NOT in /tmp — survives restarts) |

### Backup your data:
```bash
# Backup all volumes
docker run --rm -v moltbot-data:/data -v $(pwd):/backup alpine tar czf /backup/moltbot-data.tar.gz -C /data .
docker run --rm -v moltbot-workspace:/data -v $(pwd):/backup alpine tar czf /backup/moltbot-workspace.tar.gz -C /data .
```

### Reset everything:
```bash
docker compose down -v  # ⚠️ Deletes ALL data including config and workspace
```

---

## 🛠️ Useful Commands

```bash
# === Lifecycle ===
docker compose up -d              # Start in background
docker compose down               # Stop and remove container
docker compose restart            # Restart
docker compose stop               # Stop without removing

# === Logs ===
docker compose logs -f            # Follow logs (Ctrl+C to stop)
docker compose logs --tail 100    # Last 100 lines

# === Shell access ===
docker compose exec moltbot bash  # Open shell inside container

# === Moltbot CLI ===
docker compose exec moltbot moltbot status          # Gateway status
docker compose exec moltbot moltbot configure       # Interactive setup
docker compose exec moltbot moltbot doctor --fix    # Auto-fix issues
docker compose exec moltbot moltbot security audit  # Security check

# === Update Moltbot ===
docker compose build --no-cache   # Rebuild image (pulls latest moltbot)
docker compose up -d              # Restart with new image

# === Cleanup ===
docker system prune -a            # Remove unused images (reclaim disk space)
```

---

## 🌐 Network Isolation

By default, the container has internet access — this is **required** for API calls to Anthropic, OpenAI, etc.

### Full isolation (no internet):
```yaml
# In docker-compose.yml, change:
networks:
  moltbot-net:
    internal: true  # No internet access
```

> ⚠️ **Warning:** This blocks ALL outgoing connections, including API calls to LLM providers. Only use if you have a **local model setup** (e.g., Ollama running on the same network).

### Partial isolation (allow specific hosts only):
For advanced users, use Docker network policies or iptables rules to allow only specific API endpoints.

---

## 📡 Access Channels

Moltbot supports multiple communication channels simultaneously. All channels share the same agent, memory, and workspace.

| Channel | Type | Access | Setup Difficulty | Best For |
|---------|------|--------|-----------------|----------|
| 📱 **Telegram** | Messaging | Anywhere (mobile/desktop) | ⭐ Easy | Daily use, quick access |
| 📲 **WhatsApp** | Messaging | Anywhere (mobile/desktop) | ⭐ Easy | If you already use WhatsApp |
| 💬 **Webchat** | Web UI | Local network / VPN | ⭐ Easy | Rich UI, file uploads |
| 🌐 **Webchat (public)** | Web UI | Anywhere | ⭐⭐⭐ Advanced | Public-facing bot |
| 🔒 **Tailscale** | VPN | Anywhere (zero-trust) | ⭐⭐ Medium | Most secure remote access |
| 💜 **Discord** | Messaging | Anywhere | ⭐⭐ Medium | Teams, communities |
| 💼 **Slack** | Messaging | Anywhere | ⭐⭐ Medium | Work/enterprise |
| 🔵 **Signal** | Messaging | Anywhere | ⭐⭐⭐ Advanced | Maximum privacy |
| 🟢 **Matrix** | Messaging | Anywhere | ⭐⭐⭐ Advanced | Self-hosted, federated |

### Which should I use?

- **Simplest setup:** Telegram — one bot token and you're done
- **Most private:** Signal or Tailscale + Webchat
- **Access from anywhere without extra apps:** Telegram + WhatsApp (you already have them)
- **Best for teams/work:** Slack or Discord
- **Most secure remote webchat:** Tailscale — zero-trust VPN, no open ports

### Multi-channel

You can enable **multiple channels simultaneously**. All channels share the same agent, memory, and workspace. Messages from any channel arrive in the same assistant.

> ⚠️ **Cross-channel messaging is restricted** by design — the bot won't leak conversation data between channels.

---

## 🖥️ Webchat Access (Remote)

The gateway binds to `127.0.0.1` (loopback only). To access the webchat from another machine, use an **SSH tunnel**:

```bash
# On your local machine (the one with the browser):
ssh -L 18789:localhost:18789 user@your-server-ip

# Then open in your browser:
# http://127.0.0.1:18789/chat
```

This is the safest way to access the web interface remotely — no ports exposed, all traffic encrypted via SSH.

### Alternative: Tailscale (recommended for regular use)

If you access webchat frequently, set up [Tailscale](https://tailscale.com) for seamless VPN access:

```bash
# On your server:
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# On your devices:
# Install Tailscale app, log in with same account
# Access webchat via: http://<tailscale-ip>:18789/chat
```

---

## 🧰 Recommended Tools & Skills

Enhance your Moltbot with these additional tools:

### 🛠 CLI Tools

| Tool | Install | Purpose |
|------|---------|---------|
| [Codex CLI](https://github.com/openai/codex) | `npm i -g @openai/codex` | AI coding agent (OpenAI) |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | `npm i -g agent-browser` | Headless browser automation |
| FFmpeg | Pre-installed in Docker image | Audio/video processing |
| Faster Whisper | Pre-installed in Docker image | Local audio transcription |

### 🎨 API Services

| Service | Purpose | Pricing |
|---------|---------|---------|
| [OpenRouter](https://openrouter.ai) | Gateway to multiple LLMs (free models available) | Free tier + pay-per-use |
| [Kie.ai](https://kie.ai) | Image, video & music generation (Veo 3.1, Flux, Suno) | Credits |
| [ElevenLabs](https://elevenlabs.io) | Text-to-speech (realistic voices) | Free tier + paid |
| [Gamma](https://gamma.app) | AI presentations & documents | Free tier + paid |
| [HeyGen](https://heygen.com) | AI video avatars | Credits |

### 📚 Skills (for Codex / Claude Code)

| Skill | Install | Purpose |
|-------|---------|---------|
| [Remotion Skills](https://github.com/inematds/remotion-skills) | Copy to `.codex/skills/` | Create videos programmatically with React |

```bash
# Install Remotion Skills for Codex
docker compose exec moltbot bash -c '
  git clone https://github.com/inematds/remotion-skills.git /tmp/remotion-skills
  mkdir -p .codex/skills
  cp -r /tmp/remotion-skills/skills/remotion .codex/skills/
'
```

---

## 🧠 LLM Organization

Recommended model strategy for different tasks:

| Model | Provider | Use Case | Cost |
|-------|----------|----------|------|
| Claude Opus 4.5 | Anthropic | Main assistant — conversations, complex tasks | Paid (API or Max plan) |
| gpt-5.2-codex | OpenAI | Code generation (priority) | Paid (Team plan) |
| Gemini 2.0 Flash | Google | Fast tasks, simple queries | Free tier available |
| Free models | OpenRouter | Sub-agents, secondary tasks | Free |

**Free models on OpenRouter:** DeepSeek R1, Llama 3.1 405B, Llama 3.3 70B, Gemini 2.0 Flash, Qwen3 Coder

> 💡 Configure model preferences with `docker compose exec -it moltbot moltbot configure`

---

## 💻 Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **RAM** | 2 GB | 4 GB (with Whisper) |
| **Disk** | 5 GB | 10+ GB |
| **CPU** | 1 core | 2+ cores |
| **Docker** | Engine 24+ / Compose v2+ | Latest stable |
| **OS** | Linux, macOS, Windows 10+ | Ubuntu 22.04+ / macOS 13+ |
| **Network** | Internet access | Stable broadband |

---

## 🔧 Troubleshooting

### Windows Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `open //./pipe/dockerDesktopLinuxEngine: O sistema não pode encontrar o arquivo` | Docker Desktop not running | Open Docker Desktop from Start menu, wait for "Docker is running" |
| `.env not found` | Missing config file | Run `copy .env.example .env` then `notepad .env` |
| `the attribute version is obsolete` | Old docker-compose format | Harmless warning — ignore it (this repo doesn't use `version:`) |
| `WSL docker-desktop Stopped` | WSL not started | Open Docker Desktop — it starts WSL automatically |
| Build hangs or fails | Not enough RAM | Docker Desktop → Settings → Resources → increase to 4GB+ |
| `exec entrypoint.sh: no such file or directory` | Windows CRLF line endings | Re-clone the repo: `git config --global core.autocrlf input` then `git clone` again |
| `npm ERR! Error while executing` | Network/proxy issues | Check your internet connection; if behind a proxy, configure Docker proxy settings |

### Linux / Mac Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `permission denied` | Not in docker group | `sudo usermod -aG docker $USER` then **log out and back in** |
| `port already in use` | Another service on 18789 | Change port in `docker-compose.yml` or stop the other service |
| `no space left on device` | Disk full | `docker system prune -a` to clean old images |
| Build fails on ARM Mac | Architecture mismatch | Usually works fine; if issues, try `docker compose build --platform linux/amd64` |

### Docker / Container Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `exec entrypoint.sh: no such file or directory` | CRLF line endings in entrypoint.sh | **Auto-fixed** by Dockerfile (`sed -i 's/\r$//'`). If it still happens: open `entrypoint.sh` in VS Code → change CRLF to LF (bottom-right corner) → save → rebuild |
| `error: unknown option '--foreground'` | Old command syntax | CMD should be `["moltbot", "gateway", "run"]` — update your Dockerfile |
| `npm error: spawn git ENOENT` | Git not in Docker image | Git is included in this Dockerfile. If using a custom image, add `git` to `apt-get install` |
| Container keeps restarting | Various — check logs | `docker compose logs --tail 50` and look for the error |
| Gateway binds to 127.0.0.1 inside container | Default bind is loopback | **Auto-fixed** by entrypoint.sh (sets `bind: "lan"`). Docker needs 0.0.0.0 inside, but `docker-compose.yml` restricts host access to 127.0.0.1 |
| Logs in /tmp disappear | tmpfs wipes on restart | Logs are stored in `/home/moltbot/logs` volume (NOT /tmp). This is correct by default. |

### General Issues

| Problem | Fix |
|---------|-----|
| Bot not responding to messages | Check logs: `docker compose logs -f`. Verify API keys and bot token are correct. |
| API errors / rate limiting | Verify API keys in `.env` are correct and have credits |
| Can't access webchat remotely | Use SSH tunnel: `ssh -L 18789:localhost:18789 user@server` |
| Bot responds slowly | Check your internet connection; consider a faster LLM model |
| "Pairing required" message | This is expected — approve with `moltbot pairing approve <channel> <code>` |
| Config changes not applied | Restart: `docker compose restart` |

---

## 🔄 Migration from Clawdbot

If you're upgrading from the old `docker-clawdbot` setup, here's what changed:

### What's different:

| Old (Clawdbot) | New (Moltbot) |
|----------------|---------------|
| Package: `clawdbot` (npm) | Package: `moltbot` (npm) |
| CLI: `clawdbot` | CLI: `moltbot` |
| Command: `clawdbot gateway start --foreground` | Command: `moltbot gateway run` |
| Repo: `inematds/docker-clawdbot` | Repo: `inematds/docker-moltbot` |
| Docs: `docs.clawd.bot` | Docs: `docs.molt.bot` (redirects work) |
| Config dir: `~/.clawdbot` | Config dir: `~/.moltbot` (with fallback to `~/.clawdbot`) |
| User: `clawdbot` | User: `moltbot` |
| Container: `clawdbot` | Container: `moltbot` |

### Migration steps:

1. **Backup your data:**
   ```bash
   # From old setup
   cd docker-clawdbot
   docker run --rm -v clawdbot-data:/data -v $(pwd):/backup alpine tar czf /backup/clawdbot-data-backup.tar.gz -C /data .
   docker run --rm -v clawdbot-workspace:/data -v $(pwd):/backup alpine tar czf /backup/clawdbot-workspace-backup.tar.gz -C /data .
   ```

2. **Stop old container:**
   ```bash
   cd docker-clawdbot
   docker compose down
   ```

3. **Clone new repo:**
   ```bash
   git clone https://github.com/inematds/docker-moltbot.git
   cd docker-moltbot
   ```

4. **Copy your .env:**
   ```bash
   cp ../docker-clawdbot/.env .env
   ```

5. **Start new container:**
   ```bash
   docker compose up -d
   ```

6. **Restore data (optional):**
   ```bash
   # Restore workspace
   docker run --rm -v moltbot-workspace:/data -v $(pwd):/backup alpine tar xzf /backup/clawdbot-workspace-backup.tar.gz -C /data
   ```

### Compatibility notes:
- The old `clawdbot` npm package is now a **shim** that redirects to `moltbot`
- Your existing config files are compatible — Moltbot falls back to `~/.clawdbot` if `~/.moltbot` doesn't exist
- Telegram bot tokens, pairing approvals, and API keys carry over unchanged
- You may need to **re-pair** on some channels after migration

### Known issues fixed in this version:
- ✅ `git` package included in Dockerfile (was missing → npm install failed)
- ✅ CRLF line endings auto-fixed by Dockerfile + `.gitattributes` (was causing "no such file" on Windows)
- ✅ Gateway binds to `lan` inside container (was binding to 127.0.0.1 → unreachable from host)
- ✅ Correct command: `moltbot gateway run` (was `clawdbot gateway start --foreground`)
- ✅ Logs in `/home/moltbot/logs` volume (was in /tmp → lost on restart)
- ✅ `.dockerignore` and `.gitignore` included

---

## 🤝 Contributing

PRs welcome! Please follow the security checklist in [SECURITY.md](SECURITY.md).

1. Fork the repo
2. Create a feature branch: `git checkout -b my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push: `git push origin my-feature`
5. Open a Pull Request

### Guidelines:
- Keep security best practices in mind
- Test on both Linux and Windows if possible
- Update documentation for any user-facing changes
- Follow existing code style

---

## 📜 License

[MIT](LICENSE) — use it however you want.

---

<p align="center">
  <a href="https://molt.bot">molt.bot</a> •
  <a href="https://docs.molt.bot">Documentation</a> •
  <a href="https://discord.gg/clawd">Discord</a> •
  <a href="https://github.com/moltbot/moltbot">GitHub</a>
</p>
