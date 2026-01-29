# 🔒 Security Hardening Checklist

Based on the [Moltbot Security Hardening Guide](https://docs.molt.bot) — Top 10 vulnerabilities and fixes.

---

## Three Deployment Scenarios

This guide covers three distinct setups. Choose your scenario:

| | 🏠 Local Basic | 🏠🔒 Local Maximum | ☁️ Cloud VPS |
|---|---|---|---|
| **Physical access** | Yes | Yes | No |
| **Network exposure** | LAN only | LAN only | Public IP |
| **Attack surface** | Low | Low | High |
| **SSH hardening** | Optional | Required | **Critical** |
| **Firewall** | Optional | Required | **Required** |
| **Fail2Ban** | Skip | Optional | **Required** |
| **VPN/Tailscale** | Nice to have | Recommended | **Highly recommended** |
| **Disk encryption** | Optional | Recommended | Provider-dependent |
| **Effort** | 5 minutes | 30 minutes | 45 minutes |

---

## 🏠 Local Server — Basic Security (Home / Office)

You have physical access to the machine. It sits behind your router/firewall.

### Threat model:
- Other devices on your LAN
- Someone with physical access
- Malware on your network

### What this Docker setup does automatically:
```
✅ Gateway bind: loopback (127.0.0.1 on host side)
✅ DM policy: pairing (users must be approved)
✅ Logging enabled (audit trail)
✅ Config permissions: chmod 600 (secrets protected)
✅ Docker container isolation (non-root user)
✅ No privilege escalation (no-new-privileges)
✅ Secrets via environment variables (not in config files)
```

### Recommended extras:
```bash
# Block port 18789 from outside your LAN (most routers do this by default)
# Just make sure you DON'T have port forwarding enabled for 18789

# Enable automatic security updates (Ubuntu/Debian)
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### What you can skip:
- Fail2Ban (no public SSH)
- Changing SSH port (not exposed to internet)
- VPN (you're on the same LAN)

---

## 🏠🔒 Local Server — Maximum Security

Same physical access, but you want **enterprise-grade** protection. For sensitive data, compliance, or healthy paranoia.

### Threat model:
- Compromised device on your LAN
- Malware/ransomware spreading laterally
- Insider threats (shared office/lab)
- Physical theft of the machine
- Supply chain attacks (compromised dependencies)

### 🛡️ Full hardening:

#### 1. Network Isolation (Firewall)
```bash
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 22  # SSH only from your LAN
sudo ufw deny 18789/tcp                              # Block gateway externally
sudo ufw --force enable
```

#### 2. SSH Hardening (Key-Only Auth)
```bash
# Generate key on your local machine
ssh-keygen -t ed25519 -C "local-admin"
ssh-copy-id user@server-local-ip

# Disable password + root login
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sudo systemctl restart sshd
```

#### 3. Full Disk Encryption (LUKS)
Protects against physical theft:
```bash
# Best done during OS install
# If already installed, encrypt data partition:
sudo cryptsetup luksFormat /dev/sdX
sudo cryptsetup luksOpen /dev/sdX moltbot-data
sudo mkfs.ext4 /dev/mapper/moltbot-data
```

#### 4. Docker with AppArmor
```yaml
# Add to docker-compose.yml:
services:
  moltbot:
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
    tmpfs:
      - /tmp:size=512M,noexec,nosuid
```

#### 5. Automatic Security Updates
```bash
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

#### 6. Audit & Monitoring
```bash
# Install auditd for system-level auditing
sudo apt-get install -y auditd
sudo systemctl enable auditd

# Monitor file changes on sensitive paths
sudo auditctl -w /home/moltbot/.clawdbot/ -p rwa -k moltbot-config
sudo auditctl -w /root/.ssh/ -p rwa -k ssh-keys

# Log rotation (keep 90 days)
cat > /etc/logrotate.d/moltbot << 'LOGROTATE'
/home/moltbot/logs/*.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
}
LOGROTATE
```

#### 7. Network Monitoring
```bash
# Install intrusion detection
sudo apt-get install -y tripwire aide

# Monitor outbound connections
sudo apt-get install -y nethogs
# Run: sudo nethogs — shows which processes use bandwidth
```

#### 8. Backup Encryption
```bash
# Encrypted backup of Moltbot data
tar czf - /home/moltbot/.moltbot /home/moltbot/workspace | \
  gpg --symmetric --cipher-algo AES256 -o /backup/moltbot-$(date +%Y%m%d).tar.gz.gpg
```

#### 9. USB/Physical Port Lockdown
```bash
# Disable USB storage (prevent data exfiltration)
echo "blacklist usb-storage" | sudo tee /etc/modprobe.d/disable-usb-storage.conf
sudo update-initramfs -u

# Set BIOS/UEFI password manually
# Disable boot from USB/CD in BIOS
```

#### 10. Tailscale for Remote Access
```bash
# Zero-trust network — no open ports needed
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Access only via Tailscale IP
sudo ufw default deny incoming
sudo ufw allow in on tailscale0
```

### Security Level Comparison

| Measure | Basic | Maximum |
|---------|:-----:|:-------:|
| Gateway loopback | ✅ | ✅ |
| DM pairing | ✅ | ✅ |
| Logging | ✅ | ✅ |
| chmod 600 | ✅ | ✅ |
| Non-root container | ✅ | ✅ |
| UFW firewall | ❌ | ✅ |
| SSH key-only | ❌ | ✅ |
| Disk encryption | ❌ | ✅ |
| AppArmor | ❌ | ✅ |
| Auditd | ❌ | ✅ |
| Network monitoring | ❌ | ✅ |
| USB lockdown | ❌ | ✅ |
| Encrypted backups | ❌ | ✅ |
| VLAN isolation | ❌ | ✅ |
| Tailscale zero-trust | ❌ | ✅ |
| Auto-updates | ❌ | ✅ |

---

## ☁️ Cloud VPS (Hetzner, DigitalOcean, AWS, etc.)

Your server has a **public IP**. It's under constant attack from automated scanners.

### Threat model:
- SSH brute-force bots (thousands per day)
- Port scanners looking for open services
- API token theft if config is exposed
- Prompt injection from web content

### 🚨 Required security (do ALL of these):

#### 1. Firewall (UFW)
```bash
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
# Only allow specific ports you need:
# sudo ufw allow 443/tcp    # HTTPS if serving web
sudo ufw deny 18789/tcp     # Block gateway port externally
sudo ufw --force enable
sudo ufw status
```

#### 2. SSH Key-Only Authentication
⚠️ **Do this in order or you WILL lose access!**

```bash
# Step 1: On your LOCAL machine, generate a key (if you don't have one)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Step 2: Copy your public key to the server
ssh-copy-id user@your-server-ip
# Or manually: echo "your-public-key" >> ~/.ssh/authorized_keys

# Step 3: TEST key login from a NEW terminal (don't close the current one!)
ssh user@your-server-ip

# Step 4: Only after confirming key login works:
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo systemctl restart sshd
```

#### 3. Fail2Ban (Anti Brute-Force)
```bash
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status:
sudo fail2ban-client status sshd
```

#### 4. Automatic Security Updates
```bash
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

#### 5. Change Default SSH Port (optional, reduces noise)
```bash
# Edit /etc/ssh/sshd_config:
# Port 22  →  Port 2222  (or any port between 1024-65535)

# Update firewall:
sudo ufw allow 2222/tcp
sudo ufw delete allow OpenSSH
sudo systemctl restart sshd
```

#### 6. Remote Access via Tailscale (recommended)
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# Access via Tailscale IP only — optionally block SSH from public internet
```

---

## Moltbot-Specific Hardening

These apply to **all** scenarios:

### Vulnerability Status

| # | Vulnerability | Fix | Status |
|---|--------------|-----|--------|
| 1 | Gateway exposed on 0.0.0.0:18789 | Bind to loopback only | ✅ Default |
| 2 | DM policy allows all users | Set dmPolicy to `pairing` | ✅ Default |
| 3 | Sandbox disabled by default | Docker container isolation | ✅ Docker |
| 4 | Credentials in plaintext | Environment variables + chmod 600 | ✅ Entrypoint |
| 5 | Prompt injection via web content | Wrap untrusted content in safety tags | ⚠️ Manual |
| 6 | Dangerous commands unblocked | Block rm -rf, curl pipes, git push --force | ⚠️ AGENTS.md |
| 7 | No network isolation | Docker network with `internal: true` option | ✅ Compose |
| 8 | Elevated tool access granted | Restrict MCP tools to minimum needed | ⚠️ Manual |
| 9 | No audit logging enabled | Logging + diagnostics enabled | ✅ Default |
| 10 | Weak/default pairing codes | Pairing mode with rate limiting | ✅ Default |

### What This Docker Setup Does Automatically:
- **Gateway binds to loopback** — not exposed to the internet
- **Credentials via env vars** — never stored in plaintext config
- **Config file permissions** — chmod 600 on startup
- **Non-root user** — container runs as `moltbot` user
- **No new privileges** — `security_opt: no-new-privileges`
- **Logging enabled** — info level + diagnostics by default
- **DM pairing mode** — users must be approved before chatting

### Manual Steps Needed:
- [ ] Configure `AGENTS.md` to block dangerous commands
- [ ] Set Docker network to `internal: true` if full isolation is needed
- [ ] Review and restrict MCP tool access
- [ ] Set up prompt injection protection for web content
- [ ] Use `allowlist` dmPolicy for WhatsApp with personal number

---

## 🔍 Quick Security Audit

### Inside the container:
```bash
docker compose exec moltbot bash

# Check config permissions
stat -c '%a' ~/.clawdbot/clawdbot.json
# Expected: 600

# Check gateway binding
grep -o '"bind":"[^"]*"' ~/.clawdbot/clawdbot.json
# Expected: "bind":"lan" (required inside Docker; host is restricted to 127.0.0.1 by docker-compose)

# Check DM policy
grep -o '"dmPolicy":"[^"]*"' ~/.clawdbot/clawdbot.json
# Expected: "dmPolicy":"pairing"

# Check logging
grep -o '"level":"[^"]*"' ~/.moltbot/moltbot.json 2>/dev/null
# Expected: "level":"info"

# Run Moltbot's built-in security audit
moltbot security audit
```

### On the host (VPS only):
```bash
# Check firewall
sudo ufw status

# Check SSH config
grep "PasswordAuthentication" /etc/ssh/sshd_config

# Check fail2ban
sudo fail2ban-client status sshd

# Check open ports
ss -tlnp | grep -E '18789|22'
```

---

---

## 📁 Arquivos de Configuração — Localizações e Segurança

### Estrutura de Diretórios

**Dentro do container:**

```
/home/moltbot/
├── .clawdbot/                           # Diretório principal de configuração
│   ├── clawdbot.json                    # ⚠️ CRÍTICO - Contém tokens e configurações
│   ├── clawdbot.json.bak                # Backup automático (criado pelo doctor)
│   ├── credentials/                     # OAuth tokens, refresh tokens
│   └── agents/
│       └── main/
│           └── sessions/
│               └── sessions.json        # Sessões ativas, histórico de conversas
├── workspace/                           # Workspace do agente
│   ├── AGENTS.md                        # ⚠️ Regras de segurança do agente
│   └── projects/                        # Arquivos de projetos do usuário
└── logs/                                # Logs persistentes
    └── moltbot-YYYY-MM-DD.log          # Logs diários
```

**No host (volumes Docker):**

```bash
# Ver onde os volumes estão montados:
docker volume inspect moltbot-data

# Localização típica (Linux):
/var/lib/docker/volumes/moltbot-data/_data/

# Localização típica (Windows com WSL):
\\wsl$\docker-desktop-data\data\docker\volumes\moltbot-data\_data\
```

---

### 🔐 Arquivos Sensíveis — O Que Proteger

#### 1. **`clawdbot.json`** — Configuração Principal

**Localização:** `/home/moltbot/.clawdbot/clawdbot.json`

**Contém:**
- Gateway auth token (GATEWAY_AUTH_TOKEN)
- API keys (se configuradas diretamente no JSON)
- Configurações de canais (Telegram bot token, WhatsApp sessão)
- Preferências de modelo e routing

**Permissões:** `600` (somente owner read/write)

**Como acessar:**
```bash
# Dentro do container
docker exec moltbot cat /home/moltbot/.clawdbot/clawdbot.json

# Copiar para o host para backup
docker cp moltbot:/home/moltbot/.clawdbot/clawdbot.json ./backup-config.json
```

**⚠️ NUNCA:**
- Commitar este arquivo no git
- Enviar em canais públicos (Discord, fóruns)
- Fazer backup não-criptografado em cloud pública
- Editar manualmente (use variáveis de ambiente no `.env` quando possível)

---

#### 2. **`.env`** — Variáveis de Ambiente (Secrets)

**Localização:** `/caminho/do/repo/docker-moltbot/.env` (no host)

**Contém:**
- `ANTHROPIC_API_KEY` — Chave de API Anthropic (Claude)
- `OPENAI_API_KEY` — Chave de API OpenAI (GPT)
- `GOOGLE_API_KEY` — Chave de API Google (Gemini)
- `OPENROUTER_API_KEY` — Chave de API OpenRouter
- `GATEWAY_AUTH_TOKEN` — Token de autenticação do gateway
- `TELEGRAM_BOT_TOKEN` — Token do bot Telegram

**Permissões recomendadas:**
```bash
chmod 600 .env
```

**Proteção:**
- ✅ Já está no `.gitignore` (não vai pro GitHub)
- ✅ Não é copiado para dentro da imagem Docker
- ✅ Apenas passado como variáveis de ambiente ao container

**⚠️ CRÍTICO:**
- Se alguém tiver acesso ao `.env`, tem acesso total ao seu sistema
- Nunca compartilhe este arquivo
- Use `.env.example` como template (sem valores reais)

---

#### 3. **`credentials/`** — OAuth Tokens

**Localização:** `/home/moltbot/.clawdbot/credentials/`

**Contém:**
- Refresh tokens de OAuth (Gmail, Google Calendar, etc.)
- Access tokens temporários
- Chaves de sessão

**Permissões:** `700` (diretório), `600` (arquivos)

**Risco:** Permite acesso às suas contas conectadas (Gmail, Calendar, etc.)

---

#### 4. **`sessions.json`** — Histórico de Conversas

**Localização:** `/home/moltbot/.clawdbot/agents/main/sessions/sessions.json`

**Contém:**
- Histórico completo de mensagens
- Contexto de conversas ativas
- Memória de longo prazo do agente

**Risco Potencial:**
- Pode conter informações sensíveis discutidas com o bot
- Prompts, respostas, arquivos compartilhados

**Recomendação:**
```bash
# Habilite redação de dados sensíveis nos logs
# No clawdbot.json:
{
  "logging": {
    "redactSensitive": "tools"  # Redige argumentos de ferramentas
  }
}
```

---

#### 5. **Logs** — Trilha de Auditoria

**Localização:** `/home/moltbot/logs/*.log`

**Contém:**
- Chamadas de API (pode mostrar modelos usados)
- Erros e stack traces
- Conexões de rede (IPs, timestamps)

**Retenção padrão:** Indefinida (cresce com o tempo)

**Rotação de logs recomendada:**
```bash
# Criar /etc/logrotate.d/moltbot no host:
/var/lib/docker/volumes/moltbot-logs/_data/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
}
```

---

### 🛡️ Medidas de Proteção Automáticas

**O que o `entrypoint.sh` faz automaticamente:**

```bash
# 1. Cria diretório de config com permissões restritas
mkdir -p "$HOME/.clawdbot"

# 2. Injeta secrets via variáveis de ambiente (não texto puro no JSON)
if [ -n "$ANTHROPIC_API_KEY" ]; then
  inject_json "$CONFIG_FILE" "cfg.auth.profiles['anthropic:default'] = { provider: 'anthropic', mode: 'token' };"
fi

# 3. Define permissões seguras no arquivo de config
chmod 600 "$CONFIG_FILE"

# 4. Configura bind seguro (lan dentro do container, loopback no host)
inject_json "$CONFIG_FILE" "cfg.gateway.bind = 'lan';"
```

**O que o `docker-compose.yml` faz:**

```yaml
services:
  moltbot:
    # Porta só acessível do localhost (não de fora)
    ports:
      - "127.0.0.1:18789:18789"

    # Container roda como usuário não-root
    user: moltbot

    # Sem escalação de privilégios
    security_opt:
      - no-new-privileges:true

    # Filesystem read-only onde possível
    read_only: false  # (precisa escrever em config)
```

---

### 📋 Checklist de Segurança de Configuração

#### ✅ Nível Básico (obrigatório)
- [ ] `.env` não está commitado no git
- [ ] `.env` tem permissões `600` (`chmod 600 .env`)
- [ ] Gateway só acessível via `127.0.0.1` (não `0.0.0.0`)
- [ ] `dmPolicy` está em `pairing` ou `allowlist`
- [ ] Logging está habilitado (`level: "info"`)

#### ✅ Nível Intermediário (recomendado)
- [ ] Backup de `clawdbot.json` é criptografado
- [ ] Volumes Docker têm backup regular
- [ ] `redactSensitive: "tools"` está habilitado
- [ ] Firewall (UFW) bloqueia porta 18789 de fora
- [ ] Rotação de logs configurada

#### ✅ Nível Avançado (máxima segurança)
- [ ] Volumes Docker são encrypted-at-rest
- [ ] Disco do host tem LUKS full-disk encryption
- [ ] Acesso remoto via Tailscale (não SSH direto)
- [ ] AppArmor/SELinux habilitado no container
- [ ] Auditd monitora mudanças em arquivos de config
- [ ] Backup automático para storage criptografado off-site

---

### 🔍 Auditoria de Configuração

**Verifique se seus arquivos estão protegidos:**

```bash
# 1. Permissões do arquivo de config
docker exec moltbot stat -c '%a %U:%G %n' /home/moltbot/.clawdbot/clawdbot.json
# Esperado: 600 moltbot:moltbot

# 2. Gateway bind
docker exec moltbot cat /home/moltbot/.clawdbot/clawdbot.json | grep -o '"bind":"[^"]*"'
# Esperado: "bind":"lan"

# 3. Política de DM
docker exec moltbot cat /home/moltbot/.clawdbot/clawdbot.json | grep -o '"dmPolicy":"[^"]*"'
# Esperado: "dmPolicy":"pairing"

# 4. .env não está no git
git ls-files | grep "^.env$"
# Esperado: (saída vazia)

# 5. Porta só acessível localmente
ss -tlnp | grep 18789
# Esperado: 127.0.0.1:18789 (não 0.0.0.0:18789)

# 6. Auditoria completa
docker exec moltbot clawdbot security audit
```

---

### 💾 Backup Seguro de Configuração

**Backup manual (criptografado):**

```bash
# 1. Backup dos volumes Docker (criptografado)
docker run --rm \
  -v moltbot-data:/data \
  -v $(pwd):/backup \
  alpine tar czf - /data | \
  gpg --symmetric --cipher-algo AES256 -o /backup/moltbot-data-$(date +%Y%m%d).tar.gz.gpg

# 2. Backup do .env (criptografado)
gpg --symmetric --cipher-algo AES256 .env -o .env.backup.gpg

# 3. Armazenar em local seguro off-site
# - Cloud com criptografia (S3 + KMS, etc.)
# - Disco externo criptografado
# - NUNCA armazenar não-criptografado em Dropbox, Google Drive público, etc.
```

**Restauração:**

```bash
# 1. Descriptografar backup
gpg -d moltbot-data-20260128.tar.gz.gpg | docker run --rm -i \
  -v moltbot-data:/data \
  alpine tar xzf - -C /

# 2. Reiniciar container
docker compose restart
```

---

### ⚠️ O Que NUNCA Fazer

❌ **NUNCA commite `.env` no git**
```bash
# Se acidentalmente commitou:
git rm --cached .env
git commit -m "Remove .env from repo"
git push

# E revogue todas as API keys imediatamente!
```

❌ **NUNCA edite `clawdbot.json` manualmente**
- Use variáveis de ambiente no `.env` quando possível
- Use `clawdbot doctor --fix` para correções automáticas
- Se precisar editar, faça backup primeiro

❌ **NUNCA exponha a porta 18789 publicamente**
```yaml
# ERRADO:
ports:
  - "0.0.0.0:18789:18789"  # ❌ Exposto ao mundo

# CERTO:
ports:
  - "127.0.0.1:18789:18789"  # ✅ Só local
```

❌ **NUNCA desabilite logging para "performance"**
- Logging é sua trilha de auditoria
- Essencial para investigar incidentes
- Use `redactSensitive` se preocupado com privacidade

❌ **NUNCA rode o container como root**
```yaml
# ERRADO:
user: root  # ❌ Risco de segurança

# CERTO:
user: moltbot  # ✅ Não-root (já é o padrão)
```

---

## 📚 Resources

- [Moltbot Documentation](https://docs.molt.bot)
- [Moltbot Website](https://molt.bot)
- [Discord Community](https://discord.gg/clawd)
- [GitHub](https://github.com/moltbot/moltbot)
