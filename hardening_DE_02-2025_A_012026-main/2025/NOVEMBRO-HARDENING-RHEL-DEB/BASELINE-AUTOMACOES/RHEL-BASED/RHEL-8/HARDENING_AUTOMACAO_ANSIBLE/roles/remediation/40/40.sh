#!/usr/bin/env bash
echo "[40] Remediação: Configurar senha no bootloader (grub2 user.cfg)"

cfg_file="/boot/grub2/user.cfg"

if [ ! -f "$cfg_file" ]; then
  echo "- Arquivo não encontrado: $cfg_file"
  echo "- É necessário executar manualmente o comando abaixo para gerar a senha:"
  echo "    grub2-setpassword"
  echo "- Após isso, valide se a linha GRUB2_PASSWORD=... foi criada nesse arquivo."
  return 0 2>/dev/null || exit 0
fi

if grep -Eq '^\s*GRUB2_PASSWORD=grub\.pbkdf2\.sha512' "$cfg_file"; then
  echo "Senha já está configurada corretamente no GRUB."
else
  echo "⚠ Nenhuma senha detectada no arquivo $cfg_file."
  echo "- Execute manualmente:"
  echo "    grub2-setpassword"
  echo "- Depois valide se a linha GRUB2_PASSWORD=... foi criada."
fi
