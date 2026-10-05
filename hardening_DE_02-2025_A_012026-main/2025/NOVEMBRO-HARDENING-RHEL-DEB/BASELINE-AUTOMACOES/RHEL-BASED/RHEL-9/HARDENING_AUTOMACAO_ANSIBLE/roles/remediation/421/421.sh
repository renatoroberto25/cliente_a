#!/usr/bin/env bash
echo -e "\n[137] Remediação – firewalld: Remover serviços e portas desnecessários"

echo "[✅ SUCESSO]: Esta remediação é educativa – siga as instruções abaixo para ajustar sua política local."

echo -e "\n🔹 Para remover um serviço:"
echo "   firewall-cmd --remove-service=<servico>"
echo "   EXEMPLO: firewall-cmd --remove-service=cockpit"

echo -e "\n🔹 Para remover uma porta:"
echo "   firewall-cmd --remove-port=<porta>/<protocolo>"
echo "   EXEMPLO: firewall-cmd --remove-port=25/tcp"

echo -e "\n🔹 Para tornar as mudanças permanentes:"
echo "   firewall-cmd --runtime-to-permanent"

echo -e "\n❗ Verifique quais serviços/portas estão ativos com:"
echo "   firewall-cmd --list-all"