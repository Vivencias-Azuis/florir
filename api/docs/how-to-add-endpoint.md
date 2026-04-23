# How To Add Endpoint

## Escopo

Este guia assume um endpoint CRUD JSON em uma API Rails.

## Passos

1. Escreva primeiro a request spec do endpoint.
2. Confirme que ela falha pelo motivo certo.
3. Adicione ou ajuste a rota.
4. Implemente o controller com delegacao minima.
5. Crie ou ajuste serializer, presenter ou contrato de resposta.
6. Extraia caso de uso apenas se houver logica real.
7. Rode `script/ci-fast`.

## Regras

- nao coloque regras longas no controller
- nao exponha JSON ad hoc se o endpoint for relevante
- trate autorizacao e validacao de forma explicita
- se houver efeito colateral, deixe-o visivel no fluxo
- um endpoint CRUD novo deve ter request spec cobrindo sucesso e erro relevante
- se a resposta JSON for contrato publico, capture fixture aprovada ou cobertura equivalente
