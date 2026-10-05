#!/usr/bin/env bash
# [10 - 35] Verifica se partições críticas e adicionais estão montadas com as opções seguras
# Compatível com Servidores baseados em RHEL 7, 8, 9

echo -e "[10 - 35] Verificação das opções de montagem em partições críticas e adicionais\n"

# Lista de partições no formato: "ponto:descricao:espera_separada:opcoes"
PARTICOES=(
  "/:0:no:defaults"
  "/boot:0:no:defaults,nodev"
  "/UNIX:0:yes:nodev,nosuid,noexec"
  "/crash:0:yes:nodev,nosuid,noexec"
  "/historico:0:yes:nodev,nosuid,noexec"
  "/opt:0:no:defaults"
  "/usr:0:no:defaults"
  "/swap:0:no:defaults"
  "/tmp:10:no:nodev,nosuid,noexec"
  "/dev/shm:11:no:nodev,nosuid,noexec"
  "/home:12:yes:nodev,nosuid"
  "/var:13:yes:nodev,nosuid"
  "/var/tmp:14:yes:nodev,nosuid,noexec"
  "/var/log:15:yes:nodev,nosuid,noexec"
  "/var/log/audit:16:yes:nodev,nosuid,noexec"
)

FALHAS=()

auditar_particao() {
    local ponto="$1"
    local descricao="$2"
    local espera_separada="$3"
    local opcoes="$4"

    echo "🔹 [$descricao.1] Verificando '$ponto'..."

    # Verifica se o ponto existe no fstab
    if ! grep -qE "^[^#].*\s+$ponto\s+" /etc/fstab; then
        echo "   ⚠️  $ponto não definido no /etc/fstab"
        FALHAS+=("$ponto - ausência de entrada no fstab")
        echo ""
        return
    fi

    # Verifica se está montado separadamente
    if findmnt -kn "$ponto" >/dev/null 2>&1; then
        if [ "$espera_separada" = "yes" ]; then
            echo "   ✅ Montado separadamente"
        else
            echo "   ✅ Montado (pode estar na raiz)"
        fi
    else
        if [ "$espera_separada" = "yes" ]; then
            echo "   ❌ Não está em partição separada"
            FALHAS+=("$ponto - não está separado conforme baseline")
        else
            echo "   ⚠️ Pode estar na raiz (aceitável)"
        fi
    fi

    # Para partições defaults, só valida montagem
    if [[ "$opcoes" == "defaults" ]]; then
        echo "   ✅ $ponto usa opções padrão (defaults)"
        echo ""
        return
    fi

    # Verifica opções de montagem ativas
    local mountinfo
    mountinfo=$(findmnt -n -o OPTIONS --target "$ponto" 2>/dev/null)
    echo "   ↳ Opções atuais: ${mountinfo:-(não montado)}"

    local i=2
    for opt in ${opcoes//,/ }; do
        echo "🔸 [$descricao.$i] Verificando opção '$opt'..."
        if grep -qw "$opt" <<< "$mountinfo"; then
            echo "   ✅ '$opt' presente"
        else
            echo "   ❌ '$opt' ausente"
            FALHAS+=("$ponto - opção '$opt' ausente ($descricao)")
        fi
        ((i++))
    done
    echo ""
}

# Loop principal
for entrada in "${PARTICOES[@]}"; do
    IFS=':' read -r ponto desc separada opcoes <<< "$entrada"
    auditar_particao "$ponto" "$desc" "$separada" "$opcoes"
done

# Resultado final
if [ ${#FALHAS[@]} -eq 0 ]; then
    echo -e "✅ Todas as partições estão configuradas corretamente conforme baseline HITSS.\n"
else
    echo -e "⚠️  Foram encontradas falhas nas seguintes partições:\n"
    for falha in "${FALHAS[@]}"; do
        echo "❗ $falha"
    done
    echo -e "\n💡 Sugestão: verifique e edite o arquivo /etc/fstab para garantir persistência das opções após reboot."
    echo "Exemplo:"
    echo "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0"
fi

exit 0