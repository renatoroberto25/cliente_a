# Hardening HITSS — RHEL 7, 8 e 9

Automação de auditoria e remediação baseada no baseline RHEL 1.3.5.
Compatível com RHEL e derivados, incluindo Oracle Linux 7, 8 e 9.

O auditor verifica 174 controles. A remediação trata apenas o que pode ser
aplicado de forma genérica e segura; itens dependentes do papel do servidor são
marcados como `SKIP` e exigem decisão técnica.

## Resultado esperado

Em laboratório com Oracle Linux 7, 8 e 9, a aderência após a remediação ficou
entre 79% e 82%. Esse resultado é referência, não garantia: cada ambiente deve
ser validado e a automação adaptada aos seus perfis antes da expansão.

## Uso

```bash
./executor.sh audit
sudo ./executor.sh remed
sudo ./executor.sh full
./executor.sh report
./executor.sh status
sudo ./executor.sh rollback
```

Sem argumentos, `./executor.sh` abre o menu interativo.

- `audit`: verifica os 174 controles sem alterar o sistema;
- `remed`: cria snapshot e executa as remediações;
- `full`: executa audit, remediação e novo audit;
- `report`: lista as falhas do último audit;
- `status`: mostra o resumo do último audit;
- `rollback`: restaura o snapshot mais recente.

A remediação exige `root`. O audit também deve ser executado como `root` para
produzir resultados completos. Logs e snapshots ficam em `logs/`.

## Antes de aplicar

1. Selecione um servidor de teste representativo do perfil.
2. Garanta snapshot/backup e acesso por console.
3. Execute o audit e revise os `FAIL`.
4. Adapte exceções de SSH, sudo, PAM, serviços e rede ao ambiente.
5. Execute a remediação em janela controlada e audite novamente.

Não aplique a automação indiscriminadamente em produção.

## O que não é automatizado de forma genérica

- criação ou redimensionamento de partições;
- decisões sobre serviços, pacotes, IPv6, forwarding e contêineres;
- allowlists de SSH, sudo e contas;
- mudanças de PAM sem perfil previamente validado;
- remoção de SUID/SGID sem análise do sistema;
- alterações criptográficas sem teste das integrações.

## Rollback

Antes de `remed` e `full`, o executor cria um snapshot dos arquivos gerenciados.
O rollback restaura esses arquivos, mas não desfaz automaticamente estado de
serviços, valores já carregados no kernel ou regras de auditoria em runtime.
Pode ser necessário recarregar serviços ou reiniciar o host.

## Estrutura

```text
executor.sh                 Orquestra audit, remediação e rollback
AUDIT_SH/audit.sh           Verifica os controles do baseline
REMED_SH/                   Remediações agrupadas por domínio
logs/audit/                 Logs de auditoria
logs/remed/                 Logs de remediação
logs/backups/               Snapshots para rollback
```

## Validação dos scripts

```bash
for script in executor.sh AUDIT_SH/*.sh REMED_SH/*.sh; do
    bash -n "$script" || exit 1
done
```
