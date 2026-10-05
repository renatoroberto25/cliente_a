#!/usr/bin/env bash

echo "Para configurar uma senha no bootloader GRUB2, utilize o seguinte comando:"
echo "  grub2-setpassword"
echo ""
echo "Isso criará um arquivo de senha seguro para proteger as configurações do GRUB."
echo ""
echo "Alternativamente, você pode editar manualmente o arquivo de configuração adicionando um usuário e senha:"
echo "  1. Execute: grub-mkpasswd-pbkdf2"
echo "  2. Copie o hash gerado."
echo "  3. Adicione ao arquivo /etc/grub.d/40_custom:"
echo '     set superusers="admin"'
echo '     password_pbkdf2 admin <HASH_GERADO>'
echo "  4. Atualize o GRUB com: grub2-mkconfig -o /boot/grub2/grub.cfg"
echo ""
echo "Isso garantirá que apenas usuários autorizados possam editar as configurações do bootloader."
