# Como Contribuir

Obrigado pelo interesse em contribuir com o `dump_ia`! Este documento explica
o processo para que sua contribuição seja aceita de forma rápida e segura.

## Antes de começar

- Leia o [AGENTS.md](AGENTS.md) para entender a arquitetura e as convenções
  obrigatórias do projeto.
- Verifique se já existe uma [issue](https://github.com/petrinhu/dump_ia/issues)
  aberta para o que você quer fazer. Se não existir, abra uma antes de codificar.
- Para mudanças pequenas (typos, ajustes de documentação), você pode ir direto
  para o PR.

## Configurando o ambiente

### Requisitos

| Ferramenta   | Versão mínima | Como instalar |
|--------------|---------------|---------------|
| bash         | 4.4           | Padrão na maioria das distros |
| shellcheck   | qualquer      | `apt install shellcheck` / `dnf install ShellCheck`  |
| bats-core    | 1.2+          | Veja abaixo |

### Instalando bats-core

```bash
# Ubuntu / Debian
sudo apt install bats

# Fedora / RHEL
sudo dnf install bats

# Manual (qualquer sistema)
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Clonando o repositório

```bash
git clone https://github.com/petrinhu/dump_ia.git
cd dump_ia
chmod +x dump_ia.sh
```

## Rodando os testes

**Todos os testes devem passar antes de abrir um PR.** Sem exceção.

```bash
# Rodar todos os testes
bats tests/run_tests.bats

# Rodar um teste específico
bats tests/run_tests.bats --filter "nome do teste"

# Verificar sintaxe bash
bash -n dump_ia.sh

# Lint completo
shellcheck dump_ia.sh
```

A saída esperada é algo como:

```
1..13
ok 1 --help exibe texto de uso
ok 2 opção desconhecida retorna erro
ok 3 gera dump em pasta temporária
...
```

Se algum teste falhar, corrija antes de submeter.

## Fluxo de contribuição

1. **Fork** o repositório no GitHub
2. **Crie um branch** a partir de `main` com nome descritivo:
   ```bash
   git checkout -b feat/nova-extensao-padrao
   git checkout -b fix/encoding-windows
   git checkout -b docs/melhorar-readme
   ```
3. **Faça as alterações** seguindo as convenções do projeto
4. **Rode os testes** e corrija qualquer falha
5. **Atualize o CHANGELOG.md** na seção `[Não lançado]`
6. **Commit** com mensagem no formato Conventional Commits (veja abaixo)
7. **Abra o Pull Request** usando o template fornecido

## Convenção de commits

Use o formato [Conventional Commits](https://www.conventionalcommits.org/pt-br/):

```
<tipo>(<escopo>): <descrição curta em português>

[corpo opcional]

[rodapé opcional]
```

**Tipos aceitos:**

| Tipo       | Uso |
|------------|-----|
| `feat`     | Nova funcionalidade |
| `fix`      | Correção de bug |
| `docs`     | Apenas documentação |
| `test`     | Adição ou correção de testes |
| `refactor` | Refatoração sem mudança de comportamento |
| `chore`    | Tarefas de manutenção (CI, dependências, etc.) |
| `perf`     | Melhoria de desempenho |

**Exemplos:**

```
feat(detecção): adicionar suporte a projetos Elixir/Mix
fix(encoding): corrigir conversão de arquivos CP1252 em sistemas Linux
docs(readme): atualizar exemplos de uso com --verbose
test(hash): adicionar teste para verificação com sha512
```

## O que faz um bom PR

- **Escopo único** — um PR resolve uma coisa só. Se encontrou dois bugs,
  abra dois PRs.
- **Testes incluídos** — toda mudança de comportamento deve ter cobertura.
- **Sem regressões** — todos os testes existentes passam.
- **Documentação atualizada** — `uso()` no script, CHANGELOG e AGENTS.md
  quando aplicável.
- **Shellcheck limpo** — sem warnings não documentados.

## Reportando bugs

Use o [template de bug report](.github/ISSUE_TEMPLATE/bug_report.yml) no
GitHub. Inclua sempre:

- Versão do script (`grep VERSAO dump_ia.sh`)
- Sistema operacional e versão do bash (`bash --version`)
- Comando exato que causou o problema
- Saída completa do terminal

## Sugerindo funcionalidades

Use o [template de feature request](.github/ISSUE_TEMPLATE/feature_request.yml).
Descreva o problema que a funcionalidade resolve, não apenas a solução.

## Dúvidas

Abra uma [discussion](https://github.com/petrinhu/dump_ia/discussions) ou
entre em contato via **petrinhu@yahoo.com.br**.
