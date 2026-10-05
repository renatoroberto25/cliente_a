./AUDIT/           # scripts de auditoria (*.sh)
./REMED_FULL/      # scripts de remediação completa (*.sh)  (padrão)
# OU ./REMED_LIGHT/ (se quiser operar remediação leve)
./logs/audit/      # logs de auditoria
./logs/remed/      # logs de remediação


Por padrão, o script usa REMED_FULL. 
Para usar REMED_LIGHT, ajuste a variável REMED_DIR no topo do executor.sh.


O executor.sh:

Cria (se necessário) os diretórios de log: ./logs/audit e ./logs/remed.
Lista os scripts *.sh de cada pasta e os executa em ordem natural (sort -V), garantindo sequenciamento por nome (ex.: 001-..., 002-...).
Para cada execução, registra stdout/stderr no log correspondente e indica sucesso/erro por exit code do script.
Ao final da auditoria, gera um resumo com contagem de APROVADO e REPROVADO.
Na opção completa (AUDIT → REMEDIAÇÃO → AUDIT PÓS), compara o pré e pós, mostrando melhoria ou regressão.