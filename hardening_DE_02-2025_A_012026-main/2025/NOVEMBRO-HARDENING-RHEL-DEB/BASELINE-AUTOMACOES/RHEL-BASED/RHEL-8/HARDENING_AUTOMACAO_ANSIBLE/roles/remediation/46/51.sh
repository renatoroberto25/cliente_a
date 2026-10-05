#!/usr/bin/env bash
echo "[51-53] Remediações complementares SELINUX: Serviços confinados, mctrans e setroubleshoot"

# 51 - Serviços não confinados
echo "[51] Verificar se há serviços rodando com contexto unconfined"
if ps -eZ | grep -q 'unconfined_service_t'; then
  echo "⚠️ Serviços com contexto 'unconfined_service_t' encontrados."
  echo "Remoção ou reconfiguração deve ser feita manualmente após análise:"
  ps -eZ | grep 'unconfined_service_t'
else
  echo "Nenhum serviço não confinado encontrado"
fi

# 52 - Desabilitar e parar mcstrans
echo "[52] Verificar se o serviço mcstrans está habilitado"
if systemctl is-enabled mcstrans.service &>/dev/null; then
  echo "⚠️ mcstrans está habilitado — desabilitando..."
  systemctl disable --now mcstrans.service
else
  echo "mcstrans já está desabilitado"
fi

# 53 - Remover setroubleshoot se instalado
echo "[53] Verificar se o pacote setroubleshoot está instalado"
if rpm -q setroubleshoot &>/dev/null; then
  echo "⚠️ setroubleshoot instalado — removendo..."
  dnf remove -y setroubleshoot
else
  echo "setroubleshoot não está instalado"
fi