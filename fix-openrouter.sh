#!/bin/bash
# Script para verificar e corrigir configuração OpenRouter

echo "=== Removendo volumes antigos (pode conter config de Anthropic) ==="
docker compose down -v

echo ""
echo "=== Reconstruindo imagem do zero ==="
docker compose build --no-cache

echo ""
echo "=== Iniciando container com OpenRouter ==="
docker compose up -d

echo ""
echo "=== Aguardando 10 segundos para inicialização ==="
sleep 10

echo ""
echo "=== Verificando configuração gerada ==="
docker compose exec moltbot cat ~/.clawdbot/clawdbot.json | grep -A 5 '"auth"'

echo ""
echo "=== Verificando logs de inicialização ==="
docker compose logs --tail 30

echo ""
echo "=== Status do gateway ==="
docker compose exec moltbot clawdbot status

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅ Se tudo estiver OK, acesse:                          ║"
echo "║  🌐 http://localhost:18789/chat                          ║"
echo "║  🔑 Token: bb2773e2eca86687652407dfa8b94b9b3f57963d68ded695  ║"
echo "╚══════════════════════════════════════════════════════════╝"
