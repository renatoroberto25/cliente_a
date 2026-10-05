#!/usr/bin/env bash

echo -e "[9 - 34] Verificação das opções de montagem em partições críticas\n"

# Formato: ponto:numero_inicial:exige_separada:opcoes
PARTICOES=(
  "/tmp:9:no:nodev,nosuid,noexec"
  "/dev/shm:13:no:nodev,nosuid,noexec"
  "/home:17:yes:nodev,nosuid"
  "/var:20:yes:nodev,nosuid"
  "/var/tmp:23:yes:nodev,nosuid,noexec"
  "/var/log:27:yes:nodev,nosuid,noexec"
  "/var/log/audit:31:yes:nodev,nosuid,noexec"
)

FALHAS=()

auditar_particao() {
    local ponto="$1"
    local descricao="$2"
    local espera_separada="$3"
    local opcoes="$4"

    echo "🔹 [$descricao.1] Verificando se '$ponto' é uma partição separada..."
    if findmnt -kn "$ponto" > /dev/null; then
        echo "   ✅ Montado separadamente"
    else
        if [ "$espera_separada" = "yes" ]; then
            echo "   ❌ Não está em partição separada"
            FALHAS+=("$ponto - não está separado conforme $descricao")
        else
            echo "   ⚠️ Pode estar na raiz (aceitável)"
        fi
    fi

    local i=2
    local mountinfo
    mountinfo=$(findmnt -n -o OPTIONS --target "$ponto" 2>/dev/null)

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
}

# Loop principal
for entrada in "${PARTICOES[@]}"; do
    IFS=':' read -r ponto desc separada opcoes <<< "$entrada"
    auditar_particao "$ponto" "$desc" "$separada" "$opcoes"
    echo ""
done

# Resultado final
if [ ${#FALHAS[@]} -eq 0 ]; then
    echo -e "✅ Todas as partições estão configuradas corretamente conforme Hitss Benchmark.\n"
else
    echo -e "⚠️  Foram encontradas falhas nas seguintes partições:\n"
    for falha in "${FALHAS[@]}"; do
        echo "❗ $falha"
    done

    echo -e "\nNota: verifique e edite o arquivo /etc/fstab para garantir persistência das opções após reboot."
    echo "Exemplo:"
    echo -e "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0 \n"
fi

exit 0