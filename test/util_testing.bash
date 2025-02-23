run_test_case() {
    local test_case_name="$1"
    shift
    echo "--------------------------------"
    echo "🔹 Running test case \"$test_case_name\"..."
    echo "---"
    (
        fail_count=0
        trap '((fail_count++))' ERR
        "$@"
        return "$fail_count"
    )
    fail_count="$?"
    echo "---"
    if [ "$fail_count" -eq 0 ]; then
        echo "✅ Test case \"$test_case_name\" passed!"
        echo "--------------------------------"
        return 0
    else
        echo "❌ Test case \"$test_case_name\" failed!"
        echo "--------------------------------"
        return 1
    fi
}

expect_unset() {
    local var_name="$1"
    eval "local var_value=\"\$$var_name\""
    local test_name="$2"
    if [ -n "$var_value" ]; then
        echo "❌ $test_name: Expected variable to be unset: $var_name"
        return 1
    fi
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
    return 0
}

print_header() {
    echo ""
    echo "============================"
    echo " 🚀 R O S S R C  T E S T S "
    echo "============================"
    echo ""
}

print_test_summary() {
    local fail_count="$1"
    echo ""
    echo "=================="
    echo " 🔍 R E S U L T S"
    echo "=================="
    echo ""
    if [ "$fail_count" -eq 0 ]; then
        echo "✅ All tests passed!"
    elif [ "$fail_count" -eq 1 ]; then
        echo "❌ $fail_count test case failed!"
    else
        echo "❌ $fail_count tests cases failed!"
    fi
    echo ""
    echo "=================="
}
