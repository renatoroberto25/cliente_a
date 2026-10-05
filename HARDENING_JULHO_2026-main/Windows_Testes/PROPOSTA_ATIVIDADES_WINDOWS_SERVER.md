Se fosse eu, levaria estes pontos como atividades principais:

- Revisar os baselines de Windows conforme o padrão definido.
- Manter os itens fiéis aos arquivos INF correspondentes.
- Padronizar a descrição dos controles no formato:
  - `ID, Nome do item, Criticidade`
- Revisar os audits conforme o mesmo padrão.
- Completar os campos informacionais necessários no audit.
- Validar os comandos PowerShell usados em cada controle.
- Testar os audits em uma VM antes do uso em produção.
- Comparar o resultado do Tenable com o que está realmente configurado nos servidores.
- Verificar divergências entre INF, baseline, audit e ambiente.
- Corrigir controles que retornem PASS ou FAIL de forma incorreta.
- Versionar os baselines e audits revisados.
- Identificar e comunicar às equipes que receberam versões anteriores.

Visando fechar o ciclo:

- Baselines padronizados.
- Audits revisados e completos.
- Controles testados em VM.
- Resultado do Tenable compatível com a configuração real dos servidores.
