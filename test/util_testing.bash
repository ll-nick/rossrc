expect_unset() {
    local var_name="$1"
    eval "local var_value=\"\$$var_name\""
    local test_name="$2"
    if [ -n "$var_value" ]; then
        echo "❌ $test_name: Expected variable to be unset: $var_name"
        return 1
    fi
    echo "✅ $test_name"
    return 0
}

expect_equal() {
    local var_name="$1"
    local expected_value="$2"
    eval "local var_value=\"\$$var_name\""
    local test_name="$3"
    if [ "$var_value" != "$expected_value" ]; then
        echo "❌ $test_name: Expected variable to be '$expected_value', but got '$var_value'"
        return 1
    fi
    echo "✅ $test_name"
    return 0
}

test_summary() {
    local fail_count="$1"
    rm -rf "$TEST_DIR"  # Cleanup
    echo ""
    echo "==============="
    echo " R E S U L T S"
    echo "==============="
    echo ""
    if [ "$fail_count" -eq 0 ]; then
        echo "✅ All tests passed!"
    elif [ "$fail_count" -eq 1 ]; then
        echo "❌ $fail_count test failed!"
    else
        echo "❌ $fail_count tests failed!"
    fi
}
