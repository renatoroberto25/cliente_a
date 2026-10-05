#!/usr/bin/env bash
# [107] Remediação: garantir que 'at' esteja restrito a usuários autorizados (executa apenas se cron NÃO existir e at estiver instalado)
TS="$(date +%F_%H%M%S)"
echo -e "\n[107] Remediação: garantir que 'at' esteja restrito a usuários autorizados (aplica apenas se cron NÃO existir e at instalado)"

# Helpers
ok(){ printf '✅ %s\n' "$1"; }
warn(){ printf '⚠️ %s\n' "$1"; }

# Se cron estiver presente, não aplicamos (controle não aplicável)
if systemctl list-unit-files | grep -q '^cron.service'; then
  ok "cron presente — controle 107 não aplicável"
  exit 0
fi

# Se at não instalado, nada a fazer
if ! command -v at >/dev/null 2>&1; then
  ok "at não está instalado — nada a fazer"
  exit 0
fi

# Auditoria prévia
if [ -f /etc/at.allow ] && stat -Lc "%a %U %G" /etc/at.allow 2>/dev/null | grep -Eq '^600 root root$'; then
  ok "/etc/at.allow existe com permissões 600 root:root — nada a fazer"
  exit 0
fi

# Remediação: se /etc/at.allow existe, somente ajustar owner/perm (faz backup)
if [ -f /etc/at.allow ]; then
  cp -a /etc/at.allow "/etc/at.allow.bak_${TS}" 2>/dev/null && warn "Backup criado: /etc/at.allow.bak_${TS}"
  chown root:root /etc/at.allow 2>/dev/null || warn "chown falhou em /etc/at.allow"
  chmod 600 /etc/at.allow 2>/dev/null || warn "chmod falhou em /etc/at.allow"
  ok "Ajustadas owner/perms em /etc/at.allow"
  exit 0
fi

# Se não existe, criar um arquivo conservador contendo apenas 'root' (apenas usuários autorizados)
warn "/etc/at.allow ausente — criando com entrada 'root' (backup não necessário)"
printf 'root\n' > /etc/at.allow 2>/dev/null || { echo "⚠️ Falha ao criar /etc/at.allow"; exit 1; }
chown root:root /etc/at.allow 2>/dev/null || warn "chown falhou em /etc/at.allow"
chmod 600 /etc/at.allow 2>/dev/null || warn "chmod falhou em /etc/at.allow"
ok "/etc/at.allow criado com permissões 600 root:root e conteúdo conservador (root)"

# Opcional: informar sobre /etc/at.deny (não removemos automaticamente)
if [ -f /etc/at.deny ]; then
  warn "/etc/at.deny existe — quando /etc/at.allow existe, /etc/at.deny é ignorado. Mantenha/remoção: manual."
fi

exit 0