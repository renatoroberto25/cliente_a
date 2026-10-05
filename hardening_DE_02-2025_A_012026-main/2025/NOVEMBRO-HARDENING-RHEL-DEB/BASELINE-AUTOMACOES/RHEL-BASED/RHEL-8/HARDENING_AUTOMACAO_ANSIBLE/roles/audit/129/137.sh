#!/usr/bin/env bash
echo "[137] - Verifique se o uso do 'at' está restrito a usuários autorizados"

# Verifica se o at está instalado
if ! rpm -q at &>/dev/null; then
  echo "✅ at não está instalado — item não se aplica"
  exit 0
fi

echo "Pacote 'at' instalado — verificando arquivos de controle"

# Verifica at.allow
echo -e "\n Verificando /etc/at.allow"
if [ -e /etc/at.allow ]; then
  perms=$(stat -c "%a" /etc/at.allow)
  owner=$(stat -c "%U" /etc/at.allow)
  group=$(stat -c "%G" /etc/at.allow)

  if [[ "$perms" -le 640 && "$owner" == "root" && ("$group" == "root" || "$group" == "daemon") ]]; then
    echo "✅ /etc/at.allow em conformidade"
  else
    echo "⚠️ /etc/at.allow fora do padrão esperado"
  fi
else
  echo "⚠️ /etc/at.allow não encontrado"
fi

# Verifica at.deny
echo -e "\n Verificando /etc/at.deny"
if [ -e /etc/at.deny ]; then
  perms=$(stat -c "%a" /etc/at.deny)
  owner=$(stat -c "%U" /etc/at.deny)
  group=$(stat -c "%G" /etc/at.deny)

  if [[ "$perms" -le 640 && "$owner" == "root" && ("$group" == "root" || "$group" == "daemon") ]]; then
    echo "✅ /etc/at.deny em conformidade"
  else
    echo "⚠️ /etc/at.deny fora do padrão esperado"
  fi
else
  echo "✅ /etc/at.deny ausente — permitido"
fi