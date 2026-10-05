# Catálogo e Taxonomia dos Baselines de Hardening

## 1. Objetivo

Este diretório reúne os baselines de hardening utilizados para auditoria, definição de padrão e validação de servidores Linux nos diferentes ambientes do grupo.

Os arquivos são separados por:

- família de sistema operacional;
- abrangência do baseline;
- nível de maturidade ou compatibilidade do ambiente;
- empresa, área ou fluxo de provisionamento;
- finalidade operacional.

O baseline aplicável deve ser escolhido de acordo com o sistema operacional, a idade da plataforma e o contexto do ativo.

---

## 2. Taxonomia

### 2.1 Família de sistema operacional

| Identificador | Definição |
|---|---|
| `RHEL_LIKE` | Distribuições compatíveis com o ecossistema Red Hat, principalmente Oracle Linux, Red Hat Enterprise Linux e Rocky Linux. |
| `DEB_LIKE` | Distribuições compatíveis com o ecossistema Debian, principalmente Debian e Ubuntu. |

### 2.2 Tipo de baseline

| Identificador | Definição |
|---|---|
| `PADRAO` | Baseline genérico e abrangente, criado sem considerar exceções específicas de um ambiente ou equipe. |
| `LEGADO` | Baseline reduzido para sistemas antigos, com auditoria local e remediações pontuais. |
| `FULL` | Baseline completo, revisado e adaptado ao ambiente real da empresa ou unidade. |
| `JIRA` | Baseline de entrada para máquinas novas provisionadas por template ou solicitação via Jira. |
| `<AREA>` | Baseline específico para uma área técnica ou unidade de negócio, como `VIDEO`. |

### 2.3 Escopo e prioridade de aplicação

A prioridade recomendada é:

1. baseline específico da área ou do fluxo de provisionamento;
2. baseline completo e validado para a empresa;
3. baseline legado, quando houver limitação de versão ou de ferramenta;
4. baseline padrão genérico.

Para máquinas novas originadas de templates, o baseline de entrada deve ser aplicado primeiro. Depois da auditoria inicial, o ativo pode ser enquadrado em outro baseline mais específico, conforme o ambiente e a responsabilidade da equipe.

---

## 3. Catálogo dos arquivos

### `01_Hardening_2026_RHEL_LIKE_PADRAO.xlsx`

Baseline genérico e abrangente para distribuições da família RHEL.

Foi o primeiro baseline consolidado e representa a visão mais ampla do padrão de segurança, sem considerar particularidades de ambiente, aplicações ou equipes.

É aplicável principalmente a:

- Oracle Linux;
- Red Hat Enterprise Linux;
- Rocky Linux;
- outras distribuições compatíveis com RHEL.

Deve ser utilizado como referência geral quando ainda não existir um baseline específico para o ambiente.

---

### `02_Hardening_2026_DEB_LIKE_PADRAO.xlsx`

Baseline genérico e abrangente para distribuições da família Debian.

Apesar da numeração, é um baseline mais recente, criado para atender ambientes do grupo que utilizam Debian e Ubuntu, incluindo:

- serviços de mídia, televisão e música;
- plataformas que dependem de aplicações homologadas apenas para Debian ou Ubuntu;
- estações VDI de desenvolvimento baseadas em Ubuntu 24.04.

Assim como o baseline RHEL padrão, não considera particularidades de uma equipe específica e serve como referência global para sistemas Debian-like.

---

### `03_Hardening_2026_RHEL_LIKE_LEGADO.xlsx`

Baseline reduzido para distribuições RHEL-like anteriores à versão 7 ou classificadas internamente como legadas.

Esses ativos não seguem o mesmo ciclo de automação e auditoria dos sistemas atuais. A validação é realizada localmente, com alterações pontuais e controladas.

O objetivo é elevar o nível de segurança sem aplicar indiscriminadamente controles incompatíveis com sistemas antigos.

---

### `04_Hardening_2026_DEB_LIKE_LEGADO.xlsx`

Baseline reduzido para distribuições Debian-like classificadas como legadas.

Abrange principalmente versões antigas de Debian, Ubuntu e derivados que, no contexto atual, não utilizam o agente Tenable ou não possuem compatibilidade adequada com o processo padrão de auditoria.

A avaliação é realizada localmente, com remediações pontuais e compatíveis com a versão do sistema.

---

### `05_Hardening_2026_RHEL_LIKE_CLARO_TI_FULL.xlsx`

Baseline completo da Claro TI para distribuições RHEL-like.

Foi desenvolvido a partir do baseline genérico, mas revisado conforme a realidade do ambiente. Sua construção considerou:

- discussões com as equipes responsáveis;
- configurações já utilizadas em produção;
- scripts e procedimentos existentes;
- limitações operacionais;
- controles aplicáveis ao ambiente da Claro TI.

Representa o padrão completo e contextualizado para os servidores RHEL-like da Claro TI.

---

### `06_Hardening_2026_RHEL_LIKE_CLARO_TI_JIRA.csv`

Baseline de entrada para máquinas novas provisionadas por templates ou solicitações via Jira.

Esses ativos já devem nascer com o agente Tenable instalado e com os requisitos mínimos de segurança atendidos.

O baseline possui caráter mais rigoroso porque sua função é identificar, desde a criação da máquina, desvios de configuração, falhas de template e ausência de controles básicos.

Características principais:

- auditoria inicial de máquinas novas;
- ausência de remediação automatizada;
- validação do padrão mínimo esperado;
- identificação rápida de falhas no processo de provisionamento;
- geração de evidências para discussão com as equipes responsáveis.

Após a auditoria inicial, o ativo pode ser direcionado para outro baseline aplicável ao seu ambiente.

---

### `07_Hardening_2026_DEB_LIKE_VIDEO.xlsx`

Baseline específico para a área de Engenharia de Vídeo.

Foi criado para atender um parque heterogêneo de servidores Ubuntu, com versões que podem variar de releases atuais até versões antigas ainda mantidas pela área.

Como referência:

- o baseline foi pensado para abranger, em princípio, Ubuntu 18.04 ou superior;
- versões anteriores devem ser avaliadas quanto à compatibilidade dos controles;
- sistemas muito antigos ou incompatíveis com o processo atual devem ser reenquadrados no baseline legado.

Os controles ainda estão em processo de avaliação e homologação pelas equipes responsáveis.

---

## 4. Convenção recomendada de nomes

Formato:

```text
NN_Hardening_<ANO>_<FAMILIA>_<ESCOPO>_<PERFIL>.<EXTENSAO>
```

Exemplos:

```text
01_Hardening_2026_RHEL_LIKE_PADRAO.xlsx
02_Hardening_2026_DEB_LIKE_PADRAO.xlsx
03_Hardening_2026_RHEL_LIKE_LEGADO.xlsx
04_Hardening_2026_DEB_LIKE_LEGADO.xlsx
05_Hardening_2026_RHEL_LIKE_CLARO_TI_FULL.xlsx
06_Hardening_2026_RHEL_LIKE_CLARO_TI_JIRA.csv
07_Hardening_2026_DEB_LIKE_VIDEO.xlsx
```

### Regras

- utilizar numeração sequencial sem duplicidade;
- utilizar `_` como separador;
- evitar hífen dentro dos identificadores;
- manter as famílias como `RHEL_LIKE` ou `DEB_LIKE`;
- indicar empresa, área ou fluxo somente quando o baseline for específico;
- utilizar `PADRAO`, `LEGADO`, `FULL`, `JIRA` ou o nome da área como perfil;
- manter o ano no nome do arquivo para facilitar rastreabilidade;
- registrar alterações relevantes em controle de versão ou histórico de mudanças.

---

## 5. Critérios de enquadramento

| Situação do ativo | Baseline recomendado |
|---|---|
| RHEL-like atual, sem baseline específico | `RHEL_LIKE_PADRAO` |
| Debian-like atual, sem baseline específico | `DEB_LIKE_PADRAO` |
| RHEL-like antigo ou incompatível com o processo atual | `RHEL_LIKE_LEGADO` |
| Debian-like antigo ou incompatível com o processo atual | `DEB_LIKE_LEGADO` |
| Servidor RHEL-like da Claro TI | `RHEL_LIKE_CLARO_TI_FULL` |
| Máquina nova provisionada por Jira ou template | `RHEL_LIKE_CLARO_TI_JIRA` |
| Servidor da Engenharia de Vídeo | `DEB_LIKE_VIDEO` |

---

## 6. Princípios de governança

- Baselines genéricos definem a referência técnica global.
- Baselines completos refletem a realidade de um ambiente específico.
- Baselines legados reduzem risco sem exigir controles incompatíveis.
- Baselines de entrada validam a qualidade do provisionamento.
- Baselines específicos de área devem ser homologados pelas equipes responsáveis.
- Exceções devem ser justificadas e registradas.
- A ausência de automação não elimina a obrigatoriedade da auditoria.
- O baseline aplicável deve ser definido antes da análise dos resultados.
