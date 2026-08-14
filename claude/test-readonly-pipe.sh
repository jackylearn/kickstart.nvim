#!/bin/bash
# Test harness for readonly-pipe-check.sh
HOOK="./readonly-pipe-check.sh"
PASS=0
FAIL=0

run_test() {
    local desc="$1"
    local input="$2"
    local expect_approve="$3" # "yes" or "no"

    result=$(echo "$input" | bash "$HOOK" 2>/dev/null)

    if [ "$expect_approve" = "yes" ]; then
        if echo "$result" | grep -q '"approve"'; then
            echo "PASS: $desc"
            ((PASS++))
        else
            echo "FAIL: $desc (expected approve, got: '$result')"
            ((FAIL++))
        fi
    else
        if [ -z "$result" ] || ! echo "$result" | grep -q '"approve"'; then
            echo "PASS: $desc"
            ((PASS++))
        else
            echo "FAIL: $desc (expected no approve, got: '$result')"
            ((FAIL++))
        fi
    fi
}

# --- Should APPROVE ---
run_test "simple pipe" \
    '{"tool_input":{"command":"rg foo | sort | wc -l"}}' "yes"

run_test "sequential &&" \
    '{"tool_input":{"command":"rg foo && rg bar"}}' "yes"

run_test "sequential ;" \
    '{"tool_input":{"command":"rg foo; head -5 file.txt"}}' "yes"

run_test "sequential ||" \
    '{"tool_input":{"command":"rg foo || echo not found"}}' "yes"

run_test "mixed sequential and pipe" \
    '{"tool_input":{"command":"rg foo | wc -l && rg bar | sort"}}' "yes"

run_test "p4 sequential" \
    '{"tool_input":{"command":"p4 opened && p4 fstat //depot/..."}}' "yes"

run_test "p4 piped to rg" \
    '{"tool_input":{"command":"p4 filelog file.c | rg submit"}}' "yes"

# --- Should NOT approve ---
run_test "dangerous after &&" \
    '{"tool_input":{"command":"rg foo && mkdir /tmp/bad"}}' "no"

run_test "dangerous after ;" \
    '{"tool_input":{"command":"rg foo; touch /tmp/x"}}' "no"

run_test "command substitution \$()" \
    '{"tool_input":{"command":"rg \$(whoami)"}}' "no"

run_test "command substitution backtick" \
    '{"tool_input":{"command":"rg `whoami`"}}' "no"

run_test "redirect >" \
    '{"tool_input":{"command":"rg foo > out.txt"}}' "no"

run_test "sed -i in pipe" \
    '{"tool_input":{"command":"rg -l foo | sed -i s/foo/bar/"}}' "no"

run_test "p4 write command" \
    '{"tool_input":{"command":"p4 opened && p4 edit file.c"}}' "no"

run_test "unknown command in sequence" \
    '{"tool_input":{"command":"rg foo && python script.py"}}' "no"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
