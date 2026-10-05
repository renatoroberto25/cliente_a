#!/usr/bin/env bash

echo "[220] Garantir que apenas um sistema de log esteja em uso (journald OU rsyslog)"

# Assume-se uso exclusivo do journald — rsyslog será desabilitado se estiver presente

if rpm -q rsyslog &>/dev/null; then
  echo "🔎 rsyslog está instalado."

  # Desabilita rsyslog se estiver habilitado
  if systemctl is-enabled rsyslog &>/dev/null; then
    echo "⚠️ rsyslog está habilitado — desabilitando..."
    systemctl disable --now rsyslog && echo "✅ rsyslog desabilitado com sucesso." || echo "❌ Falha ao desabilitar rsyslog"
  else
    echo "✅ rsyslog já está desabilitado."
  fi
else
  echo "✅ rsyslog não está instalado."
fi

# Garante que journald está ativo e habilitado
if systemctl is-enabled systemd-journald &>/dev/null; then
  echo "✅ systemd-journald está habilitado."
else
  echo "⚠️ systemd-journald não estava habilitado — habilitando..."
  systemctl enable --now systemd-journald && echo "✅ systemd-journald habilitado com sucesso." || echo "❌ Falha ao habilitar systemd-journald"
fi

echo "✅ Remediação concluída"
exit 0