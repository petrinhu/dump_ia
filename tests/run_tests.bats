#!/usr/bin/env bats
# tests/run_tests.bats — Suite de testes do dump_ia.sh
# Requer: bats-core >= 1.2

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/dump_ia.sh"

# =============================================================================
setup() {
    TMPDIR="$(mktemp -d)"
    mkdir -p "$TMPDIR/src"

    # Projeto mínimo com sinais suficientes para detecção (peso >= 3)
    echo "name = 'projeto-teste'" > "$TMPDIR/pyproject.toml"
    echo "# Projeto de teste"     > "$TMPDIR/README.md"
    printf 'def hello():\n    return "hello"\n' > "$TMPDIR/src/main.py"
    printf 'def test_hello():\n    assert hello() == "hello"\n' > "$TMPDIR/src/test_main.py"
}

teardown() {
    rm -rf "$TMPDIR"
}

# =============================================================================
# Argumentos e ajuda
# =============================================================================

@test "--help exibe texto de uso e sai com 0" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Uso:"* ]]
    [[ "$output" == *"--pasta"* ]]
    [[ "$output" == *"--verificar"* ]]
}

@test "opção desconhecida retorna erro" {
    run bash "$SCRIPT" --opcao-que-nao-existe
    [ "$status" -eq 1 ]
}

@test "--pasta com diretório inexistente retorna erro" {
    run bash "$SCRIPT" --pasta "/caminho/que/nao/existe/jamais"
    [ "$status" -eq 1 ]
}

@test "--output com diretório inexistente retorna erro" {
    run bash "$SCRIPT" --pasta "$TMPDIR" --output "/caminho/invalido/x"
    [ "$status" -eq 1 ]
}

@test "--max-size com valor não numérico retorna erro" {
    run bash "$SCRIPT" --pasta "$TMPDIR" --max-size "abc"
    [ "$status" -eq 1 ]
}

@test "--hash com algoritmo inválido retorna erro" {
    run bash "$SCRIPT" --pasta "$TMPDIR" --hash md5
    [ "$status" -eq 1 ]
}

# =============================================================================
# Geração do dump
# =============================================================================

@test "gera arquivo .log no diretório de saída" {
    run bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    [ "$status" -eq 0 ]
    local count
    count=$(ls "$TMPDIR"/dump_ia_*.log 2>/dev/null | wc -l)
    [ "$count" -gt 0 ]
}

@test "gera arquivo .sha256 no diretório de saída" {
    run bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    [ "$status" -eq 0 ]
    local count
    count=$(ls "$TMPDIR"/dump_ia_*.sha256 2>/dev/null | wc -l)
    [ "$count" -gt 0 ]
}

@test "--hash sha512 gera arquivo .sha512" {
    run bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet --hash sha512
    [ "$status" -eq 0 ]
    local count
    count=$(ls "$TMPDIR"/dump_ia_*.sha512 2>/dev/null | wc -l)
    [ "$count" -gt 0 ]
}

@test "dump contém cabeçalho com DUMP_IA" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    grep -q "DUMP_IA" "$dump"
}

@test "dump contém seção de árvore de pastas" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    grep -q "ÁRVORE DE PASTAS" "$dump"
}

@test "dump contém seção de conteúdo dos arquivos" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    grep -q "CONTEÚDO DOS ARQUIVOS" "$dump"
}

@test "dump contém instruções para IA" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    grep -q "INSTRUÇÕES PARA RETOMADA" "$dump"
}

@test "dump inclui conteúdo de arquivo .py" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    grep -q "src/main.py" "$dump"
}

@test "dump inclui conteúdo de arquivo .md" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    grep -q "README.md" "$dump"
}

# =============================================================================
# Extensões e filtros
# =============================================================================

@test "--ext adiciona extensão extra ao dump" {
    echo "query { hello }" > "$TMPDIR/src/schema.graphql"
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet --ext graphql
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    grep -q "schema.graphql" "$dump"
}

@test "extensão não incluída não aparece no dump sem --ext" {
    echo "query { hello }" > "$TMPDIR/src/schema.graphql"
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    # graphql não está nas extensões padrão
    run grep -c "schema.graphql" "$dump"
    [ "$output" -eq 0 ]
}

@test "--max-size ignora arquivos grandes e gera erros.log" {
    # Cria arquivo de ~2KB
    dd if=/dev/zero bs=1024 count=2 2>/dev/null | tr '\0' 'x' > "$TMPDIR/src/grande.py"
    run bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet --max-size 1
    [ "$status" -eq 0 ]
    local erros
    erros=$(ls "$TMPDIR"/dump_ia_*_erros.log 2>/dev/null | wc -l)
    [ "$erros" -gt 0 ]
}

@test "erros.log não é criado quando não há erros" {
    run bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    [ "$status" -eq 0 ]
    local erros
    erros=$(ls "$TMPDIR"/dump_ia_*_erros.log 2>/dev/null | wc -l)
    [ "$erros" -eq 0 ]
}

# =============================================================================
# Verificação de hash
# =============================================================================

@test "--verificar confirma integridade de dump válido" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    run bash "$SCRIPT" --verificar "$dump"
    [ "$status" -eq 0 ]
}

@test "--verificar detecta dump corrompido" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    echo "linha injetada para corromper o dump" >> "$dump"
    run bash "$SCRIPT" --verificar "$dump"
    [ "$status" -eq 1 ]
}

@test "--verificar retorna erro se arquivo de hash não existe" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    # Remove o arquivo de hash
    rm -f "$TMPDIR"/dump_ia_*.sha256 "$TMPDIR"/dump_ia_*.sha512
    run bash "$SCRIPT" --verificar "$dump"
    [ "$status" -eq 1 ]
}

@test "--verificar sha512 confirma integridade" {
    bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet --hash sha512
    local dump
    dump=$(ls "$TMPDIR"/dump_ia_*.log | head -1)
    run bash "$SCRIPT" --verificar "$dump"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Modos de output
# =============================================================================

@test "--quiet não produz output no stdout" {
    run bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" --quiet
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "sem --quiet produz output no stderr" {
    run bash "$SCRIPT" --pasta "$TMPDIR" --output "$TMPDIR" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[INFO]"* ]]
}
