# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

---

## [2.0.0] — 2026-02-23

Versão com reescrita completa do script, adicionando detecção inteligente de
projetos, suporte a encoding, modo silencioso/verboso e estrutura de saída
reformulada.

### Adicionado

- **Sistema de detecção de projeto por pesos** — analisa a pasta-alvo e
  atribui pontuação com base em sinais como arquivos de manifesto, VCS,
  CI/CD, lockfiles, configurações de ferramentas e quantidade de arquivos
  de código. Limiares: 0 bloqueia, 1–2 solicita confirmação, 3+ prossegue.
- **Opção `--quiet` / `-q`** — suprime todo output do terminal, ideal para
  uso em pipelines e scripts automatizados.
- **Opção `--verbose`** — exibe cada arquivo sendo processado em tempo real,
  com nome e tamanho.
- **Opção `--verificar` / `-v`** — valida a integridade de um dump existente
  comparando com o arquivo de hash correspondente (`.sha256` ou `.sha512`).
  Detecta automaticamente o algoritmo pelo nome do arquivo.
- **Conversão automática de encoding** — arquivos não-UTF-8 são convertidos
  com `iconv` antes de serem incluídos no dump. Tenta o encoding detectado
  via `file --mime-encoding`, com fallback para ISO-8859-1, CP1252,
  ISO-8859-15 e LATIN1.
- **Arquivo `erros.log` separado** — registra arquivos ignorados por tamanho
  e arquivos com falha de encoding, com timestamp e caminho relativo.
  Criado apenas quando há erros; removido automaticamente se vazio.
- **Suporte a SHA-512** — via `--hash sha512`. Padrão mantido em SHA-256.
- **Extensões novas no padrão** — `.lock`, `.puml`, `.drawio`, `.tf`,
  `.tfvars`, `.gradle`, `.rst`.
- **`.env` explicitamente ignorado** por padrão na lista de diretórios/
  arquivos excluídos.
- **Estrutura de log reformulada**:
  1. Cabeçalho com metadados e opções utilizadas na geração
  2. Árvore de diretórios
  3. Conteúdo dos arquivos
  4. Instruções para retomada de contexto por IA
- **Hash calculado sobre o log completo** e salvo exclusivamente em arquivo
  externo (`.sha256` ou `.sha512`), eliminando o problema circular de
  hash dentro do próprio arquivo.
- **Fallback automático** para `find` quando `tree` não está instalado,
  com aviso e instruções de instalação.
- **Verificação de dependências** — `iconv` e `file` são opcionais com aviso;
  `sha256sum`/`sha512sum` são obrigatórios com erro claro.

### Alterado

- Cabeçalho do dump agora inclui todas as opções utilizadas na geração
  (inclusive os valores padrão), host, usuário, projeto e saída.
- Separadores visuais mais consistentes entre seções do log.
- Contadores de arquivos incluídos, ignorados e com erro exibidos tanto
  no terminal quanto ao final do dump.
- `--quiet` tem precedência sobre `--verbose` quando ambos são passados.
- Em modo `--quiet` com detecção fraca de projeto, o script continua
  automaticamente sem interação, registrando aviso no stderr.

### Corrigido

- Argumentos do `find` passados como arrays em vez de strings, evitando
  falhas com caminhos e nomes contendo espaços.
- Uso correto de `glob_existe()` como wrapper de `compgen -G` para
  compatibilidade com `set -euo pipefail`.
- Variáveis aritméticas usando `$(( ))` em atribuições e `(( ))` apenas
  em contextos condicionais, evitando saída inesperada com `set -e`.

---

## [1.0.0] — 2026-02-23

Versão inicial do script com funcionalidades básicas de dump.

### Adicionado

- Geração de arquivo de dump com árvore de diretórios e conteúdo dos
  arquivos de código e documentação.
- Opções `--pasta`, `--output`, `--ext`, `--ignorar`, `--max-size`,
  `--hash` e `--help`.
- Lista padrão de extensões de código e linguagens de marcação.
- Lista padrão de diretórios ignorados (node_modules, .git, venv, etc.).
- Instrução para IA embutida ao final do dump.
- Geração de hash SHA-256 em arquivo externo.
- Opção `--verificar` para validação de integridade do dump.

---

[2.0.0]: https://github.com/petrinhu/dump_ia/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/petrinhu/dump_ia/releases/tag/v1.0.0
