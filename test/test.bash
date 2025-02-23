#!/bin/bash
# shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
# shellcheck disable=SC2119  # Don't warn about not passing values to rossrc

source "$(dirname "${BASH_SOURCE[0]}")/util_testing.bash"

# Automatically count failures when a command returns non-zero
fail_count=0
trap '((fail_count++))' ERR

test_setup() {
    TEST_DIR=$(mktemp -d)


    source "$(dirname "${BASH_SOURCE[0]}")/rossrc.test.bash"
}

test_outside_of_workspace() {
    IS_NOT_A_WORKSPACE_DIR="$TEST_DIR/test_not_ws"
    mkdir -p "$IS_NOT_A_WORKSPACE_DIR/src"

    expect_unset "ROS_DISTRO" "Global environment should not yet be sourced"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"

    cd "$IS_NOT_A_WORKSPACE_DIR" || return
    rossrc

    expect_equal "ROS_DISTRO" "testora" "The global environment should be sourced with the correct ROS distro"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"
}

test_inside_of_actual_workspace() {
    IS_A_WORKSPACE_DIR="$TEST_DIR/test_ws"
    mkdir -p "$IS_A_WORKSPACE_DIR/.catkin_tools/profiles"
    echo "active: debug" > "$IS_A_WORKSPACE_DIR/.catkin_tools/profiles/profiles.yaml"
    mkdir -p "$IS_A_WORKSPACE_DIR/devel"
    echo "export SOURCED_DEVEL_SETUP=1" > "$IS_A_WORKSPACE_DIR/devel/setup.bash"
    mkdir -p "$IS_A_WORKSPACE_DIR/devel_debug"
    echo "export SOURCED_DEVEL_DEBUG_SETUP=1" > "$IS_A_WORKSPACE_DIR/devel_debug/setup.bash"
    mkdir -p "$IS_A_WORKSPACE_DIR/src"
    mkdir -p "$IS_A_WORKSPACE_DIR/some_other_dir"

    expect_unset "ROS_DISTRO" "Global environment should not yet be sourced"
    expect_unset "ROS_WORKSPACE" "ROS_WORKSPACE should not be set when not in a workspace"
    expect_unset "ROS_SETUP_FILE" "ROS_SETUP_FILE should not be set when not in a workspace"

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
}

print_header

test_setup

run_test_case "rossrc outside of workspace" test_outside_of_workspace
run_test_case "rosscr insdie a workspace" test_inside_of_actual_workspace

print_test_summary "$fail_count"

if [ "$fail_count" -eq 0 ]; then
    exit 0
else
    exit 1
fi
