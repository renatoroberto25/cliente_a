#!/usr/bin/env bash
echo "[216] Restaurar permissões e ownership conforme RPM database"

# Cria log para análise
DATA=$(date +%Y%m%d%H%M%S)
LOG="/tmp/rpm_verify_diff_$DATA.log"

# Verifica divergências e salva
rpm -Va --nomtime --nosize --nomd5 --nolinkto | grep -vw c > "$LOG"

if [ ! -s "$LOG" ]; then
  echo "✅ Nenhuma divergência encontrada"
else
  echo "⚠️ Divergências detectadas — restaurando metadados"
  echo "Arquivo de log: $LOG"

  # Restaura permissões e ownership conforme RPM database
  #rpm --setperms $(rpm -qa) 2>&1 | grep -v "No such file or directory"
  #rpm --setugids $(rpm -qa) 2>&1 | grep -v "No such file or directory"
  rpm --setperms $(rpm -qa | grep -Ev 'sudo|shadow-utils|util-linux|coreutils')
  rpm --setugids $(rpm -qa | grep -Ev 'sudo|shadow-utils|util-linux|coreutils')



  echo "✔ Permissões e ownership restaurados para pacotes instalados"
fi
echo "[ℹ️ FIM]"