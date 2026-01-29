# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker Moltbot is a Docker-based deployment of Moltbot (formerly Clawdbot), an AI personal assistant that runs locally with security hardening built-in. This repository provides a production-ready Docker setup with:
- Security hardening by default (non-root user, loopback binding, pairing-based authentication)
- Multi-channel support (Telegram, WhatsApp, Discord, Slack, Webchat)
- Multi-LLM support (Claude, GPT, Gemini, OpenRouter)
- Persistent storage with Docker volumes
- Automated configuration via environment variables

## Build and Run Commands

### Basic Commands
```bash
# Build and start container
docker compose up -d

# Rebuild from scratch (pulls latest moltbot)
docker compose build --no-cache
docker compose up -d

# View logs
docker compose logs -f              # Follow logs
docker compose logs --tail 100      # Last 100 lines

# Container lifecycle
docker compose restart              # Restart container
docker compose stop                 # Stop without removing
docker compose down                 # Stop and remove container
docker compose down -v              # Remove container + volumes (deletes all data)

# Access container shell
docker compose exec moltbot bash
```

### Moltbot CLI Commands
```bash
# Configuration and status
docker compose exec moltbot moltbot status          # Show gateway status
docker compose exec -it moltbot moltbot configure   # Interactive setup wizard
docker compose exec moltbot moltbot doctor --fix    # Auto-detect and fix config issues
docker compose exec moltbot moltbot doctor          # Check issues without fixing

# Security
docker compose exec moltbot moltbot security audit  # Run security audit

# Channel management
docker compose exec -it moltbot moltbot channels login whatsapp   # Login to WhatsApp
docker compose exec moltbot moltbot pairing approve telegram <code>  # Approve Telegram pairing

# Note: The CLI uses 'moltbot' commands, but the actual runtime currently uses 'clawdbot'
# This is due to the ongoing rebrand. Both work interchangeably.
```

## Architecture

### Docker Architecture
- **Base image**: `node:22-slim`
- **Runtime**: Currently installs `clawdbot` npm package (will transition to `moltbot` when fully released)
- **User**: Non-root user `moltbot` (UID/GID created during build)
- **Entry point**: `entrypoint.sh` — performs config generation and env var injection
- **Security**: AppArmor, no-new-privileges, read-only tmpfs where applicable

### Directory Structure
```
/home/moltbot/
├── .clawdbot/              # Config directory (runtime uses ~/.clawdbot until full moltbot release)
│   ├── clawdbot.json       # Generated config (secrets injected from env vars)
│   └── clawdbot.json.template  # Template copied during build
├── workspace/              # Agent workspace (AGENTS.md, memory, project files)
└── logs/                   # Log files (not in /tmp — persists across restarts)
```

### Docker Volumes
| Volume | Mount Path | Purpose |
|--------|-----------|---------|
| `moltbot-data` | `/home/moltbot/.clawdbot` | Config, session data, auth tokens, pairing info |
| `moltbot-workspace` | `/home/moltbot/workspace` | Workspace files, AGENTS.md, memory |
| `moltbot-logs` | `/home/moltbot/logs` | Log files (persistent) |

### Configuration Flow
1. **Build time**: Dockerfile copies `moltbot.json.template` to container
2. **Runtime**: `entrypoint.sh` generates config from template on first run
3. **Env var injection**: `entrypoint.sh` injects secrets (API keys, tokens) from environment variables into config JSON
4. **Provider detection**: Auto-detects LLM provider from env vars (priority: Anthropic > OpenRouter > OpenAI > Google)
5. **Config written**: Final config saved as `~/.clawdbot/clawdbot.json` with `chmod 600`
6. **Gateway starts**: `clawdbot gateway run` command executes

### Network & Security
- **Gateway bind**: Container binds to `0.0.0.0:18789` internally (required for Docker port mapping)
- **Host access**: `docker-compose.yml` restricts host-side access to `127.0.0.1:18789` (loopback only)
- **Network**: Bridge network `moltbot-net` with `internal: false` (allows outbound internet for API calls)
- **Security options**: `no-new-privileges:true`, user isolation
- **DM policy**: Defaults to `pairing` (users must be approved before chatting)

### Multi-LLM Provider Configuration
The entrypoint.sh automatically configures the LLM provider based on which API keys are present:

1. **Anthropic direct**: If `ANTHROPIC_API_KEY` is set and not a placeholder
2. **OpenRouter**: If `OPENROUTER_API_KEY` is set — automatically routes anthropic/openai/google requests through OpenRouter
3. **OpenAI direct**: If `OPENAI_API_KEY` is set
4. **Google direct**: If `GOOGLE_API_KEY` is set

**OpenRouter routing** (entrypoint.sh:73-84): When OpenRouter is detected, the script sets `auth.order` to route all provider requests through OpenRouter and sets a default model (`anthropic/claude-3.5-sonnet`).

## Key Files

### Dockerfile
- Installs system dependencies: `ffmpeg`, `python3`, `git`, `curl`
- Installs `clawdbot` globally via npm (the actual runtime, until moltbot npm is fully released)
- Optionally installs `faster-whisper` for audio transcription (may fail on some architectures)
- Creates non-root user `moltbot`
- Fixes Windows CRLF line endings with `sed -i 's/\r$//'` on entrypoint.sh
- Sets proper ownership and permissions

### entrypoint.sh
Bash script that runs before Moltbot starts. Key responsibilities:
- Creates config directory if missing
- Generates config from template on first run
- Injects environment variables into JSON config using Node.js
- Auto-detects and configures LLM provider
- Sets gateway bind to `lan` (required for Docker)
- Configures logging level
- Sets `chmod 600` on config file (protect secrets)
- Executes CMD (clawdbot gateway run)

**JSON injection pattern** (entrypoint.sh:23-31): Uses Node.js one-liner to parse JSON, modify, and write back:
```bash
inject_json() {
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$file', 'utf8'));
    $script  # JavaScript modification here
    fs.writeFileSync('$file', JSON.stringify(cfg, null, 2));
  "
}
```

### docker-compose.yml
- Service name: `moltbot`
- Build context: current directory (uses Dockerfile)
- Restart policy: `unless-stopped`
- Port binding: `127.0.0.1:18789:18789` (loopback only on host)
- Three volumes for data, workspace, logs
- Bridge network with internet access
- Security: `no-new-privileges:true`

### config/moltbot.json.template
Template config with defaults:
- Gateway: port 18789, local mode, loopback bind
- Logging: info level, pretty console output
- Diagnostics: enabled
- Channels: Telegram disabled by default
- Agents: workspace at `/home/moltbot/workspace`, safeguard compaction mode

## Common Development Tasks

### Modifying Security Settings
Security configuration is in SECURITY.md. The Docker setup implements 7/10 hardening measures automatically. To add additional hardening:
- AppArmor: Add `apparmor:docker-default` to `security_opt` in docker-compose.yml
- Capability dropping: Add `cap_drop: [ALL]` and `cap_add: [NET_BIND_SERVICE]`
- Network isolation: Set `internal: true` in networks (blocks all outbound — breaks API calls unless using local models)

### Testing Changes to entrypoint.sh
```bash
# Edit entrypoint.sh
nano entrypoint.sh

# Rebuild (entrypoint.sh is copied during build)
docker compose build

# Start and watch logs
docker compose up

# If there are errors, the entrypoint logs will show what failed
```

### Adding Environment Variables
1. Add to `.env.example` with placeholder value
2. Update `entrypoint.sh` to inject the value (see existing patterns for TELEGRAM_BOT_TOKEN, ANTHROPIC_API_KEY, etc.)
3. Update README.md if user-facing
4. Test: set value in `.env`, rebuild, check config with `docker compose exec moltbot cat ~/.clawdbot/clawdbot.json`

### Windows CRLF Issues
The repo has multiple safeguards:
- `.gitattributes`: Forces LF line endings for `.sh` files
- Dockerfile: `sed -i 's/\r$//' /home/moltbot/entrypoint.sh` strips CRLF at build time

If you see `exec format error` or `no such file or directory` for entrypoint.sh:
1. Check line endings: `file entrypoint.sh` should show "POSIX shell script" not "with CRLF"
2. Convert if needed: `dos2unix entrypoint.sh` or in VS Code: change CRLF to LF (bottom right status bar)
3. Rebuild: `docker compose build --no-cache`

## Migration Notes (Clawdbot → Moltbot)

This codebase is in transition from `clawdbot` to `moltbot`:
- **NPM package**: Currently installs `clawdbot` (the full runtime)
- **Config directory**: Uses `~/.clawdbot` (Moltbot runtime has fallback support)
- **CLI commands**: Uses `clawdbot gateway run` in CMD
- **Future**: Will switch to `moltbot` npm package and `~/.moltbot` config directory when fully released

When updating to the full moltbot release:
1. Change Dockerfile: `npm install -g moltbot` (line 19)
2. Change CMD: `["moltbot", "gateway", "run"]` (line 51)
3. Volumes will auto-migrate (moltbot has fallback to `~/.clawdbot`)

## Important Technical Details

### Gateway Binding Quirk
- **Inside container**: Must bind to `0.0.0.0` or `lan` (entrypoint.sh sets `bind: "lan"`)
- **Outside container**: docker-compose.yml restricts to `127.0.0.1:18789:18789`
- **Why**: Docker port mapping requires container to listen on all interfaces, but we restrict host-side access to localhost

### Log Storage
- Logs are stored in volume `/home/moltbot/logs` (NOT `/tmp`)
- `/tmp` is tmpfs (cleared on restart)
- Volume-backed logs persist across container restarts

### First Run Detection
`entrypoint.sh` checks if `~/.clawdbot/clawdbot.json` exists. If not, it's a first run:
- Copies from template
- Injects all env vars
- If template is missing, creates minimal config: `{"gateway":{"port":18789},"channels":{}}`

### Config Permissions
`chmod 600` is applied to config file on every container start (entrypoint.sh:123). This protects API keys and tokens from being read by other users.

## Testing

There are no automated tests in this repository. Testing is manual:

### Basic Smoke Test
```bash
# Start container
docker compose up -d

# Wait 10 seconds for startup
sleep 10

# Check status
docker compose exec moltbot moltbot status

# Check logs for errors
docker compose logs --tail 50

# Access webchat
# Open browser: http://localhost:18789/chat
# Enter GATEWAY_AUTH_TOKEN from .env
```

### Security Audit Test
```bash
docker compose exec moltbot moltbot security audit
```

Expected output should show:
- Gateway binding: ✓ (lan inside container, loopback on host)
- DM policy: ✓ (pairing)
- Config permissions: ✓ (600)
- Logging: ✓ (enabled)

## Troubleshooting Common Issues

### Container immediately exits
Check logs: `docker compose logs --tail 50`
- Missing `.env` file: Copy from `.env.example` and fill in values
- Invalid JSON in template: Check `config/moltbot.json.template` syntax
- Missing API keys: Set at least one LLM provider key in `.env`

### "exec entrypoint.sh: no such file or directory"
CRLF line ending issue. Fix: `dos2unix entrypoint.sh` or rebuild with `--no-cache`

### Gateway not accessible on Windows
- Ensure Docker Desktop is running (check system tray for whale icon)
- Windows firewall may block localhost — allow Docker Desktop through firewall
- Try accessing via `http://127.0.0.1:18789/chat` instead of `localhost`

### Config changes not applied
Restart container: `docker compose restart`
Config is only read on startup.

### "npm error: spawn git ENOENT"
Git is missing from the image. This should not happen (git is installed in Dockerfile). If you modified the Dockerfile, ensure `git` is in the `apt-get install` list.

## Security Considerations

### Default Security Posture
This Docker setup implements:
- ✅ Non-root user (moltbot)
- ✅ Loopback-only gateway access (127.0.0.1 on host)
- ✅ Pairing-required DM policy
- ✅ Config file permissions (chmod 600)
- ✅ Secrets via environment variables
- ✅ Logging enabled (audit trail)
- ✅ No privilege escalation

### Not Implemented (User Must Configure)
- ⚠️ AGENTS.md to block dangerous commands (rm -rf, curl | bash, etc.)
- ⚠️ MCP tool access restrictions
- ⚠️ Network isolation (`internal: true`) — would break API calls

### Remote Access
Gateway is bound to loopback only. For remote access:
- **SSH tunnel** (recommended): `ssh -L 18789:localhost:18789 user@host`
- **Tailscale** (for frequent access): Install Tailscale on host, access via Tailscale IP
- **NEVER** change port binding to `0.0.0.0:18789:18789` — this exposes gateway to the internet

## Environment Variables Reference

| Variable | Required | Purpose | Example |
|----------|----------|---------|---------|
| `GATEWAY_AUTH_TOKEN` | Yes | Protects gateway API | `openssl rand -hex 24` |
| `ANTHROPIC_API_KEY` | One of these | Claude models | `sk-ant-...` |
| `OPENAI_API_KEY` | One of these | GPT models | `sk-...` |
| `OPENROUTER_API_KEY` | One of these | Multi-model gateway | `sk-or-...` |
| `GOOGLE_API_KEY` | One of these | Gemini models | `...` |
| `TELEGRAM_BOT_TOKEN` | No | Telegram channel | `123456:ABC...` |
| `BRAVE_API_KEY` | No | Web search tool | `...` |
| `LOG_LEVEL` | No | Logging verbosity | `info` (default) |

## Additional Documentation

- **README.md**: User-facing documentation, setup instructions, channel configuration
- **SECURITY.md**: Detailed security hardening guide for local and cloud deployments
- **Official docs**: https://docs.molt.bot
- **Discord community**: https://discord.gg/clawd
