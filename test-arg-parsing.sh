#!/usr/bin/env bash
# Test argument parsing in setup.sh

set -euo pipefail

echo "Testing argument parsing in setup.sh"
echo "====================================="
echo

# Helper function to test a command
test_command() {
    local description="$1"
    local expected_result="$2"  # "pass" or "fail"
    shift 2
    local cmd=("$@")

    echo "Test: $description"
    if output=$("${cmd[@]}" 2>&1); then
        if [[ "$expected_result" == "pass" ]]; then
            echo "✅ Passed (command succeeded as expected)"
        else
            echo "❌ Failed (command should have failed but succeeded)"
            echo "Output: $output"
        fi
    else
        if [[ "$expected_result" == "fail" ]]; then
            echo "✅ Passed (command failed as expected)"
            echo "Error message: $(echo "$output" | head -1)"
        else
            echo "❌ Failed (command should have succeeded but failed)"
            echo "Output: $output"
        fi
    fi
    echo
}

cd /Users/dm/code_area/vps-setup

# Test 1: Unknown argument
test_command "Unknown argument --invalid" "fail" \
    bash -c './setup.sh --invalid 2>&1 | head -5'

# Test 2: --skip without value
test_command "--skip without value" "fail" \
    bash -c './setup.sh --skip 2>&1 | head -5'

# Test 3: --only without value
test_command "--only without value" "fail" \
    bash -c './setup.sh --only 2>&1 | head -5'

# Test 4: Both --skip and --only
test_command "Both --skip and --only (mutual exclusivity)" "fail" \
    bash -c './setup.sh --skip containers --only user-env 2>&1 | head -10'

# Test 5: Valid --skip (will fail later for other reasons, but should parse args)
echo "Test: Valid --skip containers"
if ./setup.sh --skip containers 2>&1 | head -20 | grep -q "Starting VPS Setup"; then
    echo "✅ Passed (--skip flag parsed successfully)"
else
    echo "❌ Failed (--skip flag not parsed correctly)"
fi
echo

# Test 6: Valid -S short form
echo "Test: Valid -S containers"
if ./setup.sh -S containers 2>&1 | head -20 | grep -q "Starting VPS Setup"; then
    echo "✅ Passed (-S short form parsed successfully)"
else
    echo "❌ Failed (-S short form not parsed correctly)"
fi
echo

# Test 7: Valid --only
echo "Test: Valid --only user-env"
if ./setup.sh --only user-env 2>&1 | head -20 | grep -q "Starting VPS Setup"; then
    echo "✅ Passed (--only flag parsed successfully)"
else
    echo "❌ Failed (--only flag not parsed correctly)"
fi
echo

# Test 8: Valid -O short form
echo "Test: Valid -O system"
if ./setup.sh -O system 2>&1 | head -20 | grep -q "Starting VPS Setup"; then
    echo "✅ Passed (-O short form parsed successfully)"
else
    echo "❌ Failed (-O short form not parsed correctly)"
fi
echo

# Test 9: Multiple IDs comma-separated
echo "Test: Multiple IDs -S node,containers,verify"
if ./setup.sh -S node,containers,verify 2>&1 | head -20 | grep -q "Starting VPS Setup"; then
    echo "✅ Passed (comma-separated list parsed successfully)"
else
    echo "❌ Failed (comma-separated list not parsed correctly)"
fi
echo

echo "====================================="
echo "Argument parsing tests complete!"
