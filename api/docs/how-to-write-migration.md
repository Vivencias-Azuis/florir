# How To Write Migration

## Regras

- prefira migrations pequenas
- pense em rollback antes do merge
- avalie lock, backfill e impacto em producao
- nao misture alteracoes estruturais e de dados sem necessidade

## Checklist

- a migration e reversivel?
- o nome comunica bem a mudanca?
- ha risco de lock longo?
- precisa de rollout em mais de uma etapa?
- os tests relevantes cobrem o novo comportamento?
