# POC Tenable — Scan autenticado Linux com HashiCorp Vault

## Objetivo

Validar scans autenticados do Tenable em sistemas Linux legados e modernos, executados por um sensor dedicado.

Os targets são acessados remotamente por SSH e `sudo`, sem necessidade de Nessus Agent. A credencial pode ser fornecida ao Tenable de duas formas:

1. usuário e senha configurados diretamente na credencial SSH do scan;
2. usuário e senha recuperados do HashiCorp Vault por AppRole e KV v2.

Nos dois casos, o sensor usa a mesma conta de serviço existente nos targets.

## Arquitetura

```text
Internet / Tenable Cloud
          |
          | NAT
          v
Tenable Sensor — Debian 12
192.168.56.210
          |
          | Host-Only: 192.168.56.0/24
          |
          +------ HTTPS/8200 ------> HashiCorp Vault
          |                           192.168.56.200
          |
          +------ SSH/22 ----------> Oracle Linux 6.10
          |                           192.168.56.60
          |
          +------ SSH/22 ----------> AlmaLinux 10
                                      192.168.56.100
```

| Componente | IP | Função |
|---|---:|---|
| Oracle Linux 6.10 | `192.168.56.60` | Target legado EL6 |
| AlmaLinux 10 | `192.168.56.100` | Target moderno EL10 |
| HashiCorp Vault | `192.168.56.200` | Cofre de credenciais |
| Tenable Sensor | `192.168.56.210` | Execução dos scans |

## Organização do IAC

```text
IAC/
├── README.md
├── deb12_SENSOR2/
│   ├── Vagrantfile
│   └── instala_sensor.sh
├── deb12_vault/
│   ├── Vagrantfile
│   └── bootstrap_vault.sh
└── rhel_lab/
    ├── Vagrantfile
    └── instala_default.sh
```

## Responsabilidade de cada VM

### Targets Linux

O `rhel_lab/Vagrantfile` cria:

- Oracle Linux 6.10;
- AlmaLinux 10;
- conta de serviço local;
- senha da conta;
- permissão `sudo NOPASSWD`;
- serviço SSH disponível na rede do LAB.

O scan é remoto. Os targets não precisam de Nessus Agent para a validação de credentialed scan.

### HashiCorp Vault

O `deb12_vault/Vagrantfile` cria a VM e prepara:

- pacote HashiCorp Vault;
- serviço `vault`;
- listener HTTPS na porta `8200`;
- certificado self-signed com SAN;
- armazenamento em `/opt/vault/data`;
- configuração `/etc/vault.d/vault.hcl`.

Depois de `init` e `unseal`, o `bootstrap_vault.sh` cria:

```text
secret/tenable/ol6
secret/tenable/ol10
```

Também cria policies somente leitura e AppRoles separados para OL6 e OL10.

### Tenable Sensor

O `deb12_SENSOR2/Vagrantfile` cria o sensor em `192.168.56.210` e executa `instala_sensor.sh`.

O sensor precisa alcançar:

```text
192.168.56.200:8200  Vault
192.168.56.60:22     Oracle Linux 6
192.168.56.100:22    AlmaLinux 10
```

## Subida do LAB

### 1. Targets

```bash
cd IAC/rhel_lab
vagrant up
```

### 2. Vault

```bash
cd IAC/deb12_vault
vagrant up
vagrant ssh
```

Na VM:

```bash
export VAULT_ADDR='https://192.168.56.200:8200'
export VAULT_SKIP_VERIFY=true

vault operator init -key-shares=3 -key-threshold=2
vault operator unseal
vault operator unseal
```

Guardar Unseal Keys e Initial Root Token fora do Git.

Executar o bootstrap:

```bash
export VAULT_TOKEN='<INITIAL_ROOT_TOKEN>'
sudo -E /vagrant/bootstrap_vault.sh
```

O script exibe Role ID e Secret ID de cada AppRole. Esses valores também devem permanecer fora do Git.

### 3. Sensor

```bash
cd IAC/deb12_SENSOR2
vagrant up
```

## Métodos de autenticação do scan

### Opção A — usuário e senha

No Tenable:

```text
Credential type: SSH
Authentication: Password
Username: conta criada nos targets
Password: senha da conta
Privilege escalation: sudo
```

### Opção B — HashiCorp Vault

No Tenable:

```text
Credential type: SSH
Authentication method: Hashicorp Vault
Vault host: 192.168.56.200
Port: 8200
Authentication type: App Role
Authentication URL: /v1/auth/approle/login
Vault type: KV2
KV2 engine URL: /v1/secret
Secret path: tenable/ol6 ou tenable/ol10
Username key: username
Password key: password
SSL: enabled
Verify SSL: disabled somente no LAB self-signed
Privilege escalation: sudo
```

Fluxo:

```text
Tenable autentica no Vault por AppRole
             |
             v
Vault entrega username/password do target
             |
             v
Sensor abre SSH no target e executa sudo
             |
             v
Tenable executa o audit de compliance
```

## Audits da POC

### Oracle Linux 6

```text
AUDIT/COMPLIANCE_CLARO-TI_RHEL6 -LEGADO_310820261336.audit
```

Escopo: EL6 e baseline legado.

### AlmaLinux 10

```text
AUDIT/COMPLIANCE_CLARO-TI_RHEL7-10_FULL_V1.3.5_310820261048.audit
```

Escopo: EL7 a EL10 e derivados homologados.

Primeiro, cada audit deve ser executado isoladamente no seu sistema correspondente. Depois da validação dos dois resultados, os blocos poderão ser unidos em um único `.audit`, com seleção pela versão principal do sistema operacional.

Evidências de execução atualmente preservadas:

```text
AUDIT/oracle6.txt    OL6 com credencial SSH direta
AUDIT/ol6_vault.txt OL6 com credencial recuperada do Vault
AUDIT/alma10.txt     AlmaLinux 10
```

## Verificações antes do scan

No sensor:

```bash
nc -vz 192.168.56.200 8200
nc -vz 192.168.56.60 22
nc -vz 192.168.56.100 22
curl -k https://192.168.56.200:8200/v1/sys/health
```

Nos targets:

```bash
sudo -n id
```

Esperado:

```text
uid=0(root) gid=0(root)
```

Para o Oracle Linux 6, pode ser necessário permitir algoritmos SSH legados exclusivamente para o host `192.168.56.60`. Não habilitar algoritmos antigos globalmente.

## Resultados esperados

Para cada target, o Tenable deve indicar:

```text
Credentialed checks: Yes
SSH authentication: successful
Privilege escalation: successful
Compliance audit: executed
```

Também são esperados:

- inventário local de sistema, kernel e pacotes;
- execução dos controles do audit correspondente;
- resultados `PASSED`, `FAILED` ou equivalentes por controle;
- comandos observáveis nos logs de `sshd` e `sudo` do target;
- mesmo resultado operacional usando senha direta ou credencial recuperada do Vault.

Falha de hardening não significa falha do scan. Um controle pode retornar `FAILED` porque o target não atende ao baseline, enquanto autenticação, `sudo` e execução do audit funcionam corretamente.

## Critério de sucesso da POC

A POC está concluída quando:

1. o sensor alcança Vault e targets;
2. o Vault entrega a credencial correta pelo AppRole;
3. o Tenable autentica via SSH;
4. a elevação por `sudo` funciona;
5. o audit legado executa integralmente no OL6;
6. o audit moderno executa integralmente no AlmaLinux 10;
7. os resultados são produzidos tanto com senha direta quanto usando o Vault.

## Segurança do LAB

Não versionar:

- Unseal Keys;
- Initial Root Token;
- Role Secret ID;
- tokens temporários;
- chaves privadas;
- linking key do Tenable;
- credenciais que serão reutilizadas fora deste LAB.

O certificado self-signed e `VAULT_SKIP_VERIFY=true` são aceitáveis apenas para esta POC.
