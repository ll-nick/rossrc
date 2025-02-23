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
    mkdir -p "$IS_A_WORKSPACE_DIR/some_other_dir"

    # Prepare devel dir
    mkdir -p "$IS_A_WORKSPACE_DIR/devel"
    export DEVEL_SOURCE_COUNTER=0
    echo "export DEVEL_SOURCE_COUNTER=\$((DEVEL_SOURCE_COUNTER + 1))" > "$IS_A_WORKSPACE_DIR/devel/setup.bash"

    # Prepare devel_debug dir
    mkdir -p "$IS_A_WORKSPACE_DIR/devel_debug"
    export DEVEL_DEBUG_SOURCE_COUNTER=0
    echo "export DEVEL_DEBUG_SOURCE_COUNTER=\$((DEVEL_DEBUG_SOURCE_COUNTER + 1))" > "$IS_A_WORKSPACE_DIR/devel_debug/setup.bash"

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

    # Sourcing again shouldn't change anything, even when in a different directory
    cd "$IS_A_WORKSPACE_DIR/some_other_dir" || return
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
    # Sourcing again shouldn't change anything, even when in a different directory
    cd "$IS_A_WORKSPACE_DIR/some_other_dir" || return
    rossrc
    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_equal "GLOBAL_SOURCE_COUNTER" "1" "The global workspace should not be sourced again"
    expect_equal "ROS_WORKSPACE" "$IS_A_WORKSPACE_DIR" "The workspace should not have changed"
    expect_equal "ROS_SETUP_FILE" "$IS_A_WORKSPACE_DIR/devel_debug/setup.bash" "The setup file should not have changed"
    expect_equal "DEVEL_SOURCE_COUNTER" "1" "The setup bash should not have been sourced again"
    expect_equal "DEVEL_DEBUG_SOURCE_COUNTER" "1" "The setup bash should not have been sourced again"

    return "$fail_count"
}

test_multiple_workspaces() {
    fail_count=0
    trap '((fail_count++))' ERR

    # Prepare base workspace structure
    WORKSPACE_1="$TEST_DIR/test_ws_1"
    mkdir -p "$WORKSPACE_1/.catkin_tools/profiles"
    echo "active: release" > "$WORKSPACE_1/.catkin_tools/profiles/profiles.yaml"
    mkdir -p "$WORKSPACE_1/devel"
    export DEVEL_SOURCE_COUNTER_1=0
    echo "export DEVEL_SOURCE_COUNTER_1=\$((DEVEL_SOURCE_COUNTER_1 + 1))" > "$WORKSPACE_1/devel/setup.bash"

    WORKSPACE_2="$TEST_DIR/test_ws_2"
    mkdir -p "$WORKSPACE_2/.catkin_tools/profiles"
    echo "active: release" > "$WORKSPACE_2/.catkin_tools/profiles/profiles.yaml"
    mkdir -p "$WORKSPACE_2/devel"
    export DEVEL_SOURCE_COUNTER_2=0
    echo "export DEVEL_SOURCE_COUNTER_2=\$((DEVEL_SOURCE_COUNTER_2 + 1))" > "$WORKSPACE_2/devel/setup.bash"

    # Outside of workspace
    expect_unset "ROS_DISTRO" "Global environment should not yet be sourced"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"
    expect_equal "GLOBAL_SOURCE_COUNTER" "0" "The global environment should not have been sourced"
    expect_equal "DEVEL_SOURCE_COUNTER_1" "0" "The setup bash for workspace 1 should not have been sourced"
    expect_equal "DEVEL_SOURCE_COUNTER_2" "0" "The setup bash for workspace 2 should not have been sourced"

    cd "$WORKSPACE_1" || return
    rossrc

    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_equal "GLOBAL_SOURCE_COUNTER" "1" "The global environment should have been sourced once"
    expect_equal "ROS_WORKSPACE" "$WORKSPACE_1" "ROS_WORKSPACE should be set to the current workspace"
    expect_equal "ROS_SETUP_FILE" "$WORKSPACE_1/devel/setup.bash" "ROS_SETUP_FILE should be set to the current workspace's setup.bash"
    expect_equal "DEVEL_SOURCE_COUNTER_1" "1" "The setup bash for workspace 1 should have been sourced"
    expect_equal "DEVEL_SOURCE_COUNTER_2" "0" "The setup bash for workspace 2 should not have been sourced"

    cd "$WORKSPACE_2" || return
    rossrc

    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_equal "GLOBAL_SOURCE_COUNTER" "2" "The global environment should have been sourced again since the workspace changed"
    expect_equal "ROS_WORKSPACE" "$WORKSPACE_2" "ROS_WORKSPACE should be set to the current workspace"
    expect_equal "ROS_SETUP_FILE" "$WORKSPACE_2/devel/setup.bash" "ROS_SETUP_FILE should be set to the current workspace's setup.bash"
    expect_equal "DEVEL_SOURCE_COUNTER_1" "1" "The setup bash for workspace 1 should not have been sourced again"
    expect_equal "DEVEL_SOURCE_COUNTER_2" "1" "The setup bash for workspace 2 should have been sourced"

    return "$fail_count"
}

test_cd_hook() {
    fail_count=0
    trap '((fail_count++))' ERR

    source "$(dirname "${BASH_SOURCE[0]}")/../cd_hook.bash"

    # Prepare base workspace structure
    WORKSPACE="$TEST_DIR/cd_hook_ws"
    mkdir -p "$WORKSPACE/.catkin_tools/profiles"
    echo "active: release" > "$WORKSPACE/.catkin_tools/profiles/profiles.yaml"
    mkdir -p "$WORKSPACE/devel"
    export DEVEL_SOURCE_COUNTER=0
    echo "export DEVEL_SOURCE_COUNTER=\$((DEVEL_SOURCE_COUNTER + 1))" > "$WORKSPACE/devel/setup.bash"

    # Outside of workspace
    expect_unset "ROS_DISTRO" "Global environment should not yet be sourced"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"
    expect_equal "GLOBAL_SOURCE_COUNTER" "0" "The global environment should not have been sourced"
    expect_equal "DEVEL_SOURCE_COUNTER" "0" "The setup bash should not have been sourced"

    # Outside of a workspace the cd hook should not do anything
    cd "$TEST_DIR" || return
    expect_unset "ROS_DISTRO" "Global environment should not yet be sourced"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"
    expect_equal "GLOBAL_SOURCE_COUNTER" "0" "The global environment should not have been sourced"
    expect_equal "DEVEL_SOURCE_COUNTER" "0" "The setup bash should not have been sourced"

    # No need to run rossrc with the cd hook
    cd "$WORKSPACE" || return
    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_equal "GLOBAL_SOURCE_COUNTER" "1" "The global environment should have been sourced once"
    expect_equal "ROS_WORKSPACE" "$WORKSPACE" "ROS_WORKSPACE should be set to the current workspace"
    expect_equal "ROS_SETUP_FILE" "$WORKSPACE/devel/setup.bash" "ROS_SETUP_FILE should be set to the current workspace's setup.bash"
    expect_equal "DEVEL_SOURCE_COUNTER" "1" "The setup bash should have been sourced"

    return "$fail_count"
}

main() {
    failed_test_cases=0
    trap '((failed_test_cases++))' ERR

    print_header

    test_setup

    run_test_case "rossrc outside of workspace" test_outside_of_workspace
    run_test_case "rossrc inside a workspace" test_switching_profiles
    run_test_case "rossrc with multiple workspaces" test_multiple_workspaces
    run_test_case "auto sourcing using cd hook" test_cd_hook

    cleanup

    print_test_summary "$failed_test_cases"

    if [ "$failed_test_cases" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

main
