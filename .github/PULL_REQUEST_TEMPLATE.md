## Descrição

<!-- Descreva o que esta PR resolve ou adiciona. Inclua o contexto necessário
     para entender a mudança. Se resolve uma issue, use "Closes #123". -->

Closes #

## Tipo de mudança

<!-- Marque com [x] o que se aplica -->

- [ ] Correção de bug
- [ ] Nova funcionalidade
- [ ] Melhoria de funcionalidade existente
- [ ] Refatoração (sem mudança de comportamento)
- [ ] Documentação
- [ ] Testes
- [ ] Manutenção (CI, dependências, etc.)

## Mudanças realizadas

<!-- Liste as principais alterações feitas nesta PR -->

-
-

## Checklist

<!-- Todos os itens marcados são obrigatórios para aprovação -->

- [ ] `bash -n dump_ia.sh` passa sem erros
- [ ] `shellcheck dump_ia.sh` passa sem warnings não documentados
- [ ] `bats tests/run_tests.bats` — todos os testes passam
- [ ] Novos testes adicionados para comportamentos novos ou corrigidos
- [ ] `CHANGELOG.md` atualizado
- [ ] `uso()` no script atualizado (se novas opções foram adicionadas)
- [ ] Sem `echo` direto fora das funções utilitárias (`info`, `aviso`, `erro`)

## Como testar

<!-- Descreva os passos para verificar manualmente que a mudança funciona -->

```bash
# Exemplo:
./dump_ia.sh --pasta /alguma/pasta --verbose
```

## Contexto adicional

<!-- Screenshots, logs, links relevantes ou qualquer informação adicional -->
