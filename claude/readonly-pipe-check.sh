#!/bin/bash
# Hook: auto-approve Bash commands where every pipeline segment is read-only.
# Receives JSON on stdin with tool_input.command field.

set -euo pipefail

CMD=$(jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

# Read-only command allowlist (first word of each pipe segment)
READONLY_CMDS="rg|head|tail|wc|sort|uniq|sed|cut|tr|column|cat|fmt|rev|nl|paste|expand|unexpand|fold|comm|diff|tac|jq|ps|pgrep|ls|file|stat|readlink|basename|dirname|realpath|which|type|echo|printf|true|false|test|expr"

# p4 read-only subcommands
P4_READONLY="annotate|branches|changes|clients|depots|describe|diff|diff2|dirs|files|filelog|fixes|fstat|grep|groups|have|help|info|interchanges|jobs|labels|opened|print|protects|sizes|status|streams|users|where"

# Reject command substitution — fall through to normal prompting
if echo "$CMD" | grep -qP '(\$\(|`)' 2>/dev/null; then
    exit 0
fi

# Reject if any output redirection is present (>, >>)
if echo "$CMD" | grep -qP '(?<![12])\s*>{1,2}\s' 2>/dev/null; then
    exit 0
fi
# Also catch explicit fd redirections like 1> 2> that write to files (but allow 2>&1)
if echo "$CMD" | grep -qP '\d+>\s*[^&]' 2>/dev/null; then
    exit 0
fi

# Split on sequential operators (&&, ;, ||) into individual commands, then validate each
# Uses perl to split while preserving pipe characters within each command
readarray -t COMMANDS < <(echo "$CMD" | perl -pe 's/\s*(&&|\|\||;)\s*/\n/g')

for cmd in "${COMMANDS[@]}"; do
    [ -z "$cmd" ] && continue

    # Split each command on pipes and check each segment
    IFS='|' read -ra SEGMENTS <<< "$cmd"

    for seg in "${SEGMENTS[@]}"; do
        # Trim leading/trailing whitespace
        seg=$(echo "$seg" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$seg" ] && continue

        # Get the first word (command name)
        first_word=$(echo "$seg" | awk '{print $1}')

        # Check if it's a read-only command
        if echo "$first_word" | grep -qxP "($READONLY_CMDS)"; then
            # Extra check: reject sed -i / --in-place (in-place edit)
            if [ "$first_word" = "sed" ] && echo "$seg" | grep -qP '\s(-i|--in-place)\b'; then
                exit 0
            fi
            # Extra check: reject sort -o (writes to file)
            if [ "$first_word" = "sort" ] && echo "$seg" | grep -qP '\s(-o|--output)\b'; then
                exit 0
            fi
            continue
        fi

        # Check if it's a read-only p4 command
        if [ "$first_word" = "p4" ]; then
            p4_sub=$(echo "$seg" | awk '{print $2}')
            if echo "$p4_sub" | grep -qxP "($P4_READONLY)"; then
                continue
            fi
            exit 0
        fi

        # Not in allowlist — don't auto-approve, fall through to normal prompting
        exit 0
    done
done

# All segments across all commands are read-only — auto-approve
echo '{"decision":"approve","reason":"all pipeline segments are read-only"}'
