@echo off
echo === Removendo volumes antigos (pode conter config de Anthropic) ===
docker compose down -v

echo.
echo === Reconstruindo imagem do zero ===
docker compose build --no-cache

echo.
echo === Iniciando container com OpenRouter ===
docker compose up -d

echo.
echo === Aguardando 10 segundos para inicializacao ===
timeout /t 10 /nobreak

echo.
echo === Verificando logs de inicializacao ===
docker compose logs --tail 30

echo.
echo === Verificando configuracao gerada ===
docker compose exec moltbot cat ~/.clawdbot/clawdbot.json

echo.
echo === Status do gateway ===
docker compose exec moltbot clawdbot status

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║  ✅ Se tudo estiver OK, acesse:                          ║
echo ║  🌐 http://localhost:18789/chat                          ║
echo ║  🔑 Token: bb2773e2eca86687652407dfa8b94b9b3f57963d68ded695  ║
echo ╚══════════════════════════════════════════════════════════╝
pause
