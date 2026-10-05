#!/usr/bin/env bash
echo "[54 - 57] Políticas de criptografia, remoção de algoritmos fracos"

# 54 - Corrigir se LEGACY estiver definida
echo "[54] Verificando política ativa"
if grep -q '^LEGACY$' /etc/crypto-policies/config; then
  echo "⚠️ Política LEGACY detectada. Corrigindo para DEFAULT..."
  cp -p /etc/crypto-policies/config /etc/crypto-policies/config.bak_$(date +%F_%H-%M-%S)
  update-crypto-policies --set DEFAULT
  echo "✅ Política atualizada para DEFAULT"
else
  echo "✅ Já está em conformidade"
fi

# 55 a 57 - Reaplicar política DEFAULT se houver algoritmos fracos
arquivo="/etc/crypto-policies/state/CURRENT.pol"
echo "[55 - 57] Verificando presença de algoritmos fracos (SHA1, CBC, MACs 64 bits)"
if grep -Pi 'sha1|cbc|hmac|mac.*-64' "$arquivo" &>/dev/null; then
  echo "⚠️ Algoritmos fracos detectados. Reaplicando política DEFAULT..."
  update-crypto-policies --set DEFAULT
  echo "✅ Política DEFAULT reaplicada"
else
  echo "✅ Já está em conformidade"
fi