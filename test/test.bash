#!/bin/bash
# shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
# shellcheck disable=SC2119  # Don't warn about not passing values to rossrc

source "$(dirname "${BASH_SOURCE[0]}")/util_testing.bash"

test_setup() {
    TEST_DIR=$(mktemp -d)
    GLOBAL_SOURCE_COUNTER=0

    source "$(dirname "${BASH_SOURCE[0]}")/rossrc.test.bash"
}

cleanup() {
    rm -rf "$TEST_DIR"
}

test_outside_of_workspace() {
    fail_count=0
    trap '((fail_count++))' ERR

    IS_NOT_A_WORKSPACE_DIR="$TEST_DIR/test_not_ws"
    mkdir -p "$IS_NOT_A_WORKSPACE_DIR/src"

    expect_unset "ROS_DISTRO" "Global environment should not yet be sourced"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"
    expect_equal "GLOBAL_SOURCE_COUNTER" "0" "The global environment should not have been sourced"

    cd "$IS_NOT_A_WORKSPACE_DIR" || return
    rossrc

    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"
    expect_equal "GLOBAL_SOURCE_COUNTER" "1" "The global environment should have been sourced once"

    rossrc
    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"
    expect_equal "GLOBAL_SOURCE_COUNTER" "1" "The global environment should have been sourced once"

    return "$fail_count"
}

test_switching_profiles() {
    fail_count=0
    trap '((fail_count++))' ERR

    # Prepare base workspace structure
    IS_A_WORKSPACE_DIR="$TEST_DIR/test_ws"
    mkdir -p "$IS_A_WORKSPACE_DIR/.catkin_tools/profiles"
    mkdir -p "$IS_A_WORKSPACE_DIR/src"
    mkdir -p "$IS_A_WORKSPACE_DIR/some_other_dir"

    # Prepare devel dir
    mkdir -p "$IS_A_WORKSPACE_DIR/devel"
    DEVEL_SOURCE_COUNTER=0
    echo "export DEVEL_SOURCE_COUNTER=$((DEVEL_SOURCE_COUNTER + 1))" > "$IS_A_WORKSPACE_DIR/devel/setup.bash"

    # Prepare devel_debug dir
    mkdir -p "$IS_A_WORKSPACE_DIR/devel_debug"
    DEVEL_DEBUG_SOURCE_COUNTER=0
    echo "export DEVEL_DEBUG_SOURCE_COUNTER=$((DEVEL_DEBUG_SOURCE_COUNTER + 1))" > "$IS_A_WORKSPACE_DIR/devel_debug/setup.bash"

    # Outside of workspace
    expect_unset "ROS_DISTRO" "Global environment should not yet be sourced"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"
    expect_equal "GLOBAL_SOURCE_COUNTER" "0" "The global environment should not have been sourced"
    expect_equal "DEVEL_SOURCE_COUNTER" "0" "The release setup bash should not have been sourced"
    expect_equal "DEVEL_DEBUG_SOURCE_COUNTER" "0" "The debug setup bash should not have been sourced"

    cd "$IS_A_WORKSPACE_DIR" || return

    # Release profile
    echo "active: release" > "$IS_A_WORKSPACE_DIR/.catkin_tools/profiles/profiles.yaml"
    rossrc
    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_equal "GLOBAL_SOURCE_COUNTER" "1" "The global environment should have been sourced once"
    expect_equal "ROS_WORKSPACE" "$IS_A_WORKSPACE_DIR" "ROS_WORKSPACE should be set to the current workspace"
    expect_equal "ROS_SETUP_FILE" "$IS_A_WORKSPACE_DIR/devel/setup.bash" "ROS_SETUP_FILE should be set to the current workspace's setup.bash"
    expect_equal "DEVEL_SOURCE_COUNTER" "1" "The setup bash should have been sourced successfully"
    expect_equal "DEVEL_DEBUG_SOURCE_COUNTER" "0" "The debug setup bash should not have been sourced"

    # Sourcing again shouldn't change anything
    rossrc
    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_equal "GLOBAL_SOURCE_COUNTER" "1" "The global workspace should not be sourced again"
    expect_equal "ROS_WORKSPACE" "$IS_A_WORKSPACE_DIR" "The workspace should not have changed"
    expect_equal "ROS_SETUP_FILE" "$IS_A_WORKSPACE_DIR/devel/setup.bash" "The setup file should not have changed"
    expect_equal "DEVEL_SOURCE_COUNTER" "1" "The setup bash should not have been sourced again"
    expect_equal "DEVEL_DEBUG_SOURCE_COUNTER" "0" "The debug setup bash should not have been sourced"

    # Switch active profile and source again
    echo "active: debug" > "$IS_A_WORKSPACE_DIR/.catkin_tools/profiles/profiles.yaml"
    rossrc

    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_equal "GLOBAL_SOURCE_COUNTER" "1" "The global environment should have been sourced once"
    expect_equal "ROS_WORKSPACE" "$IS_A_WORKSPACE_DIR" "ROS_WORKSPACE should be set to the current workspace"
    expect_equal "ROS_SETUP_FILE" "$IS_A_WORKSPACE_DIR/devel_debug/setup.bash" "ROS_SETUP_FILE should be set to the current workspace's setup.bash"
    expect_equal "DEVEL_SOURCE_COUNTER" "1" "The setup bash should not have been sourced again"
    expect_equal "DEVEL_DEBUG_SOURCE_COUNTER" "1" "The setup bash should have been sourced successfully"

    # Sourcing again shouldn't change anything
    rossrc
    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_equal "GLOBAL_SOURCE_COUNTER" "1" "The global workspace should not be sourced again"
    expect_equal "ROS_WORKSPACE" "$IS_A_WORKSPACE_DIR" "The workspace should not have changed"
    expect_equal "ROS_SETUP_FILE" "$IS_A_WORKSPACE_DIR/devel_debug/setup.bash" "The setup file should not have changed"
    expect_equal "DEVEL_SOURCE_COUNTER" "1" "The setup bash should not have been sourced again"
    expect_equal "DEVEL_DEBUG_SOURCE_COUNTER" "1" "The setup bash should not have been sourced again"

    return "$fail_count"
}

main() {
    failed_test_cases=0
    trap '((failed_test_cases++))' ERR

    print_header

    test_setup

    run_test_case "rossrc outside of workspace" test_outside_of_workspace
    run_test_case "rossrc inside a workspace" test_switching_profiles

    cleanup

    print_test_summary "$failed_test_cases"

    if [ "$failed_test_cases" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

main
