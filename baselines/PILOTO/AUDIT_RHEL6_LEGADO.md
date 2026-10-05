# Audit customizado RHEL6 legado

## Escopo

O arquivo `COMPLIANCE_CLARO_RHEL6_LEGADO_CUSTOM.audit` foi criado para Red Hat Enterprise Linux 6.x e Oracle Linux 6.x. Ele não substitui o audit RHEL 7–9.

Segundo `ASSETS.txt`, os candidatos ao audit legado são:

- `brux0782` — declarado como Red Hat Enterprise Linux Server 6.9;
- `rjux0197` — declarado como Oracle Linux Server 6.10.

O inventário é apenas uma indicação. Antes de associar o audit, confirme remotamente a plataforma com:

```sh
cat /etc/redhat-release
uname -r
rpm -E '%{rhel}' 2>/dev/null
```

Use o audit legado somente quando a versão principal confirmada for 6. Os demais ativos do arquivo continuam no audit RHEL 7–9.

Para o caso operacional de um único arquivo e um único scan, foi gerado também `COMPLIANCE_CLARO_RHEL_FAMILY_6-9_UNIFICADO.audit`. Ele usa a estrutura `<if>/<condition>/<then>/<else>`: o primeiro ramo executa o audit original em EL7–9; o segundo executa clones dos mesmos itens, alterando somente o `cmd`, em EL6; o `else` final reporta sistema fora do escopo. O controle 999 fica fora dos ramos e é comum às versões 6–9.

## Rastreabilidade

- Os 183 `custom_item` correspondem, um a um, às 183 linhas de `03_Hardening_2026_RHEL_LEGADO.xlsx`.
- Os IDs da planilha foram preservados. As lacunas 88–92, 149 e 187 são da fonte e não foram preenchidas nem renumeradas.
- Cada descrição contém ID, resumo, criticidade e a marca `RHEL6 LEGADO`.
- Cada `reference` registra planilha, ID, tópico e perfil.
- O audit é gerado por `generate_rhel6_audit.py`, que interrompe a geração se faltar ou sobrar algum ID no mapa de comandos.

## Decisões de compatibilidade

Os checks usam recursos presentes no EL6: `service`, `chkconfig`, GRUB Legacy, `ntpd`, `pam_cracklib`, `pam_tally2`, `netstat`, `stat -c`, `grep -E` e `/proc/mounts`. Não dependem de `systemctl`, `dnf`, `authselect`, `firewall-cmd`, `findmnt`, GRUB2 ou `grep -P`.

Os itens abaixo dependem de evidência ou política local e falham de propósito até que essa evidência exista:

- `RHEL6-179`: requer `/etc/rhel6-support-contract.evidence` com a referência da cobertura de suporte ou exceção formal;
- `RHEL6-185`: compara listeners com `/etc/rhel6-approved-listeners`, um endereço/porta por linha, no mesmo formato da coluna `Local Address` de `netstat -lntup`;
- checks de serviço como HTTP, NFS, Samba, Java e compiladores assumem que o componente não é autorizado. Caso seja requisito do host, trate como exceção formal, não como falso positivo a ser ocultado.

## Validação realizada

Foram conferidos o balanceamento dos blocos, a presença dos metadados e do `expect`, a unicidade dos IDs e a sintaxe shell dos 183 comandos. A validação funcional final deve ser feita primeiro em clone/snapshot de um EL6 representativo antes do uso em produção.
