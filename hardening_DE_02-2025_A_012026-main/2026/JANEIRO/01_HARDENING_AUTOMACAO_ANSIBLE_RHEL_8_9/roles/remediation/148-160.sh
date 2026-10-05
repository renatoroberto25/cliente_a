#!/usr/bin/env bash

# Função para backup com timestamp
backup_file() {
    [ -f "$1" ] && cp "$1" "$1.bak_$(date +%F-%H%M%S)"
}

echo "=== Iniciando remediação HITSS 148–160 (RHEL 8/9) ==="

########################################
# 148 – root único UID 0
#A Red Hat nunca altera UID de contas do sistema dessa forma pois:
#- quebras de permissões
#- falha de serviços
#- inconsistência entre FS, ACLs, journald, selinux contexts.
#- UID 999 pode colidir com contas de sistema
#- Em RHEL 8/9 quase nenhum serviço usa UID 0
#→ Este controle deve ser APENAS AUDITADO, nunca remediado.
########################################


########################################
# 149 – root único GID 0
########################################
echo -e "\n[149] root único GID 0"
ROOT_GID=$(awk -F: '/^root:/ {print $4}' /etc/passwd)
if [ "$ROOT_GID" != "0" ]; then
    backup_file /etc/passwd
    usermod -g 0 root
    echo "✔ GID do root corrigido para 0"
else
    echo "✔ root já possui GID 0"
fi


########################################
# 150 – Contas de sistema travadas (<1000)
# *** CORREÇÃO IMPORTANTE ***
# Em RHEL 8/9 não se pode travar todas as contas <1000.
# Isso quebra: polkitd, qemu, libvirt, saslauthd, postfix, apache etc.
#
# Solução HITSS: travar SOMENTE contas interativas.
# Critério seguro:
# - UID < 1000
# - shell é /bin/bash, /bin/sh ou /bin/zsh
########################################
echo -e "\n[150] travar contas de sistema seguras (<1000)"

for u in $(awk -F: '$3<1000 && $1!="root" && $7 ~ /(bash|sh|zsh)$/ {print $1}' /etc/passwd); do
    echo "→ Trocando shell para nologin: $u"
    backup_file /etc/passwd
    usermod -s /sbin/nologin "$u"
done
echo "✔ Contas de sistema interativas convertidas para nologin"


########################################
# 151 – NÃO remover /sbin/nologin de /etc/shells
# RHEL 8/9 exige este caminho no /etc/shells
########################################
echo -e "\n[151] Preservando /sbin/nologin no /etc/shells (comportamento correto)"
echo "✔ Nenhuma ação realizada (RHEL 8/9)"


########################################
# 152 – PATH do root
########################################
echo -e "\n[152] ajustando PATH do root"
SAFE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

backup_file /root/.bash_profile
if grep -q '^PATH=' /root/.bash_profile; then
    sed -i "s|^PATH=.*|PATH=$SAFE_PATH|" /root/.bash_profile
else
    echo "PATH=$SAFE_PATH" >> /root/.bash_profile
fi

echo "✔ PATH do root ajustado"


########################################
# 153 – umask = 027
########################################
echo -e "\n[153] ajustando umask"

FILES="/etc/profile /etc/bashrc /etc/profile.d/*.sh"

for f in $FILES; do
    [ -f "$f" ] || continue
    backup_file "$f"

    # Remove linhas antigas de umask
    sed -i '/^umask/d' "$f"

    # Insere linha segura no final
    echo "umask 027" >> "$f"
done

echo "✔ umask definido como 027"


########################################
# 154 – TMOUT ≥ 900
########################################
echo -e "\n[154] ajustando TMOUT"

for f in $FILES; do
    [ -f "$f" ] || continue
    backup_file "$f"

    sed -i '/^TMOUT/d' "$f"
    echo "TMOUT=900" >> "$f"
done

echo "✔ TMOUT configurado para 900"


########################################
# 155–159 – Ajustes seguros no sudoers
# *** IMPORTANTE ***
# A Red Hat recomenda NÃO editar /etc/sudoers com sed.
# O correto é usar ARQUIVO DEDICADO EM /etc/sudoers.d/
########################################

SUDO_HARD="/etc/sudoers.d/hardening-hitss"
backup_file "$SUDO_HARD"

echo -e "\n[155–159] aplicando ajustes de sudo em arquivo dedicado"

cat > "$SUDO_HARD" <<EOF
# Arquivo de hardening HITSS – não editar diretamente

# [155] remover regras amplas
# Nenhuma regra %grupo ALL=(ALL) deve existir neste arquivo.

# [156] sudo usa pty
Defaults use_pty

# [157] comando de log
Defaults logfile="/var/log/sudo.log"

# [159] timeout do timestamp
Defaults timestamp_timeout=5
EOF

chmod 440 "$SUDO_HARD"

if visudo -cf "$SUDO_HARD" >/dev/null 2>&1; then
    echo "✔ sudoers.d/hardening-hitss criado com sucesso"
else
    echo "⚠ ERRO NO SUDOERS! Restaurar backup!"
fi


########################################
# 160 – su restrito ao grupo wheel
########################################
echo -e "\n[160] restringindo su ao grupo wheel"

if ! grep -Eq '^auth\s+(required|requisite)\s+pam_wheel\.so' /etc/pam.d/su; then
    backup_file /etc/pam.d/su
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su
    echo "✔ pam_wheel ativado"
else
    echo "✔ pam_wheel já configurado"
fi

echo "=== Remediação concluída ==="
