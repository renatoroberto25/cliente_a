# Utilitários Python de Hardening

Este repositório reúne ferramentas para transformar dados de inventário e resultados de Compliance Audit do Tenable em relatórios HTML autocontidos.

O README da raiz funciona apenas como ponto de entrada. As instruções de uso, requisitos, formatos de entrada e exemplos estão documentados dentro de cada solução.

## Escolha a solução

| Preciso de... | Solução | Documentação |
|---|---|---|
| Acompanhar o status das baselines, cobertura de assets e presença de agents | **One-page de baselines** | [Acessar ONE-PAGE](ONE-PAGE/README.md) |
| Transformar exports de Compliance Audit em dashboards técnicos de hardening | **Dashboards de host-audits** | [Acessar HOST-AUDITS-TODASH](HOST-AUDITS-TODASH/README.md) |

## Visão rápida

### ONE-PAGE

Atualiza uma planilha de status a partir do inventário de assets e gera uma visão executiva em HTML.

```text
inventário CSV + status anterior XLSX → novo status XLSX → one-page HTML
```

[Ver funcionalidade, requisitos e modo de uso](ONE-PAGE/README.md)

### HOST-AUDITS-TODASH

Processa resultados de Compliance Audit, organiza equipes e perfis e gera dashboards de aderência, falhas e evolução histórica.

```text
exports de Compliance CSV → consolidação e classificação → dashboard HTML
```

[Ver funcionalidade, requisitos e modo de uso](HOST-AUDITS-TODASH/README.md)

## Saídas

Os dashboards HTML são autocontidos: não precisam de servidor web e podem ser abertos diretamente em um navegador. Consulte o README da solução escolhida antes da execução para conferir os cabeçalhos e a nomenclatura esperados.
