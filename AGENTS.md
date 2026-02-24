# AGENTS.md

Diretrizes para agentes de IA trabalhando neste repositório — seja retomando
contexto a partir de um dump gerado pelo próprio `dump_ia.sh`, seja
contribuindo ativamente com o código.

---

## Parte 1 — Retomando contexto via dump

Se você recebeu um arquivo `dump_ia_*.log`, significa que o contexto de uma
sessão anterior foi perdido. Este arquivo contém tudo que você precisa para
continuar o trabalho.

### Passos para retomada

1. **Leia a seção `ÁRVORE DE PASTAS`** no início do dump para entender a
   estrutura do projeto antes de qualquer outra coisa.

2. **Identifique a stack tecnológica** pelos arquivos de configuração presentes
   (`dump_ia.sh` é bash puro; `tests/run_tests.bats` usa bats-core).

3. **Leia o `CHANGELOG.md`** para entender o histórico de decisões e o estado
   da versão atual.

4. **Leia o `CLAUDE.md`** para entender a arquitetura interna do script,
   convenções obrigatórias e comandos de desenvolvimento.

5. **Pergunte ao usuário qual era a tarefa em andamento** antes do contexto
   ser perdido, caso ele não informe espontaneamente.

### O que não fazer ao retomar

- Não propor refatorações ou melhorias não solicitadas
- Não alterar convenções de código sem discutir primeiro
- Não assumir que o projeto está incompleto só porque o contexto foi perdido

---

## Parte 2 — Contribuindo com código

### Arquitetura do projeto

`dump_ia` é um **script bash único** (`dump_ia.sh`). Toda a lógica reside em
um único arquivo, organizado em seções delimitadas por comentários `# ===`.
Não há módulos, imports ou dependências externas além de:

| Ferramenta    | Obrigatoriedade | Uso |
|---------------|-----------------|-----|
| bash 4.4+     | Obrigatória     | Execução |
| coreutils     | Obrigatória     | sha256sum, sha512sum, sort, wc |
| tree          | Opcional        | Árvore de diretórios (fallback para find) |
| iconv         | Opcional        | Conversão de encoding |
| file          | Opcional        | Detecção de encoding |
| bats-core     | Dev             | Testes automatizados |
| shellcheck    | Dev             | Lint de bash |

### Convenções de código obrigatórias

**Sempre use `set -euo pipefail`** — o script falha rápido e de forma previsível.

**Aritmética:**
```bash
# Certo — atribuição
CONTADOR=$(( CONTADOR + 1 ))

# Certo — condicional
if (( CONTADOR > 0 )); then ...

# Errado com set -e — linha isolada pode causar saída se resultado for 0
(( CONTADOR++ ))
```

**Globs com `set -e`** — sempre use o wrapper:
```bash
# Certo
glob_existe "$pasta/*.tf" && { ... }

# Errado — compgen -G retorna 1 quando não há match, matando o script
compgen -G "$pasta/*.tf" > /dev/null && { ... }
```

**Arrays para argumentos do find** — nunca strings:
```bash
# Certo
prune_args=(-name ".git" -o -name "node_modules")
find "$PASTA" \( "${prune_args[@]}" \) -prune ...

# Errado — quebra com espaços em nomes de arquivo
find "$PASTA" \( -name ".git" -o -name "node_modules" \) -prune ...
# (a versão acima funciona, mas a construção dinâmica como string não)
```

**Output para o usuário** — sempre via funções, nunca `echo` direto:
```bash
info()    { $QUIET || echo "[INFO] $*" >&2; }
aviso()   { $QUIET || echo "[AVISO] $*" >&2; }
erro()    { echo "[ERRO] $*" >&2; exit 1; }
```

**Command group vs subshell:**
```bash
# Certo — variáveis globais são preservadas
{ comandos; } > arquivo

# Errado — variáveis modificadas dentro são perdidas
( comandos ) > arquivo
```

### Adicionando novas extensões padrão

Edite o array `EXTENSOES_PADRAO` no início do script. Agrupe por categoria
e mantenha os comentários existentes.

### Adicionando novos diretórios ignorados

Edite o array `IGNORAR_PADRAO`. Nunca remova entradas existentes sem discussão.

### Adicionando novos sinais de detecção de projeto

Edite a função `detectar_projeto()`. Respeite os pesos definidos:
- Peso 3: certeza absoluta (VCS, manifestos, CI/CD)
- Peso 2: indicadores fortes (infra, lockfiles, pastas estruturais)
- Peso 1: sinais fracos (README, pastas secundárias, poucos arquivos de código)

### Testes

Todo código novo deve ter cobertura em `tests/run_tests.bats`. Para rodar:

```bash
# Instalar bats-core (se necessário)
# Ubuntu/Debian: sudo apt install bats
# Fedora:        sudo dnf install bats
# Manual:        ver https://github.com/bats-core/bats-core

bats tests/run_tests.bats
```

Cada teste deve:
- Criar ambiente temporário em `setup()` e limpá-lo em `teardown()`
- Usar `run` para capturar status e output
- Testar tanto o caminho feliz quanto os casos de erro

### Checklist antes de abrir um PR

- [ ] `bash -n dump_ia.sh` passa sem erros
- [ ] `shellcheck dump_ia.sh` passa sem warnings (ou warnings documentados)
- [ ] `bats tests/run_tests.bats` passa com todos os testes verdes
- [ ] CHANGELOG.md atualizado na seção `[Não lançado]` ou nova versão
- [ ] Nenhum `echo` direto adicionado fora das funções utilitárias
- [ ] Novos argumentos documentados em `uso()`
