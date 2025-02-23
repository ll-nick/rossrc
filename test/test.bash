#!/bin/bash

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


TEST_DIR=$(mktemp -d)

IS_A_WORKSPACE_DIR="$TEST_DIR/test_ws"
mkdir -p "$IS_A_WORKSPACE_DIR/.catkin_tools/profiles"
echo "active: debug" > "$IS_A_WORKSPACE_DIR/.catkin_tools/profiles/profiles.yaml"
mkdir -p "$IS_A_WORKSPACE_DIR/devel"
echo "export SOURCED_DEVEL_SETUP=1" > "$IS_A_WORKSPACE_DIR/devel/setup.bash"
mkdir -p "$IS_A_WORKSPACE_DIR/devel_debug"
echo "export SOURCED_DEVEL_DEBUG_SETUP=1" > "$IS_A_WORKSPACE_DIR/devel_debug/setup.bash"
mkdir -p "$IS_A_WORKSPACE_DIR/src"
mkdir -p "$IS_A_WORKSPACE_DIR/some_other_dir"

IS_NOT_A_WORKSPACE_DIR="$TEST_DIR/test_not_ws"
mkdir -p "$IS_NOT_A_WORKSPACE_DIR/src"

# Automatically count failures when a command returns non-zero
fail_count=0
trap '((FAIL_COUNT++))' ERR

echo "== Running tests =="

source "$(dirname "${BASH_SOURCE[0]}")/rossrc.test.bash"

expect_unset "ROS_DISTRO" "Global environment should not yet be sourced"

cd "$IS_NOT_A_WORKSPACE_DIR" || return
rossrc
expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"

cd "$IS_A_WORKSPACE_DIR" || return
rossrc
expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
expect_equal "ROS_WORKSPACE" "$IS_A_WORKSPACE_DIR" "ROS_WORKSPACE should be set to the current workspace"
expect_equal "ROS_SETUP_FILE" "$IS_A_WORKSPACE_DIR/devel_debug/setup.bash" "ROS_SETUP_FILE should be set to the current workspace's setup.bash"
expect_equal "SOURCED_DEVEL_DEBUG_SETUP" "1" "The setup bash should have been sourced successfully"

echo "active: release" > "$IS_A_WORKSPACE_DIR/.catkin_tools/profiles/profiles.yaml"
rossrc
expect_equal "ROS_WORKSPACE" "$IS_A_WORKSPACE_DIR" "ROS_WORKSPACE should be set to the current workspace"
expect_equal "ROS_SETUP_FILE" "$IS_A_WORKSPACE_DIR/devel/setup.bash" "ROS_SETUP_FILE should be set to the current workspace's setup.bash"
expect_equal "SOURCED_DEVEL_SETUP" "1" "The setup bash should have been sourced successfully"

test_summary "$fail_count"

if [ "$fail_count" -eq 0 ]; then
    exit 0
else
    exit 1
fi
