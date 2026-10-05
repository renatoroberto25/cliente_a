# Comparativo dos INFs Windows Server 2022 e 2025

Os arquivos abaixo possuem os mesmos 282 controles, valores, caminhos de
registro, direitos, ACLs e serviços:

- `SRV-W2K22-PADRAO-Full-CLARO_com_UAC.inf`
- `SRV-W2K25-PADRAO-Full-CLARO_com_UAC.inf`

A única diferença entre eles é o cabeçalho de versão, na linha 3:

```text
Sofware Version: Windows Server 2022
Sofware Version: Windows Server 2025
```

## Inconsistência encontrada

O INF identificado como Windows Server 2022 também contém, na linha 95:

```text
MACHINE\SOFTWARE\PSS\BASELINE=1,"SRV-W2K25-FULL-CLARO"
```

Isso indica que o INF de 2022 provavelmente é uma cópia do INF de 2025 com
apenas o cabeçalho alterado. Caso ele represente realmente a baseline de 2022,
o valor esperado provavelmente seria `SRV-W2K22-FULL-CLARO`.

## Relação com o audit funcional de 2022

O arquivo
`04_COMPLIANCE_CLARO_WINDOWS_SERVER_2022_TENABLE_POWERSHELL_MINIMAL_V1.0.2.txt`
foi criado a partir de `SRV-W2K22-PADRAO-Full-CLARO_SEM_UAC.inf`, e não do INF
`com_UAC` disponível atualmente.

Por isso, existem três diferenças entre o audit funcional de 2022 e o audit
gerado para 2025:

| Controle | Audit 2022 `SEM_UAC` | Audit 2025 `com_UAC` |
|---|---:|---:|
| Marcador da baseline | `SRV-W2K22-FULL-CLARO` | `SRV-W2K25-FULL-CLARO` |
| `ConsentPromptBehaviorAdmin` | `0` | `1` |
| `EnableLUA` | `0` | `1` |

As diferenças são decorrentes principalmente da configuração de UAC e do
marcador da baseline, não de controles distintos entre Windows Server 2022 e
Windows Server 2025 nos INFs fornecidos.
