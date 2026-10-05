#!/usr/bin/env bash
echo "[1 - 9] Remediação de módulos do kernel de sistemas de arquivos"
MODULOS=("cramfs" "freevxfs" "hfs" "hfsplus" "jffs2" "overlay" "squashfs" "udf" "usb-storage")

for mod in "${MODULOS[@]}"; do
    echo "[$mod] Aplicando remediação"
    if modinfo "$mod" &>/dev/null; then
        # Criar regra para bloquear carregamento
        CONF="/etc/modprobe.d/${mod}.conf"
        if ! grep -q "install $mod /bin/true" "$CONF" 2>/dev/null; then
            cp "$CONF" "$CONF.bak_$(date +%F_%H%M)" 2>/dev/null
            echo "install $mod /bin/true" > "$CONF"
        fi
        # Remover se estiver carregado
        lsmod | grep -q "$mod" && rmmod "$mod" 2>/dev/null
        echo "   ✅ Remediado"
    else
        echo "   ✅ Módulo não existe no kernel"
    fi
done