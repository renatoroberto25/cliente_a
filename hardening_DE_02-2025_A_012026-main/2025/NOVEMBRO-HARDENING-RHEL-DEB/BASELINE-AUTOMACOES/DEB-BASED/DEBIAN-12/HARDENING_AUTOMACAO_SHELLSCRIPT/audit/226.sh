#!/usr/bin/env bash

echo -e "\n[226] Verifique se o serviço journald está ativo"
( systemctl is-active --quiet systemd-journald.service && \
  systemctl is-enabled systemd-journald.service 2>/dev/null | grep -q 'static' ) \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[227] Verifique se o acesso aos arquivos de log do journald está configurado"
stat -Lc '%a' /var/log/journal/*/*.journal 2>/dev/null \
 | awk '{if ($1+0 > 640) exit 1} END{exit 0}' \
 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[228] Verifique se a rotação de logs do journald está configurada"
grep -Psi '^\s*(SystemMaxUse|SystemKeepFree|RuntimeMaxUse|RuntimeKeepFree|MaxFileSec)=' \
  /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null \
  | grep -q . && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[229] Verifique se apenas um sistema de logging está em uso"
if systemctl is-active --quiet rsyslog && systemctl is-active --quiet systemd-journald; then
  echo "⚠️ REPROVADO (journald é sempre ativo; rsyslog também está ativo → escolha apenas um)"
elif systemctl is-active --quiet rsyslog; then
  echo "✅ APROVADO (journald ativo por padrão, rsyslog definido como único gerenciador)"
elif systemctl is-active --quiet systemd-journald; then
  echo "✅ APROVADO (apenas journald em uso)"
else
  echo "⚠️ REPROVADO (nenhum sistema de logging detectado)"
fi

echo -e "\n[230] Verifique se o pacote systemd-journal-remote está instalado"
dpkg-query -s systemd-journal-remote &>/dev/null \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[231] Verifique se a autenticação do journal-upload está configurada"
grep -Psi '^\s*(URL|ServerKeyFile|ServerCertificateFile|TrustedCertificateFile)=' \
  /etc/systemd/journal-upload.conf /etc/systemd/journal-upload.conf.d/*.conf 2>/dev/null \
  | grep -q . && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[232] Verifique se o serviço systemd-journal-upload está habilitado e ativo"
( systemctl is-enabled --quiet systemd-journal-upload.service 2>/dev/null \
  && systemctl is-active --quiet systemd-journal-upload.service 2>/dev/null ) \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[233] Verifique se o systemd-journal-remote não está em uso"
( ! systemctl is-enabled --quiet systemd-journal-remote.socket 2>/dev/null \
  && ! systemctl is-enabled --quiet systemd-journal-remote.service 2>/dev/null \
  && ! systemctl is-active --quiet systemd-journal-remote.socket 2>/dev/null \
  && ! systemctl is-active --quiet systemd-journal-remote.service 2>/dev/null ) \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[234] Verifique se ForwardToSyslog está desabilitado (quando só journald é usado)"
grep -Psi '^\s*ForwardToSyslog=no\b' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null \
  | grep -q . && echo "✅ APROVADO (journald não encaminha logs para rsyslog)" || echo "⚠️ REPROVADO (journald ainda encaminha para rsyslog)"

echo -e "\n[235] Verifique se Compress está configurado"
grep -Psi '^\s*Compress=yes\b' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null \
  | grep -q . && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[236] Verifique se Storage está configurado como persistente"
grep -Psi '^\s*Storage=persistent\b' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null \
  | grep -q . && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

exit 0