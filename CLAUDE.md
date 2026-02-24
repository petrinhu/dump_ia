# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projeto

`dump_ia` é um script bash único (`dump_ia.sh`) sem dependências externas além de coreutils. Gera dumps completos de projetos de software para restauração de contexto por IAs. Distribuído como `.sh` direto, com pacote RPM planejado.

## Comandos de desenvolvimento

```bash
# Verificar sintaxe sem executar
bash -n dump_ia.sh

# Lint (requer shellcheck)
shellcheck dump_ia.sh

# Rodar todos os testes (requer bats-core)
bats tests/run_tests.bats

# Rodar um teste específico por nome
bats tests/run_tests.bats --filter "gera dump"

# Teste manual rápido
./dump_ia.sh --pasta . --output /tmp --verbose

# Testar verificação de hash
./dump_ia.sh --verificar /tmp/dump_ia_*.log
```

## Arquitetura

Script único, fluxo linear em seções claramente delimitadas por comentários `# ===`:

1. **Configurações padrão** — variáveis globais com valores default
2. **Funções utilitárias** — `erro()`, `info()`, `aviso()`, `verbose_msg()`, `glob_existe()`
3. **Parse de argumentos** — `while case` com validação imediata
4. **Modo verificação** — `--verificar` faz early-exit antes de qualquer outra lógica
5. **Validações** — dependências, pastas, algoritmo de hash
6. **Detecção de projeto** — sistema de pesos com `detectar_projeto()`
7. **Build de argumentos find** — arrays `prune_args` e `ext_args`
8. **Coleta de arquivos** — `find` com `sort -z`, resultado em array `ARQUIVOS`
9. **Geração do dump** — command group `{ } > $ARQUIVO_DUMP` (não é subshell)
10. **Hash** — `sha256sum`/`sha512sum` sobre o log completo
11. **Resumo final** — output de métricas

## Convenções bash obrigatórias

- `set -euo pipefail` ativo — nunca remover
- `(( expr ))` somente em contexto `if`/`&&`/`||` para evitar saída com `set -e`
- `$(( expr ))` para atribuições aritméticas
- `glob_existe()` obrigatório ao usar `compgen -G` — evita falha com `set -e`
- Arrays para listas de argumentos do `find` (`prune_args`, `ext_args`) — nunca strings
- `{ } > arquivo` para redirecionar blocos — variáveis modificadas dentro são visíveis no escopo externo
- Variáveis globais modificadas dentro do command group: `ERROS_COUNT`, `IGNORADOS_TAMANHO`
- Respeitar `$QUIET` em todo output via `info()`/`aviso()` — nunca `echo` direto exceto em `erro()`

## Detecção de projeto (pesos)

| Peso | Categoria |
|------|-----------|
| 3 | VCS (.git, .svn, .hg), manifestos (package.json, Cargo.toml…), CI/CD |
| 2 | Infra (Dockerfile, *.tf), build (Makefile, CMake), lockfiles, pastas src/tests/docs |
| 1 | README, pastas bin/scripts/dist, arquivos de código (escala: 1–3=+1, 4–10=+2, 11+=+3) |

Limiares: 0 = bloqueia com confirmação, 1–2 = avisa e confirma, 3+ = prossegue.

## Testes

Usa **bats-core**. Suite em `tests/run_tests.bats`. Antes de qualquer PR, todos os testes devem passar:

```bash
bats tests/run_tests.bats
```
