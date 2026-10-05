#!/usr/bin/env bash
echo "[69 - 73] Verificar parâmetros avançados do GDM (se aplicável)"

arquivo="/etc/dconf/db/gdm.d/00-security-settings"

if [ -f "$arquivo" ]; then
  echo "✓ Arquivo detectado: $arquivo"

  grep -q '^automount=false' "$arquivo" && echo "✅ [69] automount=false" || echo "⚠️ [69] automount não desabilitado"
  grep -q '^automount-open=false' "$arquivo" && echo "✅ [70] automount-open=false" || echo "⚠️ [70] automount-open não desabilitado"
  grep -q '^autorun-never=true' "$arquivo" && echo "✅ [71] autorun-never=true" || echo "⚠️ [71] autorun-never ausente"
  grep -q '^\[org/gnome/desktop/media-handling\]' "$arquivo" && echo "✅ [72] seção autorun detectada" || echo "⚠️ [72] seção autorun ausente"
  grep -q '^Enable=false' /etc/gdm/custom.conf 2>/dev/null && echo "✅ [73] XDMCP desabilitado" || echo "⚠️ [73] XDMCP pode estar habilitado"

else
  echo "ℹ️ GDM não detectado neste host. Nenhuma ação necessária para 69–73."
fi
exit 0