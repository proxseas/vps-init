#!/usr/bin/env bash
# Test script for --skip and --only flags

set -euo pipefail

echo "Testing --skip and --only flag implementation"
echo "=============================================="
echo

# Test 1: Invalid flag
echo "Test 1: Invalid flag (should error)"
if ./setup.sh --invalid 2>&1 | grep -q "Unknown argument"; then
    echo "✅ Invalid flag detection works"
else
    echo "❌ Invalid flag detection failed"
fi
echo

# Test 2: --skip without argument
echo "Test 2: --skip without argument (should error)"
if ./setup.sh --skip 2>&1 | grep -q "requires a comma-separated list"; then
    echo "✅ --skip argument validation works"
else
    echo "❌ --skip argument validation failed"
fi
echo

# Test 3: --only without argument
echo "Test 3: --only without argument (should error)"
if ./setup.sh --only 2>&1 | grep -q "requires a comma-separated list"; then
    echo "✅ --only argument validation works"
else
    echo "❌ --only argument validation failed"
fi
echo

# Test 4: Mutual exclusivity
echo "Test 4: --skip and --only together (should error)"
if ./setup.sh --skip containers --only user-env 2>&1 | grep -q "cannot be used together"; then
    echo "✅ Mutual exclusivity check works"
else
    echo "❌ Mutual exclusivity check failed"
fi
echo

# Test 5: Valid --skip with short form
echo "Test 5: Valid -S flag (should not error on parse)"
# We'll just check if it gets past argument parsing and reaches the directory check
# Since we're running from the correct directory, it should proceed
if ./setup.sh -S containers 2>&1 | head -5 | grep -q "Starting VPS Setup"; then
    echo "✅ -S short form works"
else
    echo "❌ -S short form failed"
fi
echo

# Test 6: Valid --only with short form
echo "Test 6: Valid -O flag (should not error on parse)"
if ./setup.sh -O user-env 2>&1 | head -5 | grep -q "Starting VPS Setup"; then
    echo "✅ -O short form works"
else
    echo "❌ -O short form failed"
fi
echo

# Test 7: Multiple IDs in comma-separated list
echo "Test 7: Multiple IDs (node,containers,verify)"
if ./setup.sh -S node,containers,verify 2>&1 | head -5 | grep -q "Starting VPS Setup"; then
    echo "✅ Comma-separated list parsing works"
else
    echo "❌ Comma-separated list parsing failed"
fi
echo

echo "=============================================="
echo "Basic flag parsing tests complete!"
