#!/usr/bin/env bash
set -u

# Mini Redis 200-test runner with clear report output.
# Project layout supported:
#   project/include/*.h
#   project/src/*.cpp
#   project/tests/test_mini_redis_200.sh
#
# Run from project root:
#   chmod +x tests/test_mini_redis_200.sh
#   ./tests/test_mini_redis_200.sh
#
# Run from inside tests/:
#   chmod +x test_mini_redis_200.sh
#   ./test_mini_redis_200.sh ..

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ge 1 ]]; then
    PROJECT_DIR="$1"
elif [[ -d "./src" && -d "./include" ]]; then
    PROJECT_DIR="."
elif [[ -d "$SCRIPT_DIR/../src" && -d "$SCRIPT_DIR/../include" ]]; then
    PROJECT_DIR="$SCRIPT_DIR/.."
else
    PROJECT_DIR="."
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
BUILD_DIR="$(mktemp -d)"
BIN="$BUILD_DIR/mini_redis_san"
REPORT="$PROJECT_DIR/tests/test_report_200.txt"
PASS=0
FAIL=0
TEST_NO=0
VALGRIND_STATUS="SKIPPED"

cleanup() {
    rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

mkdir -p "$PROJECT_DIR/tests"

{
    echo "========================================="
    echo "Mini Redis 200-Test Report"
    echo "Date: $(date)"
    echo "Project: $PROJECT_DIR"
    echo "Sanitizer binary: $BIN"
    echo "Report file: $REPORT"
    echo "========================================="
    echo
} > "$REPORT"

log() {
    printf '%s\n' "$1" | tee -a "$REPORT"
}

compile_sanitizer_binary() {
    log "[BUILD] Compiling with AddressSanitizer + UndefinedBehaviorSanitizer..."

    if [[ -d "$PROJECT_DIR/src" && -d "$PROJECT_DIR/include" ]]; then
        g++ -std=c++17 -Wall -Wextra -pedantic -g -O0 \
            -fsanitize=address,undefined -fno-omit-frame-pointer \
            "$PROJECT_DIR"/src/*.cpp \
            -I"$PROJECT_DIR/include" \
            -o "$BIN" >> "$REPORT" 2>&1
    else
        g++ -std=c++17 -Wall -Wextra -pedantic -g -O0 \
            -fsanitize=address,undefined -fno-omit-frame-pointer \
            "$PROJECT_DIR/main.cpp" \
            "$PROJECT_DIR/Parser.cpp" \
            "$PROJECT_DIR/CommandSons.cpp" \
            "$PROJECT_DIR/Database.cpp" \
            "$PROJECT_DIR/Persistence.cpp" \
            -o "$BIN" >> "$REPORT" 2>&1
    fi

    if [[ $? -eq 0 ]]; then
        log "[BUILD] PASSED"
        echo >> "$REPORT"
    else
        log "[BUILD] FAILED"
        log "Open the report for compiler output: $REPORT"
        exit 1
    fi
}

record_pass() {
    PASS=$((PASS + 1))
    printf 'PASS %03d - %s\n' "$TEST_NO" "$1" | tee -a "$REPORT"
}

record_fail() {
    FAIL=$((FAIL + 1))
    {
        printf 'FAIL %03d - %s\n' "$TEST_NO" "$1"
        printf 'Expected:\n%s\n' "$2"
        printf 'Actual:\n%s\n' "$3"
        printf '%s\n' '----------------------------------------'
    } | tee -a "$REPORT"
}

run_program() {
    local input="$1"
    ASAN_OPTIONS=detect_leaks=1:halt_on_error=1:abort_on_error=1 \
    UBSAN_OPTIONS=halt_on_error=1 \
    "$BIN" <<< "$input" 2>&1
}

run_exact() {
    local name="$1"
    local input="$2"
    local expected="$3"
    TEST_NO=$((TEST_NO + 1))

    local actual
    actual="$(run_program "$input")"

    if [[ "$actual" == "$expected" ]]; then
        record_pass "$name"
    else
        record_fail "$name" "$expected" "$actual"
    fi
}

run_contains_all() {
    local name="$1"
    local input="$2"
    shift 2
    TEST_NO=$((TEST_NO + 1))

    local actual
    actual="$(run_program "$input")"

    local missing=""
    for expected_piece in "$@"; do
        if ! grep -Fxq "$expected_piece" <<< "$actual"; then
            missing+="$expected_piece"$'\n'
        fi
    done

    if [[ -z "$missing" ]]; then
        record_pass "$name"
    else
        record_fail "$name" "Output should contain all listed lines" "$actual"$'\nMissing:\n'"$missing"
    fi
}

compile_valgrind_binary() {
    local valgrind_bin="$1"

    if [[ -d "$PROJECT_DIR/src" && -d "$PROJECT_DIR/include" ]]; then
        g++ -std=c++17 -Wall -Wextra -pedantic -g -O0 \
            "$PROJECT_DIR"/src/*.cpp \
            -I"$PROJECT_DIR/include" \
            -o "$valgrind_bin" >> "$REPORT" 2>&1
    else
        g++ -std=c++17 -Wall -Wextra -pedantic -g -O0 \
            "$PROJECT_DIR/main.cpp" \
            "$PROJECT_DIR/Parser.cpp" \
            "$PROJECT_DIR/CommandSons.cpp" \
            "$PROJECT_DIR/Database.cpp" \
            "$PROJECT_DIR/Persistence.cpp" \
            -o "$valgrind_bin" >> "$REPORT" 2>&1
    fi
}

run_valgrind_check() {
    echo >> "$REPORT"
    echo "=========================================" >> "$REPORT"
    echo "VALGRIND CHECK" >> "$REPORT"
    echo "=========================================" >> "$REPORT"

    if ! command -v valgrind >/dev/null 2>&1; then
        VALGRIND_STATUS="SKIPPED - valgrind is not installed"
        echo "Valgrind: $VALGRIND_STATUS" | tee -a "$REPORT"
        return 0
    fi

    local valgrind_bin="$BUILD_DIR/mini_redis_valgrind"
    local valgrind_log="$BUILD_DIR/valgrind.log"

    echo "[VALGRIND] Compiling non-sanitized binary..." >> "$REPORT"
    compile_valgrind_binary "$valgrind_bin"

    # Important: do NOT use EXIT here. EXIT calls std::exit(0), which skips normal
    # destruction of local C++ objects and can produce misleading still-reachable reports.
    printf "SET a 1\nGET a\nSAVE $BUILD_DIR/valgrind_test.txt\nLOAD $BUILD_DIR/valgrind_test.txt\n" | \
    valgrind \
        --leak-check=full \
        --show-leak-kinds=all \
        --error-exitcode=99 \
        "$valgrind_bin" \
        > "$valgrind_log" 2>&1

    cat "$valgrind_log" >> "$REPORT"

    # Valgrind prints either "All heap blocks were freed" OR a leak summary.
    # Accept both clean formats, but still require zero reported errors.
    if grep -q "ERROR SUMMARY: 0 errors" "$valgrind_log" && \
       { grep -q "All heap blocks were freed" "$valgrind_log" || \
         grep -q "definitely lost: 0 bytes" "$valgrind_log"; }; then
        VALGRIND_STATUS="PASSED"
        echo "Valgrind: PASSED" | tee -a "$REPORT"
    else
        VALGRIND_STATUS="FAILED"
        echo "Valgrind: FAILED" | tee -a "$REPORT"
        FAIL=$((FAIL + 1))
    fi
}

compile_sanitizer_binary

tmp_save="$BUILD_DIR/db_save.txt"
tmp_save2="$BUILD_DIR/db_save_2.txt"
corrupt_file="$BUILD_DIR/corrupt.txt"
printf 'bad line without separator\n' > "$corrupt_file"

log "[TESTS] Running 200 behavior tests..."

# 001-010 SET / GET basics
run_exact "SET then GET simple key" $'SET name Mohammed\nGET name' $'OK\nMohammed'
run_exact "GET missing key" $'GET missing' $'(nil)'
run_exact "SET overwrite value" $'SET a one\nSET a two\nGET a' $'OK\nOK\ntwo'
run_exact "SET value with spaces" $'SET full Mohammed AbuSalih\nGET full' $'OK\nMohammed AbuSalih'
run_exact "SET trims outer value spaces" $'SET x     hello world     \nGET x' $'OK\nhello world'
run_exact "SET numeric-looking value" $'SET n 12345\nGET n' $'OK\n12345'
run_exact "SET symbol value" $'SET sym !@#$%^&*()\nGET sym' $'OK\n!@#$%^&*()'
run_exact "SET empty value rejected" $'SET empty' $'Invalid command usage'
run_exact "SET missing args rejected" $'SET' $'Invalid command usage'
run_exact "SET with tab spacing" $'SET\tkey\tvalue\nGET key' $'OK\nvalue'

# 011-020 EXISTS / DEL basics
run_exact "EXISTS true after SET" $'SET a 1\nEXISTS a' $'OK\ntrue'
run_exact "EXISTS false missing" $'EXISTS nope' $'false'
run_exact "EXISTS false after DEL" $'SET a 1\nDEL a\nEXISTS a' $'OK\ndeleted\nfalse'
run_exact "EXISTS invalid no key" $'EXISTS' $'Invalid command usage'
run_exact "EXISTS invalid extra arg" $'EXISTS a b' $'Invalid command usage'
run_exact "DEL existing key" $'SET a 1\nDEL a\nGET a' $'OK\ndeleted\n(nil)'
run_exact "DEL missing key" $'DEL a' $'not found'
run_exact "DEL twice" $'SET a 1\nDEL a\nDEL a' $'OK\ndeleted\nnot found'
run_exact "DEL invalid no key" $'DEL' $'Invalid command usage'
run_exact "DEL invalid extra arg" $'DEL a b' $'Invalid command usage'

# 021-030 RENAME
run_exact "RENAME existing key" $'SET old value\nRENAME old new\nGET new\nGET old' $'OK\nrenamed\nvalue\n(nil)'
run_exact "RENAME missing old key" $'RENAME old new' $'not found'
run_exact "RENAME target already exists" $'SET a 1\nSET b 2\nRENAME a b' $'OK\nOK\ntarget already exists'
run_exact "RENAME preserves value with spaces" $'SET old hello world\nRENAME old new\nGET new' $'OK\nrenamed\nhello world'
run_exact "RENAME invalid no args" $'RENAME' $'Invalid command usage'
run_exact "RENAME invalid one arg" $'RENAME a' $'Invalid command usage'
run_exact "RENAME invalid extra arg" $'RENAME a b c' $'Invalid command usage'
run_exact "RENAME after delete becomes not found" $'SET a 1\nDEL a\nRENAME a b' $'OK\ndeleted\nnot found'
run_exact "RENAME chain" $'SET a 1\nRENAME a b\nRENAME b c\nGET c' $'OK\nrenamed\nrenamed\n1'
run_exact "RENAME same key reports target exists" $'SET a 1\nRENAME a a' $'OK\ntarget already exists'

# 031-036 KEYS
run_contains_all "KEYS includes one key" $'SET a 1\nKEYS' 'OK' 'a'
run_contains_all "KEYS includes multiple keys" $'SET a 1\nSET b 2\nSET c 3\nKEYS' 'OK' 'a' 'b' 'c'
run_exact "KEYS on empty database" $'KEYS' $''
run_exact "KEYS invalid extra arg" $'KEYS x' $'Invalid command usage'
run_contains_all "KEYS after delete contains remaining key" $'SET a 1\nSET b 2\nDEL a\nKEYS' 'OK' 'deleted' 'b'
run_contains_all "KEYS after rename contains new key" $'SET a 1\nRENAME a b\nKEYS' 'OK' 'renamed' 'b'

# 037-051 SAVE / LOAD
run_exact "SAVE creates file" $'SET a 1\nSAVE '"$tmp_save" $'OK\nDatabase saved'
run_exact "LOAD restores simple value" $'SET a 1\nSAVE '"$tmp_save"$'\nDEL a\nLOAD '"$tmp_save"$'\nGET a' $'OK\nDatabase saved\ndeleted\nDatabase loaded\n1'
run_exact "LOAD replaces current database" $'SET a 1\nSAVE '"$tmp_save"$'\nSET b 2\nLOAD '"$tmp_save"$'\nGET b\nGET a' $'OK\nDatabase saved\nOK\nDatabase loaded\n(nil)\n1'
run_exact "SAVE LOAD value with spaces" $'SET msg hello world\nSAVE '"$tmp_save"$'\nDEL msg\nLOAD '"$tmp_save"$'\nGET msg' $'OK\nDatabase saved\ndeleted\nDatabase loaded\nhello world'
run_contains_all "SAVE LOAD multiple keys" $'SET a 1\nSET b 2\nSAVE '"$tmp_save"$'\nDEL a\nDEL b\nLOAD '"$tmp_save"$'\nKEYS' 'OK' 'Database saved' 'deleted' 'Database loaded' 'a' 'b'
run_exact "LOAD missing file" $'LOAD /tmp/this_file_should_not_exist_123456789.txt' $'File error'
run_exact "LOAD corrupted file" $'LOAD '"$corrupt_file" $'Corrupted file'
run_exact "SAVE invalid no filename" $'SAVE' $'Invalid command usage'
run_exact "SAVE invalid extra arg" $'SAVE a b' $'Invalid command usage'
run_exact "LOAD invalid no filename" $'LOAD' $'Invalid command usage'
run_exact "LOAD invalid extra arg" $'LOAD a b' $'Invalid command usage'
run_exact "SAVE bad path" $'SAVE /no_such_directory_hopefully/file.txt' $'File error'
run_exact "SAVE empty database then load" $'SAVE '"$tmp_save"$'\nSET a 1\nLOAD '"$tmp_save"$'\nGET a' $'Database saved\nOK\nDatabase loaded\n(nil)'
run_exact "SAVE after overwrite keeps latest" $'SET a old\nSET a new\nSAVE '"$tmp_save"$'\nSET a changed\nLOAD '"$tmp_save"$'\nGET a' $'OK\nOK\nDatabase saved\nOK\nDatabase loaded\nnew'
run_exact "SAVE after rename keeps new key" $'SET a 1\nRENAME a b\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nGET b\nGET a' $'OK\nrenamed\nDatabase saved\nDatabase loaded\n1\n(nil)'

# 052-061 HISTORY
run_exact "HISTORY empty" $'HISTORY' $''
run_exact "HISTORY after one successful command" $'SET a 1\nHISTORY' $'OK\nSET a 1'
run_exact "HISTORY stores successful GET" $'GET a\nHISTORY' $'(nil)\nGET a'
run_exact "HISTORY does not store failed parse" $'GET\nHISTORY' $'Invalid command usage'
run_exact "HISTORY does not store failed execution" $'LOAD /tmp/this_file_should_not_exist_987.txt\nHISTORY' $'File error'
run_exact "HISTORY invalid extra arg" $'HISTORY x' $'Invalid command usage'
run_exact "HISTORY keeps original spaces" $'   SET a 1   \nHISTORY' $'OK\n   SET a 1   '
run_exact "HISTORY includes SAVE after success" $'SAVE '"$tmp_save"$'\nHISTORY' $'Database saved\nSAVE '"$tmp_save"
run_exact "HISTORY includes RENAME success" $'SET a 1\nRENAME a b\nHISTORY' $'OK\nrenamed\nSET a 1\nRENAME a b'
run_exact "HISTORY limit keeps last 20" $'SET k1 v\nSET k2 v\nSET k3 v\nSET k4 v\nSET k5 v\nSET k6 v\nSET k7 v\nSET k8 v\nSET k9 v\nSET k10 v\nSET k11 v\nSET k12 v\nSET k13 v\nSET k14 v\nSET k15 v\nSET k16 v\nSET k17 v\nSET k18 v\nSET k19 v\nSET k20 v\nSET k21 v\nSET k22 v\nHISTORY' $'OK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nSET k3 v\nSET k4 v\nSET k5 v\nSET k6 v\nSET k7 v\nSET k8 v\nSET k9 v\nSET k10 v\nSET k11 v\nSET k12 v\nSET k13 v\nSET k14 v\nSET k15 v\nSET k16 v\nSET k17 v\nSET k18 v\nSET k19 v\nSET k20 v\nSET k21 v\nSET k22 v'

# 062-068 Unknown/case/empty
run_exact "Unknown command ABC" $'ABC' $'Unknown command'
run_exact "Unknown typo GETT" $'GETT a' $'Unknown command'
run_exact "Lowercase set is unknown" $'set a 1' $'Unknown command'
run_exact "Mixed case Get is unknown" $'Get a' $'Unknown command'
run_exact "Empty line invalid" $'' $'Invalid command usage'
run_exact "Spaces-only line invalid" $'      ' $'Invalid command usage'
run_exact "Tabs-only line invalid" $'\t\t' $'Invalid command usage'

# 069-076 Parser spacing
run_exact "Leading spaces command accepted" $'   SET a 1\nGET a' $'OK\n1'
run_exact "Trailing spaces command accepted" $'SET a 1     \nGET a' $'OK\n1'
run_exact "Multiple inner spaces accepted" $'SET      a      1\nGET     a' $'OK\n1'
run_exact "GET trims key spaces" $'SET a 1\n   GET     a    ' $'OK\n1'
run_exact "DEL trims key spaces" $'SET a 1\n   DEL     a    ' $'OK\ndeleted'
run_exact "RENAME trims args" $'SET a 1\n  RENAME    a     b   \nGET b' $'OK\nrenamed\n1'
run_exact "SAVE trims filename" $'SET a 1\n  SAVE    '"$tmp_save"$'   ' $'OK\nDatabase saved'
run_exact "LOAD trims filename" $'SET a 1\nSAVE '"$tmp_save"$'\nLOAD    '"$tmp_save"$'   \nGET a' $'OK\nDatabase saved\nDatabase loaded\n1'

# 077-084 Value behavior
run_exact "Value can contain equals" $'SET expr a = b\nGET expr' $'OK\na = b'
run_exact "Value can contain many spaces inside" $'SET sentence hello   there   friend\nGET sentence' $'OK\nhello   there   friend'
run_exact "SET first word is key rest is value single command" $'SET my key value' $'OK'
run_exact "SET first word is key rest is value then GET" $'SET my key value\nGET my' $'OK\nkey value'
run_exact "GET full spaced key impossible" $'SET my key value\nGET my key' $'OK\nInvalid command usage'
run_exact "Empty string cannot be key" $'GET    ' $'Invalid command usage'
run_exact "Filename cannot contain spaces in SAVE parser" $'SAVE my file.txt' $'Invalid command usage'
run_exact "Filename cannot contain spaces in LOAD parser" $'LOAD my file.txt' $'Invalid command usage'

# 085-094 Mixed scenarios
run_exact "Mixed CRUD scenario" $'SET a 1\nSET b 2\nGET a\nDEL b\nEXISTS b\nGET b' $'OK\nOK\n1\ndeleted\nfalse\n(nil)'
run_exact "Mixed rename delete scenario" $'SET a alpha\nRENAME a b\nDEL b\nEXISTS b\nGET a' $'OK\nrenamed\ndeleted\nfalse\n(nil)'
run_exact "Load after failed command still works" $'SET a 1\nSAVE '"$tmp_save"$'\nGET\nLOAD '"$tmp_save"$'\nGET a' $'OK\nDatabase saved\nInvalid command usage\nDatabase loaded\n1'
run_exact "Failed rename does not remove old key" $'SET a 1\nSET b 2\nRENAME a b\nGET a\nGET b' $'OK\nOK\ntarget already exists\n1\n2'
run_exact "Delete old after rename not found" $'SET a 1\nRENAME a b\nDEL a\nDEL b' $'OK\nrenamed\nnot found\ndeleted'
run_exact "Overwrite after load" $'SET a 1\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nSET a 2\nGET a' $'OK\nDatabase saved\nDatabase loaded\nOK\n2'
run_exact "Save load after deleting one key" $'SET a 1\nSET b 2\nDEL a\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nGET a\nGET b' $'OK\nOK\ndeleted\nDatabase saved\nDatabase loaded\n(nil)\n2'
run_exact "History after many mixed successes" $'SET a 1\nGET a\nEXISTS a\nDEL a\nHISTORY' $'OK\n1\ntrue\ndeleted\nSET a 1\nGET a\nEXISTS a\nDEL a'
run_exact "History excludes failed middle command" $'SET a 1\nGET\nGET a\nHISTORY' $'OK\nInvalid command usage\n1\nSET a 1\nGET a'
run_exact "Corrupted load does not replace database" $'SET a 1\nLOAD '"$corrupt_file"$'\nGET a' $'OK\nCorrupted file\n1'

# 095-100 Exit and 100-operation stress
run_exact "EXIT command" $'EXIT' $'Goodbye'
run_exact "EXIT invalid extra arg" $'EXIT now' $'Invalid command usage'
run_exact "100 repeated SET commands no leak/crash" "$(for i in $(seq 1 100); do echo "SET key$i value$i"; done; echo 'GET key100')" $"$(for i in $(seq 1 100); do echo 'OK'; done; echo 'value100')"
run_exact "100 repeated GET missing no leak/crash" "$(for i in $(seq 1 100); do echo "GET missing$i"; done)" $"$(for i in $(seq 1 100); do echo '(nil)'; done)"
run_exact "100 repeated DEL missing no leak/crash" "$(for i in $(seq 1 100); do echo "DEL missing$i"; done)" $"$(for i in $(seq 1 100); do echo 'not found'; done)"
run_exact "100 repeated EXISTS missing no leak/crash" "$(for i in $(seq 1 100); do echo "EXISTS missing$i"; done)" $"$(for i in $(seq 1 100); do echo 'false'; done)"

# 101-120 More parser invalid cases
run_exact "GET too many args 1" $'GET a b' $'Invalid command usage'
run_exact "GET too many args 2" $'GET a b c' $'Invalid command usage'
run_exact "GET no args after spaces" $'GET      ' $'Invalid command usage'
run_exact "DEL too many args 1" $'DEL a b' $'Invalid command usage'
run_exact "DEL too many args 2" $'DEL a b c' $'Invalid command usage'
run_exact "EXISTS too many args 1" $'EXISTS a b' $'Invalid command usage'
run_exact "EXISTS too many args 2" $'EXISTS a b c' $'Invalid command usage'
run_exact "RENAME too many args many" $'RENAME a b c d e' $'Invalid command usage'
run_exact "SAVE many spaces no filename" $'SAVE     ' $'Invalid command usage'
run_exact "LOAD many spaces no filename" $'LOAD     ' $'Invalid command usage'
run_exact "KEYS with many args invalid" $'KEYS a b c' $'Invalid command usage'
run_exact "HISTORY with many args invalid" $'HISTORY a b c' $'Invalid command usage'
run_exact "EXIT with many args invalid" $'EXIT a b c' $'Invalid command usage'
run_exact "Unknown with args" $'UNKNOWN a b c' $'Unknown command'
run_exact "Command with lowercase letters unknown" $'Set a 1' $'Unknown command'
run_exact "Command with punctuation unknown" $'GET!' $'Unknown command'
run_exact "Command with number unknown" $'GET1 a' $'Unknown command'
run_exact "Two blank lines invalid twice" $'\n' $'Invalid command usage\nInvalid command usage'
run_exact "Line with carriage return spaces invalid" $'   \r   ' $'Invalid command usage'
run_exact "SET value can begin after tabs" $'SET a\t\tvalue\nGET a' $'OK\nvalue'

# 121-140 More CRUD and rename edge cases
run_exact "Overwrite then delete then get" $'SET a 1\nSET a 2\nDEL a\nGET a' $'OK\nOK\ndeleted\n(nil)'
run_exact "Delete does not affect another key" $'SET a 1\nSET b 2\nDEL a\nGET b' $'OK\nOK\ndeleted\n2'
run_exact "Rename does not affect another key" $'SET a 1\nSET x 9\nRENAME a b\nGET x' $'OK\nOK\nrenamed\n9'
run_exact "Rename old disappears" $'SET old 1\nRENAME old new\nEXISTS old\nEXISTS new' $'OK\nrenamed\nfalse\ntrue'
run_exact "Rename then overwrite new" $'SET a 1\nRENAME a b\nSET b 2\nGET b' $'OK\nrenamed\nOK\n2'
run_exact "Delete renamed key" $'SET a 1\nRENAME a b\nDEL b\nGET b' $'OK\nrenamed\ndeleted\n(nil)'
run_exact "Target exists after delete allowed" $'SET a 1\nSET b 2\nDEL b\nRENAME a b\nGET b' $'OK\nOK\ndeleted\nrenamed\n1'
run_exact "Rename missing does not create target" $'RENAME a b\nGET b' $'not found\n(nil)'
run_exact "Rename value with equals" $'SET a x = y\nRENAME a b\nGET b' $'OK\nrenamed\nx = y'
run_exact "Rename value with tabs preserved as spaces after parse" $'SET a hello\tworld\nRENAME a b\nGET b' $'OK\nrenamed\nhello\tworld'
run_exact "Exists after overwrite" $'SET a 1\nSET a 2\nEXISTS a' $'OK\nOK\ntrue'
run_exact "Exists after failed rename target exists" $'SET a 1\nSET b 2\nRENAME a b\nEXISTS a\nEXISTS b' $'OK\nOK\ntarget already exists\ntrue\ntrue'
run_exact "Del after failed rename removes original" $'SET a 1\nSET b 2\nRENAME a b\nDEL a\nGET a' $'OK\nOK\ntarget already exists\ndeleted\n(nil)'
run_exact "Keys after all deletes empty" $'SET a 1\nSET b 2\nDEL a\nDEL b\nKEYS' $'OK\nOK\ndeleted\ndeleted'
run_contains_all "Keys after overwrite one key" $'SET a 1\nSET a 2\nKEYS' 'OK' 'a'
run_exact "GET after many overwrites" $'SET a 1\nSET a 2\nSET a 3\nSET a 4\nGET a' $'OK\nOK\nOK\nOK\n4'
run_exact "DEL after many overwrites" $'SET a 1\nSET a 2\nSET a 3\nDEL a\nGET a' $'OK\nOK\nOK\ndeleted\n(nil)'
run_exact "EXISTS after load missing" $'SAVE '"$tmp_save"$'\nSET a 1\nLOAD '"$tmp_save"$'\nEXISTS a' $'Database saved\nOK\nDatabase loaded\nfalse'
run_exact "GET after load empty db" $'SAVE '"$tmp_save"$'\nSET a 1\nLOAD '"$tmp_save"$'\nGET a' $'Database saved\nOK\nDatabase loaded\n(nil)'
run_exact "DEL after load empty db" $'SAVE '"$tmp_save"$'\nSET a 1\nLOAD '"$tmp_save"$'\nDEL a' $'Database saved\nOK\nDatabase loaded\nnot found'

# 141-160 Persistence additional tests
run_exact "Save two different files first" $'SET a 1\nSAVE '"$tmp_save"$'\nSET a 2\nSAVE '"$tmp_save2" $'OK\nDatabase saved\nOK\nDatabase saved'
run_exact "Load first saved file" $'SET a 1\nSAVE '"$tmp_save"$'\nSET a 2\nSAVE '"$tmp_save2"$'\nLOAD '"$tmp_save"$'\nGET a' $'OK\nDatabase saved\nOK\nDatabase saved\nDatabase loaded\n1'
run_exact "Load second saved file" $'SET a 1\nSAVE '"$tmp_save"$'\nSET a 2\nSAVE '"$tmp_save2"$'\nLOAD '"$tmp_save2"$'\nGET a' $'OK\nDatabase saved\nOK\nDatabase saved\nDatabase loaded\n2'
run_exact "SET missing value then SAVE still saves empty database" $'SET a\nSAVE '"$tmp_save" $'Invalid command usage\nDatabase saved'
run_exact "Save load symbol heavy value" $'SET s []{}:;,.?/\\|+-_*&^%$#@!\nSAVE '"$tmp_save"$'\nDEL s\nLOAD '"$tmp_save"$'\nGET s' $'OK\nDatabase saved\ndeleted\nDatabase loaded\n[]{}:;,.?/\\|+-_*&^%$#@!'
run_exact "Save load long value" $'SET long abcdefghijklmnopqrstuvwxyz0123456789\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nGET long' $'OK\nDatabase saved\nDatabase loaded\nabcdefghijklmnopqrstuvwxyz0123456789'
run_exact "Load after corrupted file keeps previous key" $'SET keep yes\nLOAD '"$corrupt_file"$'\nGET keep' $'OK\nCorrupted file\nyes'
run_exact "Load missing file keeps previous key" $'SET keep yes\nLOAD /tmp/no_file_mini_redis_55555.txt\nGET keep' $'OK\nFile error\nyes'
run_exact "Save after failed load still saves old db" $'SET keep yes\nLOAD '"$corrupt_file"$'\nSAVE '"$tmp_save"$'\nDEL keep\nLOAD '"$tmp_save"$'\nGET keep' $'OK\nCorrupted file\nDatabase saved\ndeleted\nDatabase loaded\nyes'
run_exact "Save load after deleting all keys" $'SET a 1\nDEL a\nSAVE '"$tmp_save"$'\nSET b 2\nLOAD '"$tmp_save"$'\nGET b' $'OK\ndeleted\nDatabase saved\nOK\nDatabase loaded\n(nil)'
run_contains_all "Save load keys after rename and delete" $'SET a 1\nSET b 2\nRENAME a c\nDEL b\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nKEYS' 'OK' 'renamed' 'deleted' 'Database saved' 'Database loaded' 'c'
run_exact "Repeated save same file latest state" $'SET a 1\nSAVE '"$tmp_save"$'\nSET a 2\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nGET a' $'OK\nDatabase saved\nOK\nDatabase saved\nDatabase loaded\n2'
run_exact "Repeated load same file stable" $'SET a 1\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nGET a' $'OK\nDatabase saved\nDatabase loaded\nDatabase loaded\n1'
run_exact "Load file after changing db replaces all" $'SET a 1\nSAVE '"$tmp_save"$'\nSET b 2\nSET c 3\nLOAD '"$tmp_save"$'\nGET b\nGET c\nGET a' $'OK\nDatabase saved\nOK\nOK\nDatabase loaded\n(nil)\n(nil)\n1'
run_exact "Save load tab value" $'SET t hello\tworld\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nGET t' $'OK\nDatabase saved\nDatabase loaded\nhello\tworld'
run_exact "Save load equals value" $'SET e left=right\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nGET e' $'OK\nDatabase saved\nDatabase loaded\nleft=right'
run_exact "Save load value with separator text" $'SET e left = right\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nGET e' $'OK\nDatabase saved\nDatabase loaded\nleft = right'
run_exact "Bad save path does not kill program" $'SET a 1\nSAVE /no_such_directory_hopefully/file.txt\nGET a' $'OK\nFile error\n1'
run_exact "Bad load path does not kill program" $'SET a 1\nLOAD /no_such_directory_hopefully/file.txt\nGET a' $'OK\nFile error\n1'
run_exact "Save load after many commands" $'SET a 1\nSET b 2\nSET c 3\nDEL b\nRENAME c d\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nGET a\nGET b\nGET d' $'OK\nOK\nOK\ndeleted\nrenamed\nDatabase saved\nDatabase loaded\n1\n(nil)\n3'

# 161-180 History additional tests
run_exact "History includes DEL success" $'SET a 1\nDEL a\nHISTORY' $'OK\ndeleted\nSET a 1\nDEL a'
run_exact "History includes missing GET success" $'GET missing\nHISTORY' $'(nil)\nGET missing'
run_exact "History includes DEL missing success" $'DEL missing\nHISTORY' $'not found\nDEL missing'
run_exact "History includes EXISTS success" $'EXISTS a\nHISTORY' $'false\nEXISTS a'
run_exact "History includes KEYS success" $'KEYS\nHISTORY' $'KEYS'
run_exact "History excludes unknown command" $'ABC\nHISTORY' $'Unknown command'
run_exact "History excludes invalid SAVE" $'SAVE\nHISTORY' $'Invalid command usage'
run_exact "History excludes invalid LOAD" $'LOAD\nHISTORY' $'Invalid command usage'
run_exact "History excludes invalid RENAME" $'RENAME a\nHISTORY' $'Invalid command usage'
run_exact "History after SAVE and LOAD" $'SET a 1\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"$'\nHISTORY' $'OK\nDatabase saved\nDatabase loaded\nSET a 1\nSAVE '"$tmp_save"$'\nLOAD '"$tmp_save"
run_exact "History after failed target rename excludes rename" $'SET a 1\nSET b 2\nRENAME a b\nHISTORY' $'OK\nOK\ntarget already exists\nSET a 1\nSET b 2'
run_exact "History after missing rename includes rename" $'RENAME a b\nHISTORY' $'not found\nRENAME a b'
run_exact "History limit after 21 commands starts at 2" $'SET k1 v\nSET k2 v\nSET k3 v\nSET k4 v\nSET k5 v\nSET k6 v\nSET k7 v\nSET k8 v\nSET k9 v\nSET k10 v\nSET k11 v\nSET k12 v\nSET k13 v\nSET k14 v\nSET k15 v\nSET k16 v\nSET k17 v\nSET k18 v\nSET k19 v\nSET k20 v\nSET k21 v\nHISTORY' $'OK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nOK\nSET k2 v\nSET k3 v\nSET k4 v\nSET k5 v\nSET k6 v\nSET k7 v\nSET k8 v\nSET k9 v\nSET k10 v\nSET k11 v\nSET k12 v\nSET k13 v\nSET k14 v\nSET k15 v\nSET k16 v\nSET k17 v\nSET k18 v\nSET k19 v\nSET k20 v\nSET k21 v'
run_exact "History exactly 20 commands" "$(for i in $(seq 1 20); do echo "SET h$i v"; done; echo HISTORY)" $"$(for i in $(seq 1 20); do echo OK; done; for i in $(seq 1 20); do echo "SET h$i v"; done)"
run_exact "History stores original tabs" $'SET\ta\t1\nHISTORY' $'OK\nSET\ta\t1'
run_exact "History after keys empty" $'KEYS\nHISTORY' $'KEYS'
run_exact "History after command with trailing spaces" $'SET a 1   \nHISTORY' $'OK\nSET a 1   '
run_exact "History after command with leading spaces" $'   GET a\nHISTORY' $'(nil)\n   GET a'
run_exact "History after multiple failed then success" $'GET\nSET\nSET a 1\nHISTORY' $'Invalid command usage\nInvalid command usage\nOK\nSET a 1'
run_exact "History after load corrupted excludes load" $'SET a 1\nLOAD '"$corrupt_file"$'\nHISTORY' $'OK\nCorrupted file\nSET a 1'

# 181-200 Bigger stress tests
run_exact "200 repeated SET commands" "$(for i in $(seq 1 200); do echo "SET key$i value$i"; done; echo 'GET key200')" $"$(for i in $(seq 1 200); do echo OK; done; echo value200)"
run_exact "200 repeated GET existing commands" "$(echo 'SET a value'; for i in $(seq 1 200); do echo 'GET a'; done)" $"$(echo OK; for i in $(seq 1 200); do echo value; done)"
run_exact "200 repeated overwrite same key" "$(for i in $(seq 1 200); do echo "SET a value$i"; done; echo 'GET a')" $"$(for i in $(seq 1 200); do echo OK; done; echo value200)"
run_exact "200 repeated DEL missing" "$(for i in $(seq 1 200); do echo "DEL missing$i"; done)" $"$(for i in $(seq 1 200); do echo 'not found'; done)"
run_exact "200 repeated EXISTS missing" "$(for i in $(seq 1 200); do echo "EXISTS missing$i"; done)" $"$(for i in $(seq 1 200); do echo false; done)"
run_exact "200 keys save load one check" "$(for i in $(seq 1 200); do echo "SET k$i v$i"; done; echo "SAVE $tmp_save"; echo "LOAD $tmp_save"; echo 'GET k199')" $"$(for i in $(seq 1 200); do echo OK; done; echo 'Database saved'; echo 'Database loaded'; echo 'v199')"
run_exact "50 rename chain" "$(echo 'SET k v'; prev=k; for i in $(seq 1 50); do echo "RENAME $prev k$i"; prev=k$i; done; echo 'GET k50')" $"$(echo OK; for i in $(seq 1 50); do echo renamed; done; echo v)"
run_exact "50 set delete cycle" "$(for i in $(seq 1 50); do echo "SET c$i v$i"; echo "DEL c$i"; done; echo 'GET c50')" $"$(for i in $(seq 1 50); do echo OK; echo deleted; done; echo '(nil)')"
run_exact "50 set exists cycle" "$(for i in $(seq 1 50); do echo "SET e$i v$i"; echo "EXISTS e$i"; done)" $"$(for i in $(seq 1 50); do echo OK; echo true; done)"
run_exact "50 invalid GET commands" "$(for i in $(seq 1 50); do echo "GET a b$i"; done)" $"$(for i in $(seq 1 50); do echo 'Invalid command usage'; done)"
run_exact "50 unknown commands" "$(for i in $(seq 1 50); do echo "UNKNOWN$i"; done)" $"$(for i in $(seq 1 50); do echo 'Unknown command'; done)"
run_contains_all "150 keys contains samples" "$(for i in $(seq 1 150); do echo "SET sample$i value$i"; done; echo KEYS)" 'OK' 'sample1' 'sample75' 'sample150'
run_exact "Long history after 40 commands keeps last 20" "$(for i in $(seq 1 40); do echo "SET hh$i v"; done; echo HISTORY)" $"$(for i in $(seq 1 40); do echo OK; done; for i in $(seq 21 40); do echo "SET hh$i v"; done)"
run_exact "Save load after 100 overwrites" "$(for i in $(seq 1 100); do echo "SET a v$i"; done; echo "SAVE $tmp_save"; echo 'SET a changed'; echo "LOAD $tmp_save"; echo 'GET a')" $"$(for i in $(seq 1 100); do echo OK; done; echo 'Database saved'; echo OK; echo 'Database loaded'; echo v100)"
run_exact "Alternating missing and existing gets" "$(echo 'SET a 1'; for i in $(seq 1 50); do echo 'GET a'; echo "GET missing$i"; done)" $"$(echo OK; for i in $(seq 1 50); do echo 1; echo '(nil)'; done)"
run_exact "Alternating exists true false" "$(echo 'SET a 1'; for i in $(seq 1 50); do echo 'EXISTS a'; echo "EXISTS missing$i"; done)" $"$(echo OK; for i in $(seq 1 50); do echo true; echo false; done)"
run_exact "Alternating set rename" "$(for i in $(seq 1 30); do echo "SET r$i v$i"; echo "RENAME r$i rr$i"; echo "GET rr$i"; done)" $"$(for i in $(seq 1 30); do echo OK; echo renamed; echo v$i; done)"
run_exact "Alternating save load ten times" "$(echo 'SET a 1'; for i in $(seq 1 10); do echo "SAVE $tmp_save"; echo "LOAD $tmp_save"; done; echo 'GET a')" $"$(echo OK; for i in $(seq 1 10); do echo 'Database saved'; echo 'Database loaded'; done; echo 1)"
run_exact "Large value 500 chars" "$(printf 'SET big '; printf 'x%.0s' {1..500}; printf '\nGET big\n')" "$(printf 'OK\n'; printf 'x%.0s' {1..500})"
run_exact "Large number of parser invalids mixed" "$(for i in $(seq 1 25); do echo 'GET'; echo 'DEL'; echo 'EXISTS'; echo 'RENAME a'; done)" $"$(for i in $(seq 1 100); do echo 'Invalid command usage'; done)"

run_valgrind_check

{
    echo
    echo "========================================="
    echo "FINAL SUMMARY"
    echo "========================================="
    echo "Total behavior tests : $TEST_NO"
    echo "Passed               : $PASS"
    echo "Failed               : $FAIL"
    echo "Valgrind             : $VALGRIND_STATUS"
    echo "Report file          : $REPORT"
    echo "========================================="
} | tee -a "$REPORT"

if [[ "$TEST_NO" -ne 200 ]]; then
    echo "Internal test script error: expected 200 behavior tests but counted $TEST_NO" | tee -a "$REPORT"
    exit 2
fi

if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi

exit 0
