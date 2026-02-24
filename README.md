# dump_ia

> Nunca perca o contexto de desenvolvimento novamente.

[![Versão](https://img.shields.io/badge/versão-2.0.0-blue?style=flat-square)](CHANGELOG.md)
[![Licença](https://img.shields.io/badge/licença-MIT-green?style=flat-square)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.4%2B-lightgrey?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Plataforma](https://img.shields.io/badge/plataforma-linux%20|%20macos-lightgrey?style=flat-square)](https://github.com/petrinhu/dump_ia)
[![PRs bem-vindos](https://img.shields.io/badge/PRs-bem--vindos-brightgreen?style=flat-square)](CONTRIBUTING.md)

---

`dump_ia` é um script bash que exporta todo o código e a documentação do seu
projeto em **um único arquivo portátil**, pronto para ser enviado a qualquer IA
— permitindo que ela retome exatamente de onde parou, sem perda de contexto.

Ideal para projetos extensos onde o limite de tokens de uma conversa não é
suficiente para manter o histórico completo do desenvolvimento.

---

## Como funciona

```
seu projeto/          dump_ia.sh           dump_ia_23022026_143012.log
├── src/          ──────────────►   ┌─ cabeçalho + opções utilizadas
├── tests/                          ├─ árvore de diretórios
├── README.md                       ├─ conteúdo de todos os arquivos
└── ...                             └─ instruções para a IA retomar
                                   dump_ia_23022026_143012.sha256
```

Envie o `.log` para a IA. Ela lê, entende o projeto inteiro e continua
o trabalho de onde parou.

---

## Funcionalidades

- **Detecção inteligente de projetos** — sistema de pesos analisa +50 sinais
  (VCS, manifestos, CI/CD, lockfiles, pastas estruturais, quantidade de código)
  para confirmar se a pasta é realmente um projeto antes de gerar o dump

- **Suporte a +40 tipos de arquivo** — Python, JavaScript, TypeScript, Go,
  Rust, Java, C/C++, Ruby, PHP, C#, Dart, Kotlin, Swift, Lua, Vue, Svelte,
  SQL, YAML, TOML, Terraform, PlantUML, Drawio e mais

- **Conversão automática de encoding** — arquivos não-UTF-8 são detectados e
  convertidos via `iconv` antes de entrar no dump; falhas são registradas em
  log separado

- **Verificação de integridade** — gera hash SHA-256 ou SHA-512 do dump e
  permite verificar que o arquivo não foi alterado

- **Árvore de diretórios** — exibe a estrutura completa do projeto no início
  do dump (usa `tree` ou `find` como fallback automático)

- **Relatório de erros separado** — arquivos ignorados por tamanho ou com
  problemas de encoding são listados em `_erros.log` com timestamp

- **Modo silencioso** — `--quiet` suprime todo output, ideal para pipelines
  e scripts automatizados

- **Zero dependências obrigatórias além de coreutils** — `tree` e `iconv`
  são opcionais com fallback automático

---

## Requisitos

| Dependência | Obrigatório | Uso |
|-------------|-------------|-----|
| bash 4.4+   | Sim         | Execução |
| coreutils   | Sim         | sha256sum / sha512sum |
| tree        | Não         | Árvore de diretórios (fallback: find) |
| iconv       | Não         | Conversão de encoding |
| file        | Não         | Detecção de encoding |

---

## Instalação

```bash
curl -O https://raw.githubusercontent.com/petrinhu/dump_ia/main/dump_ia.sh
chmod +x dump_ia.sh
```

Ou clone o repositório:

```bash
git clone https://github.com/petrinhu/dump_ia.git
cd dump_ia
chmod +x dump_ia.sh
```

---

## Uso

### Básico — dentro da pasta do projeto

```bash
./dump_ia.sh
```

Gera `dump_ia_DDMMYYYY_HHMMSS.log` e `dump_ia_DDMMYYYY_HHMMSS.sha256` no
diretório atual.

### Especificando pasta e destino

```bash
./dump_ia.sh --pasta ~/meus-projetos/minha-api --output ~/dumps
```

### Adicionando extensões específicas do projeto

```bash
./dump_ia.sh --ext graphql,proto,svelte
```

### Ignorando pastas adicionais

```bash
./dump_ia.sh --ignorar uploads,tmp,logs
```

### Limitando tamanho de arquivo e usando SHA-512

```bash
./dump_ia.sh --max-size 200 --hash sha512
```

### Verificando integridade de um dump

```bash
./dump_ia.sh --verificar dump_ia_23022026_143012.log
```

### Uso em pipeline (sem output)

```bash
./dump_ia.sh --pasta ./projeto --output ./backups --quiet
```

### Ver progresso em tempo real

```bash
./dump_ia.sh --verbose
```

---

## Opções

| Opção | Forma curta | Padrão | Descrição |
|-------|-------------|--------|-----------|
| `--pasta <dir>` | `-p` | `.` | Pasta raiz do projeto |
| `--output <dir>` | `-o` | `.` | Pasta de saída do dump |
| `--ext <ext,...>` | `-e` | — | Extensões adicionais às padrão |
| `--ignorar <dir,...>` | `-i` | — | Diretórios adicionais a ignorar |
| `--max-size <kb>` | `-s` | `500` | Tamanho máximo por arquivo em KB |
| `--hash <algo>` | — | `sha256` | `sha256` ou `sha512` |
| `--verificar <arquivo>` | `-v` | — | Verifica integridade de dump existente |
| `--quiet` | `-q` | — | Suprime todo output do terminal |
| `--verbose` | — | — | Exibe cada arquivo processado |
| `--help` | `-h` | — | Exibe a ajuda completa |

---

## Estrutura do arquivo gerado

```
dump_ia_DDMMYYYY_HHMMSS.log
├── Cabeçalho
│   ├── O que é este arquivo
│   ├── Data, hora, host e projeto
│   └── Opções utilizadas na geração
├── Árvore de pastas
├── Conteúdo dos arquivos
│   └── [N/total] caminho/relativo/arquivo.ext
│       conteúdo completo...
└── Instruções para retomada por IA

dump_ia_DDMMYYYY_HHMMSS.sha256      ← hash do log completo
dump_ia_DDMMYYYY_HHMMSS_erros.log   ← apenas se houver erros
```

---

## Boas práticas

Adicione ao `.gitignore` do projeto para não versionar os dumps gerados:

```gitignore
dump_ia_*.log
dump_ia_*.sha256
dump_ia_*.sha512
dump_ia_*_erros.log
```

Verifique sempre a integridade antes de enviar o dump para uma IA:

```bash
./dump_ia.sh --verificar dump_ia_*.log && echo "Dump íntegro"
```

---

## Roadmap

- [ ] Pacote RPM para distribuição em sistemas baseados em Red Hat
- [ ] Suporte a `.gitignore` como filtro automático de exclusão
- [ ] Modo interativo para seleção de arquivos
- [ ] Integração com APIs de IA (envio direto do dump)

---

## Contribuindo

Contribuições são bem-vindas. Leia o [CONTRIBUTING.md](CONTRIBUTING.md) para
entender o processo, as convenções de código e como rodar os testes.

---

## Segurança

Encontrou uma vulnerabilidade? Leia a [política de segurança](SECURITY.md)
e reporte de forma responsável em **petrinhu@yahoo.com.br**.

---

## Licença

MIT © 2026 Petrus Silva Costa — veja o arquivo [LICENSE](LICENSE).
