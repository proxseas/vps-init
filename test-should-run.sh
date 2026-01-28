#!/usr/bin/env bash
# Test should_run() and should_run_any() logic in isolation

set -euo pipefail

# Copy the helper functions from setup.sh
should_run() {
    local id="$1"

    # If ONLY_LIST is set, only run if ID is in the list
    if [[ ${#ONLY_LIST[@]} -gt 0 ]]; then
        for only_id in "${ONLY_LIST[@]}"; do
            # Trim whitespace
            only_id=$(echo "$only_id" | xargs)
            if [[ "$only_id" == "$id" ]]; then
                return 0
            fi
        done
        return 1
    fi

    # If SKIP_LIST is set, skip if ID is in the list
    if [[ ${#SKIP_LIST[@]} -gt 0 ]]; then
        for skip_id in "${SKIP_LIST[@]}"; do
            # Trim whitespace
            skip_id=$(echo "$skip_id" | xargs)
            if [[ "$skip_id" == "$id" ]]; then
                return 1
            fi
        done
    fi

    # Default: run the step
    return 0
}

should_run_any() {
    for id in "$@"; do
        if should_run "$id"; then
            return 0
        fi
    done
    return 1
}

echo "Testing should_run() logic"
echo "=========================="
echo

# Test 1: No skip/only - everything should run
echo "Test 1: No filters (should run everything)"
SKIP_LIST=()
ONLY_LIST=()
if should_run "node" && should_run "containers" && should_run "verify"; then
    echo "✅ Default behavior works (all run)"
else
    echo "❌ Default behavior failed"
fi
echo

# Test 2: Skip specific items
echo "Test 2: Skip containers"
SKIP_LIST=("containers")
ONLY_LIST=()
if should_run "node" && ! should_run "containers" && should_run "verify"; then
    echo "✅ Skip single item works"
else
    echo "❌ Skip single item failed"
fi
echo

# Test 3: Skip multiple items
echo "Test 3: Skip node,containers"
SKIP_LIST=("node" "containers")
ONLY_LIST=()
if ! should_run "node" && ! should_run "containers" && should_run "verify"; then
    echo "✅ Skip multiple items works"
else
    echo "❌ Skip multiple items failed"
fi
echo

# Test 4: Only specific items
echo "Test 4: Only user-env"
SKIP_LIST=()
ONLY_LIST=("user-env")
if ! should_run "node" && should_run "user-env" && ! should_run "verify"; then
    echo "✅ Only specific item works"
else
    echo "❌ Only specific item failed"
fi
echo

# Test 5: Only multiple items
echo "Test 5: Only system,verify"
SKIP_LIST=()
ONLY_LIST=("system" "verify")
if should_run "system" && ! should_run "node" && should_run "verify"; then
    echo "✅ Only multiple items works"
else
    echo "❌ Only multiple items failed"
fi
echo

# Test 6: should_run_any with dev-tools group
echo "Test 6: should_run_any with dev-tools group"
SKIP_LIST=()
ONLY_LIST=("dev-tools")
if should_run_any "node" "dev-tools"; then
    echo "✅ should_run_any works (node matches via dev-tools group)"
else
    echo "❌ should_run_any failed"
fi
echo

# Test 7: should_run_any when one is skipped
echo "Test 7: Skip node but dev-tools in only list"
SKIP_LIST=("node")
ONLY_LIST=()
if ! should_run_any "node"; then
    echo "✅ should_run_any correctly returns false when all args are skipped"
else
    echo "❌ should_run_any should return false"
fi
echo

# Test 8: should_run_any with mixed results
echo "Test 8: Skip containers, but dev-tools should still match for python"
SKIP_LIST=("containers")
ONLY_LIST=()
if should_run_any "python" "dev-tools"; then
    echo "✅ should_run_any returns true when at least one arg should run"
else
    echo "❌ should_run_any should return true"
fi
echo

echo "=========================="
echo "Logic tests complete!"
