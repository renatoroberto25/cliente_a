# Trabalho futuro — sistemas EOL

Os sistemas abaixo estão fora dos indicadores de cobertura aplicável do
dashboard por estarem classificados como `EOL · Não aplicável`.

Nem todos, porém, precisam ficar definitivamente sem hardening. Parte dessas
plataformas ainda permite a criação de baselines reduzidos e compatíveis com as
limitações de versões antigas. O trabalho futuro consiste em revisar essa
classificação e separar o que ainda pode ser endurecido do que deve seguir
somente para migração.

## Tratamento proposto

| Grupo | Sistemas | Trabalho futuro |
| --- | --- | --- |
| Legacy hardenizável | RHEL 5, Oracle Linux 5, CentOS 5 e Enterprise Linux 5 | Criar baseline `EL5 LEGACY` |
| Legacy hardenizável | Debian 5 e 6 | Criar baseline `DEB LEGACY` |
| Legacy hardenizável | SLES 11 | Criar baseline `SUSE11 LEGACY` |
| Legacy hardenizável | Windows Server 2008 e 2008 R2 | Criar baseline `WIN2008 LEGACY` |
| EOL recente | Amazon Linux 2 | Adaptar um baseline mais moderno, mantendo uma versão separada |
| EOL ainda configurável | Windows 10 | Manter baseline próprio |
| Sem baseline futuro | RHEL 4, Oracle Linux 4, CentOS 4, SLES 10, Windows Server 2003 e Windows 2000 | Manter como `EOL · Não aplicável` e direcionar para migração |

## Escopo sugerido para Linux LEGACY

Os baselines legacy devem cobrar apenas controles suportados pela plataforma:

- permissões de `/etc/passwd`, `/etc/shadow`, `/etc/group` e arquivos sensíveis;
- contas, UID 0, shells e usuários sem senha;
- política de senha e PAM compatível com a versão;
- configuração segura do SSH dentro das capacidades do OpenSSH instalado;
- desativação de serviços desnecessários;
- proteção de `cron` e `at`;
- parâmetros de rede em `sysctl`;
- bloqueio de redirects, source routing e ICMP inseguro;
- restrição de core dumps;
- módulos de kernel disponíveis na versão;
- logging, syslog, `auditd` e regras suportadas;
- proteção do bootloader;
- opções `nodev`, `nosuid` e `noexec`, quando aplicáveis;
- inventário e tratamento de arquivos SUID/SGID;
- banners, `umask` e timeout de sessão;
- firewall disponível naquela geração.

## Mapeamento necessário

Antes de criar cada baseline, identificar precisamente a plataforma:

```text
sistema operacional → família → versão → kernel → arquitetura
```

Esse mapeamento definirá quais controles são aplicáveis, quais precisam de
adaptação e quais não são suportados pela versão EOL.
