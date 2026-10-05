#!/usr/bin/env bash

echo -e "[10 - 35] Verifica se partições críticas estão montadas com as opções seguras\n"

# Lista de partições no formato: "ponto:descricao:espera_separada:opcoes"
PARTICOES=(
  "/tmp:10:no:nodev,nosuid,noexec"
  "/dev/shm:11:no:nodev,nosuid,noexec"
  "/home:12:yes:nodev"
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

    echo -e "\n💡 Sugestão: verifique e edite o arquivo /etc/fstab para garantir persistência das opções após reboot."
    echo "Exemplo:"
    echo "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0"
fi

exit 0