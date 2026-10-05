# Gerador de audit Windows para Tenable

## Resumo simples

Este projeto faz uma coisa principal:

```text
INF do Windows -> gerador -> audit Tenable com testes PowerShell
```

O INF informa **o que deve ser verificado**, por exemplo:

```text
MinimumPasswordLength = 14
```

O gerador transforma isso em um teste PowerShell que consulta o servidor e
retorna `PASS` quando o valor é `14` ou `FAIL` quando é diferente.

O INF não possui a documentação completa de cada controle. Portanto, depois de
gerar o audit, ainda é necessário usar a documentação oficial da baseline para
completar, item a item:

- título oficial;
- criticidade oficial;
- descrição e justificativa;
- impacto;
- procedimento de correção;
- referência normativa e aplicabilidade.

Por exemplo, a documentação completa deve transformar o item técnico em algo
parecido com isto:

```text
<custom_item>
  type            : AUDIT_POWERSHELL
  description     : "001 Minimum password length, Alta"
  info            : "Define o tamanho mínimo permitido para senhas."
  solution        : "Configurar MinimumPasswordLength conforme a baseline."
  reference       : "Documento oficial da baseline, item correspondente."
  value_type      : POLICY_TEXT
  value_data      : "PASS"
  check_type      : CHECK_EQUAL
  powershell_args : "<script PowerShell em Base64/UTF-16LE>"
  ps_encoded_args : YES
</custom_item>
```

Em resumo: **o gerador cria a verificação técnica; a documentação da baseline
completa as informações do controle**.

O gerador não usa outro audit como molde e não inventa criticidade. A descrição
de cada teste é montada diretamente com o nome da seção e da chave do INF.

## Por que `powershell_args` está codificado?

Os valores de `powershell_args` **não estão criptografados**. Eles contêm scripts
PowerShell codificados em Base64 a partir de texto UTF-16LE, formato esperado pelo
PowerShell para um `EncodedCommand`.

Cada item utiliza os campos em conjunto:

```text
powershell_args : "<script em Base64/UTF-16LE>"
ps_encoded_args : YES
```

`ps_encoded_args : YES` informa ao Nessus que o valor deve ser tratado como um
comando PowerShell codificado. Remover esse campo sem também alterar o conteúdo de
`powershell_args` faz o Nessus tentar executar a sequência Base64 como texto e a
verificação falha.

### Por que não usar o script diretamente?

Essas verificações possuem scripts com múltiplas linhas, variáveis, aspas, chaves,
pipelines e redirecionamentos. Em texto puro, o comando precisa atravessar o parser
do arquivo de auditoria, o transporte do Nessus e o parser do PowerShell. Isso torna
o comando sujeito a erros de escape e interpretação.

A codificação Base64 preserva o script durante esse transporte. Ela não oferece
sigilo, proteção ou controle de acesso; qualquer pessoa pode decodificar o conteúdo.

O resultado de cada script deve ser `PASS` ou `FAIL`. O Nessus compara esse resultado
com o `value_data` definido no item.

## Como decodificar um argumento

No PowerShell:

```powershell
$encoded = '<conteúdo de powershell_args>'
[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encoded))
```

No Linux:

```bash
printf '%s' '<conteúdo de powershell_args>' | base64 -d | iconv -f UTF-16LE -t UTF-8
```

## Como gerar

```bash
python3 generate_windows_audit_powershell_from_inf.py SRV-W2K25-PADRAO-Full-CLARO_com_UAC.inf SRV-W2K25-PADRAO-Full-CLARO_com_UAC.audit
```

Referência: [AUDIT_POWERSHELL — Tenable Nessus Compliance Checks](https://docs.tenable.com/nessus/compliance-checks-reference/Content/AUDIT_POWERSHELL.htm).
