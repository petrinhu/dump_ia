#!/usr/bin/env bash
# dump_ia.sh — Gera dump completo de projeto para retomada de contexto por IA
set -euo pipefail

VERSAO="2.0.0"

# =============================================================================
# CONFIGURAÇÕES PADRÃO
# =============================================================================
PASTA="."
OUTPUT_DIR="."
ALGO_HASH="sha256"
MAX_SIZE_KB=500
EXTENSOES_EXTRA=()
IGNORAR_EXTRA=()
VERIFICAR=""
QUIET=false
VERBOSE=false

EXTENSOES_PADRAO=(
    md txt rst
    py pyw
    js mjs cjs ts jsx tsx
    sh bash zsh fish
    go
    rs
    c h cpp hpp cc hh
    java
    rb
    php
    cs
    dart kt swift
    r
    lua
    vue svelte
    css scss sass less
    html htm xml svg
    json jsonc yaml yml toml ini cfg conf
    sql
    proto
    puml drawio
    lock
    env example
    dockerfile makefile
    tf tfvars
    gradle
)

IGNORAR_PADRAO=(
    .git
    node_modules
    __pycache__
    venv .venv env .env
    dist build out
    .next .nuxt .svelte-kit
    target
    .cache .tmp tmp
    coverage .coverage
    .pytest_cache .mypy_cache .ruff_cache
    vendor
    .idea .vscode
    "*.egg-info"
)

# =============================================================================
# FUNÇÕES DE UTILIDADE
# =============================================================================

uso() {
    cat <<EOF
Uso: $(basename "$0") [OPÇÕES]

Gera um dump completo de um projeto para retomada de contexto por IA.
Inclui árvore de diretórios, conteúdo de todos os arquivos de código e
documentação, e instruções para a IA retomar o desenvolvimento do zero.

OPÇÕES:
  -p, --pasta      <dir>      Pasta raiz do projeto           (padrão: diretório atual)
  -o, --output     <dir>      Pasta de saída                  (padrão: diretório atual)
  -e, --ext        <ext,...>  Extensões adicionais            (ex: proto,graphql)
  -i, --ignorar    <dir,...>  Diretórios adicionais a ignorar (ex: tmp,logs)
  -s, --max-size   <kb>       Tamanho máximo por arquivo em KB (padrão: 500)
      --hash       <algo>     Algoritmo de hash: sha256 ou sha512 (padrão: sha256)
  -v, --verificar  <arquivo>  Verifica a integridade de um dump existente
  -q, --quiet                 Suprime todo output do terminal
      --verbose               Mostra cada arquivo sendo processado
  -h, --help                  Exibe esta ajuda e sai

EXEMPLOS:
  $(basename "$0")
  $(basename "$0") --pasta ~/meu-projeto
  $(basename "$0") --pasta ./app --output ~/dumps
  $(basename "$0") --pasta . --ignorar tmp,logs --max-size 200
  $(basename "$0") --pasta . --ext graphql --hash sha512 --verbose
  $(basename "$0") --verificar dump_ia_23022026_143000.log

SAÍDA:
  dump_ia_DDMMYYYY_HHMMSS.log         Dump completo do projeto
  dump_ia_DDMMYYYY_HHMMSS.sha256      Hash de verificação (ou .sha512)
  dump_ia_DDMMYYYY_HHMMSS_erros.log   Erros de leitura e encoding (se houver)

EXTENSÕES INCLUÍDAS POR PADRÃO:
  Documentação : md, txt, rst
  Python       : py, pyw
  JavaScript   : js, mjs, cjs, ts, jsx, tsx
  Shell        : sh, bash, zsh, fish
  Go           : go
  Rust         : rs
  C/C++        : c, h, cpp, hpp, cc, hh
  Java         : java
  Ruby         : rb  |  PHP: php  |  C#: cs
  Outros       : dart, kt, swift, r, lua, vue, svelte
  Web          : css, scss, sass, less, html, htm, xml, svg
  Config       : json, jsonc, yaml, yml, toml, ini, cfg, conf, lock
  Infra        : tf, tfvars, gradle
  Banco        : sql  |  Proto: proto
  Diagramas    : puml, drawio
  Outros       : env, example, dockerfile, makefile
EOF
}

erro() {
    echo "[ERRO] $*" >&2
    exit 1
}

aviso() {
    $QUIET || echo "[AVISO] $*" >&2
}

info() {
    $QUIET || echo "[INFO] $*" >&2
}

verbose_msg() {
    if ! $QUIET && $VERBOSE; then
        echo "[FILE] $*" >&2
    fi
}

glob_existe() {
    compgen -G "$1" > /dev/null 2>&1
}

# =============================================================================
# PARSE DE ARGUMENTOS
# =============================================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--pasta)
            [[ -n "${2:-}" ]] || erro "--pasta requer um argumento."
            PASTA="$2"; shift 2 ;;
        -o|--output)
            [[ -n "${2:-}" ]] || erro "--output requer um argumento."
            OUTPUT_DIR="$2"; shift 2 ;;
        -e|--ext)
            [[ -n "${2:-}" ]] || erro "--ext requer um argumento."
            IFS=',' read -ra EXTENSOES_EXTRA <<< "$2"; shift 2 ;;
        -i|--ignorar)
            [[ -n "${2:-}" ]] || erro "--ignorar requer um argumento."
            IFS=',' read -ra IGNORAR_EXTRA <<< "$2"; shift 2 ;;
        -s|--max-size)
            [[ -n "${2:-}" ]] || erro "--max-size requer um argumento."
            [[ "$2" =~ ^[0-9]+$ ]] || erro "--max-size deve ser um número inteiro positivo."
            MAX_SIZE_KB="$2"; shift 2 ;;
        --hash)
            [[ -n "${2:-}" ]] || erro "--hash requer um argumento."
            case "$2" in
                sha256|sha512) ALGO_HASH="$2" ;;
                *) erro "Algoritmo inválido: '$2'. Use sha256 ou sha512." ;;
            esac
            shift 2 ;;
        -v|--verificar)
            [[ -n "${2:-}" ]] || erro "--verificar requer um arquivo como argumento."
            VERIFICAR="$2"; shift 2 ;;
        -q|--quiet)
            QUIET=true; shift ;;
        --verbose)
            VERBOSE=true; shift ;;
        -h|--help)
            uso; exit 0 ;;
        --)
            shift; break ;;
        -*)
            erro "Opção desconhecida: '$1'. Use --help para ver as opções disponíveis." ;;
        *)
            break ;;
    esac
done

# quiet tem precedência sobre verbose
$QUIET && VERBOSE=false || true

# =============================================================================
# MODO VERIFICAÇÃO
# =============================================================================
if [[ -n "$VERIFICAR" ]]; then
    [[ -f "$VERIFICAR" ]] || erro "Arquivo não encontrado: '$VERIFICAR'"

    BASE="${VERIFICAR%.log}"
    HASH_FILE=""
    HASH_CMD=""

    if [[ -f "${BASE}.sha256" ]]; then
        HASH_FILE="${BASE}.sha256"
        HASH_CMD="sha256sum"
    elif [[ -f "${BASE}.sha512" ]]; then
        HASH_FILE="${BASE}.sha512"
        HASH_CMD="sha512sum"
    else
        erro "Nenhum arquivo de hash encontrado para '$(basename "$VERIFICAR")'." \
             "Esperado: ${BASE}.sha256 ou ${BASE}.sha512"
    fi

    command -v "$HASH_CMD" &>/dev/null || erro "'$HASH_CMD' não encontrado. Instale coreutils."

    info "Verificando : $(basename "$VERIFICAR")"
    info "Hash        : $(basename "$HASH_FILE")"

    DUMP_DIR="$(dirname "$(realpath "$VERIFICAR")")"

    if (cd "$DUMP_DIR" && "$HASH_CMD" --check "$(basename "$HASH_FILE")" --status); then
        echo
        info "OK — integridade verificada. O dump não foi alterado."
        exit 0
    else
        echo
        echo "[FALHA] O dump foi modificado ou corrompido. O hash não confere." >&2
        exit 1
    fi
fi

# =============================================================================
# VALIDAÇÕES
# =============================================================================
[[ -d "$PASTA" ]]      || erro "Pasta não encontrada: '$PASTA'"
[[ -d "$OUTPUT_DIR" ]] || erro "Pasta de saída não encontrada: '$OUTPUT_DIR'"

if [[ "$ALGO_HASH" == "sha256" ]]; then
    command -v sha256sum &>/dev/null || erro "'sha256sum' não encontrado. Instale coreutils."
else
    command -v sha512sum &>/dev/null || erro "'sha512sum' não encontrado. Instale coreutils."
fi

TREE_DISPONIVEL=false
if command -v tree &>/dev/null; then
    TREE_DISPONIVEL=true
else
    aviso "'tree' não instalado. Usando 'find' como alternativa."
    aviso "Para instalar: apt install tree  /  dnf install tree"
fi

ICONV_DISPONIVEL=false
command -v iconv &>/dev/null && ICONV_DISPONIVEL=true || \
    aviso "'iconv' não encontrado. Arquivos não-UTF-8 serão incluídos sem conversão."

FILE_DISPONIVEL=false
command -v file &>/dev/null && FILE_DISPONIVEL=true || true

# =============================================================================
# DETECÇÃO DE PROJETO (sistema de pesos)
# =============================================================================
DETECCAO_PONTOS=0
DETECCAO_SINAIS=()

detectar_projeto() {
    local pasta="$1"
    local pontos=0

    # --- PESO 3: Controle de versão ---
    for vcs in .git .svn .hg .bzr; do
        if [[ -d "$pasta/$vcs" ]]; then
            pontos=$(( pontos + 3 ))
            DETECCAO_SINAIS+=("VCS: $vcs")
        fi
    done

    # --- PESO 3: Manifestos de pacote (nomes exatos) ---
    local manifestos=(
        package.json pyproject.toml Cargo.toml go.mod pom.xml
        build.gradle build.gradle.kts composer.json Gemfile mix.exs
        pubspec.yaml build.sbt DESCRIPTION stack.yaml Project.toml
    )
    for f in "${manifestos[@]}"; do
        if [[ -f "$pasta/$f" ]]; then
            pontos=$(( pontos + 3 ))
            DETECCAO_SINAIS+=("manifesto: $f")
        fi
    done

    # --- PESO 3: Manifestos com glob ---
    for pat in "*.csproj" "*.sln" "*.cabal" "*.gemspec" "*.xcodeproj"; do
        if glob_existe "$pasta/$pat"; then
            pontos=$(( pontos + 3 ))
            DETECCAO_SINAIS+=("manifesto: $pat")
        fi
    done

    # --- PESO 3: CI/CD (arquivos) ---
    local cicd_files=(
        .gitlab-ci.yml Jenkinsfile .travis.yml
        azure-pipelines.yml .drone.yml bitbucket-pipelines.yml
    )
    for f in "${cicd_files[@]}"; do
        if [[ -f "$pasta/$f" ]]; then
            pontos=$(( pontos + 3 ))
            DETECCAO_SINAIS+=("CI/CD: $f")
        fi
    done

    # --- PESO 3: CI/CD (diretórios) ---
    for d in .github/workflows .circleci; do
        if [[ -d "$pasta/$d" ]]; then
            pontos=$(( pontos + 3 ))
            DETECCAO_SINAIS+=("CI/CD: $d/")
        fi
    done

    # --- PESO 2: Containers e infra ---
    local infra=(
        Dockerfile docker-compose.yml docker-compose.yaml
        Vagrantfile serverless.yml Pulumi.yaml
    )
    for f in "${infra[@]}"; do
        if [[ -f "$pasta/$f" ]]; then
            pontos=$(( pontos + 2 ))
            DETECCAO_SINAIS+=("infra: $f")
        fi
    done
    if glob_existe "$pasta/*.tf"; then
        pontos=$(( pontos + 2 ))
        DETECCAO_SINAIS+=("infra: *.tf")
    fi

    # --- PESO 2: Build alternativo ---
    local build_files=(Makefile CMakeLists.txt meson.build SConstruct BUILD WORKSPACE)
    for f in "${build_files[@]}"; do
        if [[ -f "$pasta/$f" ]]; then
            pontos=$(( pontos + 2 ))
            DETECCAO_SINAIS+=("build: $f")
        fi
    done

    # --- PESO 2: Dependências instaladas ---
    if [[ -d "$pasta/node_modules" ]]; then
        pontos=$(( pontos + 2 ))
        DETECCAO_SINAIS+=("deps: node_modules/")
    fi
    if [[ -d "$pasta/vendor" ]]; then
        pontos=$(( pontos + 2 ))
        DETECCAO_SINAIS+=("deps: vendor/")
    fi

    # --- PESO 2: Lockfiles e arquivos de dependência ---
    local lockfiles=(
        package-lock.json yarn.lock pnpm-lock.yaml Cargo.lock
        Gemfile.lock composer.lock poetry.lock Pipfile.lock go.sum
        requirements.txt Pipfile
    )
    for f in "${lockfiles[@]}"; do
        if [[ -f "$pasta/$f" ]]; then
            pontos=$(( pontos + 2 ))
            DETECCAO_SINAIS+=("deps: $f")
        fi
    done

    # --- PESO 2: Configurações de ferramentas ---
    local toolconfigs=(
        tsconfig.json jsconfig.json .editorconfig setup.cfg
        webpack.config.js webpack.config.ts vite.config.js vite.config.ts
        pytest.ini tox.ini mypy.ini .flake8 .pylintrc
    )
    for f in "${toolconfigs[@]}"; do
        if [[ -f "$pasta/$f" ]]; then
            pontos=$(( pontos + 2 ))
            DETECCAO_SINAIS+=("config: $f")
        fi
    done
    for pat in ".eslintrc*" ".prettierrc*" "babel.config.*" "rollup.config.*"; do
        if glob_existe "$pasta/$pat"; then
            pontos=$(( pontos + 2 ))
            DETECCAO_SINAIS+=("config: $pat")
        fi
    done

    # --- PESO 2: Pastas estruturais comuns ---
    local pastas_estruturais=(src lib pkg tests test spec __tests__ docs .github .gitlab)
    for d in "${pastas_estruturais[@]}"; do
        if [[ -d "$pasta/$d" ]]; then
            pontos=$(( pontos + 2 ))
            DETECCAO_SINAIS+=("pasta: $d/")
        fi
    done

    # --- PESO 2: Documentação de projeto ---
    for f in CONTRIBUTING.md CHANGELOG.md CHANGELOG LICENSE LICENSE.md LICENCE; do
        if [[ -f "$pasta/$f" ]]; then
            pontos=$(( pontos + 2 ))
            DETECCAO_SINAIS+=("doc: $f")
        fi
    done

    # --- PESO 1: README ---
    for f in README.md README.rst README.txt README; do
        if [[ -f "$pasta/$f" ]]; then
            pontos=$(( pontos + 1 ))
            DETECCAO_SINAIS+=("doc: $f")
            break
        fi
    done

    # --- PESO 1: Pastas secundárias ---
    for d in bin scripts dist build out; do
        if [[ -d "$pasta/$d" ]]; then
            pontos=$(( pontos + 1 ))
            DETECCAO_SINAIS+=("pasta: $d/")
        fi
    done

    # --- PESO 1-3: Escala por quantidade de arquivos de código ---
    local exts_codigo=(
        py js ts jsx tsx go rs c cpp h java rb php cs
        dart kt swift vue svelte lua r scala clj ex exs hs elm
    )
    local total_codigo=0
    for ext in "${exts_codigo[@]}"; do
        local n
        n=$(find "$pasta" -maxdepth 4 -name "*.$ext" -type f 2>/dev/null | wc -l)
        total_codigo=$(( total_codigo + n ))
    done

    if (( total_codigo >= 11 )); then
        pontos=$(( pontos + 3 ))
        DETECCAO_SINAIS+=("código: $total_codigo arquivo(s)")
    elif (( total_codigo >= 4 )); then
        pontos=$(( pontos + 2 ))
        DETECCAO_SINAIS+=("código: $total_codigo arquivo(s)")
    elif (( total_codigo >= 1 )); then
        pontos=$(( pontos + 1 ))
        DETECCAO_SINAIS+=("código: $total_codigo arquivo(s)")
    fi

    DETECCAO_PONTOS=$pontos
}

# --- Resolve caminhos absolutos ---
PASTA="$(realpath "$PASTA")"
OUTPUT_DIR="$(realpath "$OUTPUT_DIR")"

# --- Roda detecção ---
info "Analisando: $PASTA"
detectar_projeto "$PASTA"

if (( DETECCAO_PONTOS == 0 )); then
    echo >&2
    echo "[AVISO] Nenhum sinal de projeto reconhecido em: $PASTA" >&2
    echo "        Pode ser uma pasta vazia ou com estrutura desconhecida." >&2
    echo >&2
    if $QUIET; then
        echo "[AVISO] Modo --quiet ativo. Continuando sem confirmação." >&2
    else
        read -r -p "        Deseja continuar mesmo assim? [s/N] " resposta
        [[ "$resposta" =~ ^[sS]$ ]] || { echo "Abortado."; exit 0; }
    fi
elif (( DETECCAO_PONTOS <= 2 )); then
    echo >&2
    echo "[AVISO] Sinais fracos de projeto (pontuação: $DETECCAO_PONTOS)." >&2
    if [[ ${#DETECCAO_SINAIS[@]} -gt 0 ]]; then
        echo "        Sinais encontrados: ${DETECCAO_SINAIS[*]}" >&2
    fi
    echo >&2
    if $QUIET; then
        echo "[AVISO] Modo --quiet ativo. Continuando sem confirmação." >&2
    else
        read -r -p "        Deseja continuar mesmo assim? [s/N] " resposta
        [[ "$resposta" =~ ^[sS]$ ]] || { echo "Abortado."; exit 0; }
    fi
else
    if [[ ${#DETECCAO_SINAIS[@]} -gt 0 ]]; then
        info "Projeto detectado (pontuação: $DETECCAO_PONTOS) — ${DETECCAO_SINAIS[0]}"
    else
        info "Projeto detectado (pontuação: $DETECCAO_PONTOS)"
    fi
fi

# =============================================================================
# PREPARA VARIÁVEIS DE SAÍDA
# =============================================================================
TIMESTAMP="$(date +%d%m%Y_%H%M%S)"
NOME_BASE="dump_ia_${TIMESTAMP}"
ARQUIVO_DUMP="${OUTPUT_DIR}/${NOME_BASE}.log"
ARQUIVO_HASH="${OUTPUT_DIR}/${NOME_BASE}.${ALGO_HASH}"
ARQUIVO_ERROS="${OUTPUT_DIR}/${NOME_BASE}_erros.log"

TODAS_EXTS=("${EXTENSOES_PADRAO[@]}" "${EXTENSOES_EXTRA[@]}")
TODOS_IGNORAR=("${IGNORAR_PADRAO[@]}" "${IGNORAR_EXTRA[@]}")

# =============================================================================
# MONTA ARGUMENTOS PARA find
# =============================================================================
prune_args=()
for d in "${TODOS_IGNORAR[@]}"; do
    [[ ${#prune_args[@]} -gt 0 ]] && prune_args+=(-o)
    prune_args+=(-name "$d")
done

ext_args=()
for ext in "${TODAS_EXTS[@]}"; do
    [[ ${#ext_args[@]} -gt 0 ]] && ext_args+=(-o)
    ext_args+=(-iname "*.$ext")
done

tree_ignore=$(IFS='|'; echo "${TODOS_IGNORAR[*]}")

# =============================================================================
# COLETA ARQUIVOS
# =============================================================================
info "Escaneando arquivos..."

ARQUIVOS=()
while IFS= read -r -d '' arquivo; do
    ARQUIVOS+=("$arquivo")
done < <(
    find "$PASTA" \
        \( "${prune_args[@]}" \) -prune \
        -o \( "${ext_args[@]}" \) -type f -print0 \
    | sort -z
)

TOTAL_ENCONTRADOS=${#ARQUIVOS[@]}
info "Arquivos encontrados: $TOTAL_ENCONTRADOS"

# =============================================================================
# INCLUSÃO DE ARQUIVO COM CONVERSÃO DE ENCODING
# =============================================================================
ERROS_COUNT=0
IGNORADOS_TAMANHO=0

incluir_arquivo() {
    local arquivo="$1"
    local caminho_rel="${arquivo#${PASTA}/}"

    if ! $ICONV_DISPONIVEL; then
        cat "$arquivo"
        return 0
    fi

    # Já é UTF-8 válido?
    if iconv -f UTF-8 -t UTF-8 "$arquivo" > /dev/null 2>&1; then
        cat "$arquivo"
        return 0
    fi

    # Tenta detectar encoding com 'file'
    local encoding=""
    if $FILE_DISPONIVEL; then
        encoding=$(file --mime-encoding "$arquivo" 2>/dev/null \
            | awk -F': ' '{print $2}' | tr -d '[:space:]')
        case "$encoding" in
            binary|unknown-8bit|"") encoding="" ;;
        esac
    fi

    # Tenta converter com encoding detectado
    if [[ -n "$encoding" ]]; then
        local convertido
        if convertido=$(iconv -f "$encoding" -t UTF-8//TRANSLIT "$arquivo" 2>/dev/null); then
            echo "$convertido"
            aviso "Encoding convertido ($encoding → UTF-8): $caminho_rel"
            return 0
        fi
    fi

    # Fallback: tenta encodings comuns
    for enc in ISO-8859-1 CP1252 ISO-8859-15 LATIN1; do
        local convertido
        if convertido=$(iconv -f "$enc" -t UTF-8//TRANSLIT "$arquivo" 2>/dev/null); then
            echo "$convertido"
            aviso "Encoding convertido ($enc → UTF-8): $caminho_rel"
            return 0
        fi
    done

    # Falha total — registra erro e insere marcador no dump
    echo "[CONTEÚDO NÃO DISPONÍVEL — encoding não reconhecido]"
    printf "%s | encoding inválido | %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$caminho_rel" >> "$ARQUIVO_ERROS"
    ERROS_COUNT=$(( ERROS_COUNT + 1 ))
    return 0
}

# =============================================================================
# GERAÇÃO DO DUMP
# =============================================================================
info "Gerando: $ARQUIVO_DUMP"

# Prepara strings de opções para o cabeçalho
if [[ ${#EXTENSOES_EXTRA[@]} -gt 0 ]]; then
    EXTS_EXTRA_STR=$(IFS=', '; echo "${EXTENSOES_EXTRA[*]}")
else
    EXTS_EXTRA_STR="(nenhuma)"
fi

if [[ ${#IGNORAR_EXTRA[@]} -gt 0 ]]; then
    IGNORAR_EXTRA_STR=$(IFS=', '; echo "${IGNORAR_EXTRA[*]}")
else
    IGNORAR_EXTRA_STR="(nenhum)"
fi

{
    # --------------------------------------------------------------------------
    # CABEÇALHO
    # --------------------------------------------------------------------------
    echo "==============================================================================="
    printf " DUMP_IA v%s\n" "$VERSAO"
    echo "==============================================================================="
    echo
    echo " O QUE É ESTE ARQUIVO"
    echo " Este é um dump completo de um projeto de software, gerado pelo script"
    echo " dump_ia.sh. Contém a árvore de diretórios e o conteúdo integral dos"
    echo " arquivos de código e documentação, para que uma IA possa retomar o"
    echo " desenvolvimento com contexto completo a partir deste arquivo."
    echo
    echo "-------------------------------------------------------------------------------"
    printf " Gerado em            : %s\n" "$(date '+%d/%m/%Y %H:%M:%S')"
    printf " Host                 : %s@%s\n" "$(whoami)" "$(hostname)"
    printf " Projeto              : %s\n" "$PASTA"
    printf " Saída                : %s\n" "$OUTPUT_DIR"
    echo "-------------------------------------------------------------------------------"
    printf " Tamanho máx/arquivo  : %dKB\n" "$MAX_SIZE_KB"
    printf " Algoritmo de hash    : %s\n" "${ALGO_HASH^^}"
    printf " Extensões adicionais : %s\n" "$EXTS_EXTRA_STR"
    printf " Dirs ignorados extra : %s\n" "$IGNORAR_EXTRA_STR"
    echo "-------------------------------------------------------------------------------"
    printf " Arquivos encontrados : %d\n" "$TOTAL_ENCONTRADOS"
    echo "==============================================================================="
    echo

    # --------------------------------------------------------------------------
    # ÁRVORE DE DIRETÓRIOS
    # --------------------------------------------------------------------------
    echo "=== ÁRVORE DE PASTAS ==="
    echo

    if $TREE_DISPONIVEL; then
        tree -a --noreport -I "$tree_ignore" "$PASTA"
    else
        find "$PASTA" \
            \( "${prune_args[@]}" \) -prune \
            -o -print \
        | sort \
        | sed "s|^${PASTA}|.|"
    fi

    echo
    echo "==============================================================================="
    echo

    # --------------------------------------------------------------------------
    # CONTEÚDO DOS ARQUIVOS
    # --------------------------------------------------------------------------
    echo "=== CONTEÚDO DOS ARQUIVOS ==="
    echo

    CONTADOR=0

    for arquivo in "${ARQUIVOS[@]}"; do
        tamanho_bytes=$(wc -c < "$arquivo")
        tamanho_kb=$(( tamanho_bytes / 1024 ))
        caminho_relativo="${arquivo#${PASTA}/}"

        if (( tamanho_kb > MAX_SIZE_KB )); then
            aviso "Ignorando (${tamanho_kb}KB > ${MAX_SIZE_KB}KB): $caminho_relativo"
            IGNORADOS_TAMANHO=$(( IGNORADOS_TAMANHO + 1 ))
            printf "%s | tamanho %dKB > %dKB | %s\n" \
                "$(date '+%Y-%m-%d %H:%M:%S')" "$tamanho_kb" "$MAX_SIZE_KB" \
                "$caminho_relativo" >> "$ARQUIVO_ERROS"
            continue
        fi

        CONTADOR=$(( CONTADOR + 1 ))
        verbose_msg "[$CONTADOR/$TOTAL_ENCONTRADOS] $caminho_relativo (${tamanho_kb}KB)"

        echo "-------------------------------------------------------------------------------"
        printf " [%d/%d] %s\n" "$CONTADOR" "$TOTAL_ENCONTRADOS" "$caminho_relativo"
        echo "-------------------------------------------------------------------------------"
        echo

        incluir_arquivo "$arquivo"
        echo

    done

    if (( IGNORADOS_TAMANHO > 0 || ERROS_COUNT > 0 )); then
        echo "-------------------------------------------------------------------------------"
        if (( IGNORADOS_TAMANHO > 0 )); then
            printf " %d arquivo(s) ignorado(s) por exceder %dKB (ajuste com --max-size)\n" \
                "$IGNORADOS_TAMANHO" "$MAX_SIZE_KB"
        fi
        if (( ERROS_COUNT > 0 )); then
            printf " %d arquivo(s) com erro de encoding (ver: %s)\n" \
                "$ERROS_COUNT" "$(basename "$ARQUIVO_ERROS")"
        fi
        echo "-------------------------------------------------------------------------------"
        echo
    fi

    # --------------------------------------------------------------------------
    # INSTRUÇÕES PARA IA
    # --------------------------------------------------------------------------
    echo "==============================================================================="
    echo "=== INSTRUÇÕES PARA RETOMADA DE CONTEXTO POR IA ==="
    echo "==============================================================================="
    echo
    cat <<'INSTRUCOES'
Este arquivo é um dump completo do estado atual de um projeto de software,
gerado automaticamente pelo script dump_ia.sh.

Ele contém a estrutura de diretórios e o conteúdo de todos os arquivos de
código-fonte e documentação relevantes do projeto.

## Por que você está recebendo este arquivo

O contexto de uma sessão de desenvolvimento anterior foi perdido — seja por
limite de tokens, encerramento de conversa, ou troca de assistente. Este dump
permite que você retome o trabalho com pleno conhecimento do estado atual
do projeto.

## Passos recomendados ao receber este dump

1. Leia a seção ÁRVORE DE PASTAS para entender a organização geral do projeto.

2. Localize e leia os arquivos de configuração principais (package.json,
   pyproject.toml, Cargo.toml, go.mod, etc.) para entender as dependências
   e a stack tecnológica adotada.

3. Leia os arquivos README e demais documentos .md para compreender o
   propósito do projeto, decisões de arquitetura e contexto de negócio.

4. Identifique os arquivos centrais da aplicação: entry points, módulos
   principais, rotas, modelos de dados e interfaces públicas.

5. Pergunte ao usuário qual era a tarefa em andamento antes do contexto
   ser perdido, caso ele não informe isso espontaneamente.

## Diretrizes para continuar o desenvolvimento

- Mantenha consistência com os padrões de código, nomenclatura e estrutura
  já estabelecidos no projeto.

- Antes de propor mudanças estruturais ou arquiteturais significativas,
  confirme com o usuário se a direção está alinhada com os objetivos.

- Preste atenção a marcadores TODO, FIXME e HACK no código — eles indicam
  trabalho intencionalmente deixado para depois.

- Ao gerar código novo, siga as mesmas convenções observadas no restante
  do projeto: formatação, organização de imports, tratamento de erros, etc.

- Se houver testes automatizados, certifique-se de que novas implementações
  não quebrem o que já funciona.

INSTRUCOES

    echo
    echo "==============================================================================="
    printf " Arquivos incluídos   : %d\n" "$CONTADOR"
    if (( IGNORADOS_TAMANHO > 0 )); then
        printf " Ignorados (tamanho)  : %d\n" "$IGNORADOS_TAMANHO"
    fi
    if (( ERROS_COUNT > 0 )); then
        printf " Erros de leitura     : %d\n" "$ERROS_COUNT"
    fi
    printf " FIM DO DUMP — %s\n" "$(date '+%d/%m/%Y %H:%M:%S')"
    echo "==============================================================================="

} > "$ARQUIVO_DUMP"

# =============================================================================
# HASH (calculado sobre o log completo)
# =============================================================================
info "Calculando ${ALGO_HASH^^}: $(basename "$ARQUIVO_DUMP")"
if [[ "$ALGO_HASH" == "sha256" ]]; then
    sha256sum "$ARQUIVO_DUMP" > "$ARQUIVO_HASH"
else
    sha512sum "$ARQUIVO_DUMP" > "$ARQUIVO_HASH"
fi

# Remove erros.log se não houve erros
if [[ -f "$ARQUIVO_ERROS" ]] && [[ ! -s "$ARQUIVO_ERROS" ]]; then
    rm -f "$ARQUIVO_ERROS"
fi

# =============================================================================
# RESUMO FINAL
# =============================================================================
TAMANHO_DUMP=$(du -sh "$ARQUIVO_DUMP" | cut -f1)

echo
info "Concluído!"
info "  Dump      : $ARQUIVO_DUMP ($TAMANHO_DUMP)"
info "  Hash      : $ARQUIVO_HASH"
info "  Incluídos : $CONTADOR arquivo(s)"
if (( IGNORADOS_TAMANHO > 0 )); then
    info "  Ignorados : $IGNORADOS_TAMANHO arquivo(s) por tamanho > ${MAX_SIZE_KB}KB"
fi
if (( ERROS_COUNT > 0 )); then
    info "  Erros     : $ERROS_COUNT arquivo(s) — ver $(basename "$ARQUIVO_ERROS")"
fi
