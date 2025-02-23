#!/bin/bash

# rossrc - A Bash utility for intelligently sourcing ROS environments.
#
# This script provides a mechanism to automatically source the correct ROS
# environment and workspace setup. It ensures that the global ROS installation
# is sourced when needed and selects the appropriate workspace environment if
# within a recognized workspace.
#
# To keep overhead minimal, the script uses heuristics to determine if the
# current directory is within a workspace. If the heuristic is not satisfied,
# the script will not attempt to source the workspace. The script also avoids
# re-sourcing the workspace if the setup file is already sourced.
#
# To keep the script generic and reusable, it provides a set of functions that
# can be overridden or extended. They are prefixed with "__rossrc_" to indicate
# that they are internal functions and to not clutter the global namespace.
#
# You should not source this script directly, unless you implemented custom
# overrides. Instead, source the file matching the ROS distribution you are using.
# For example, source "rossrc.noetic.bash" for ROS Noetic.
#
# Usage:
#   source rossrc [OPTIONS]
#
# Options:
#   -f, --force    Force re-sourcing the workspace even if already sourced.
#   --help         Display usage information.

# Check if the function is already defined. If not, define a default implementation.
# This allows custom implementations to override the default behavior and you'll
# see this pattern throughout the script.
if ! declare -f __rossrc_is_within_workspace_heuristic > /dev/null; then
    # Determines if the current directory is within a workspace based on heuristics.
    #
    # This function is exposed outside of rossrc to allow the cd hook to use it.
    # Args:
    #   dir (string): The directory to check.
    # Returns:
    #   0 if inside a workspace, 1 otherwise.
    __rossrc_is_within_workspace_heuristic() {
        local dir="$1"
        if [[ "$dir" != *_ws* ]]; then
            return 1
        fi
        return 0
    }
fi

rossrc() {

    if ! declare -f __rossrc_source_global_ros_env > /dev/null; then
        # Sources the global ROS installation.
        __rossrc_source_global_ros_env() {
            local global_setup_file="/opt/ros/noetic/setup.bash"
            if [ ! -f "$global_setup_file" ]; then
                echo "No ROS installation found at $global_setup_file"
                exit
            fi
            source "$global_setup_file"
        }
    fi

    if ! declare -f __rossrc_is_workspace_root > /dev/null; then
        # Checks if a directory is a catkin workspace root.
        # Args:
        #   dir (string): The directory to check.
        # Returns:
        #   0 if it is a workspace root, 1 otherwise.
        __rossrc_is_workspace_root() {
            local dir="$1"
            if [ -d "$dir/.catkin_tools" ]; then
                return 0
            fi
            return 1
        }
    fi

    if ! declare -f __rossrc_get_workspace_root > /dev/null; then
        # Finds the root of the catkin workspace.
        # Args:
        #   dir (string): The starting directory that is within the workspace.
        # Returns:
        #   The workspace root directory or an empty string if not in a workspace.
        __rossrc_get_workspace_root() {
            local dir="$1"
            while [ "$dir" != "/" ]; do
                if ! __rossrc_is_workspace_root "$dir"; then
                    dir=$(dirname "$dir")
                    continue
                fi
                echo "$dir"
                return
            done
            # No workspace found
            echo ""
        }
    fi

    if ! declare -f __rossrc_get_active_profile > /dev/null; then
        # Retrieves the active catkin profile from profiles.yaml.
        # Args:
        #   ws_root (string): The workspace root directory.
        # Returns:
        #   The active profile name.
        __rossrc_get_active_profile() {
            local ws_root="$1"
            local profile_file="$ws_root/.catkin_tools/profiles/profiles.yaml"
            if [ -f "$profile_file" ]; then
                local active_profile
                active_profile=$(grep "active:" "$profile_file" | cut -d' ' -f2)
                echo "$active_profile"
            fi
        }
    fi

    if ! declare -f __rossrc_get_path_to_setup_dir > /dev/null; then
        # Determines the correct setup directory based on the active profile.
        # Args:
        #   ws_root (string): The workspace root directory.
        #   active_profile (string): The active profile name.
        # Returns:
        #   The setup directory path.
        __rossrc_get_path_to_setup_dir() {
            local ws_root="$1"
            echo "$ws_root/devel"
        }
    fi

    if ! declare -f __rossrc_get_setup_file > /dev/null; then
        # Gets the full path to the setup.bash file.
        # Args:
        #   setup_dir (string): The setup directory.
        # Returns:
        #   The full path to setup.bash.
        __rossrc_get_setup_file() {
            local setup_dir="$1"
            echo "$setup_dir/setup.bash"
        }
    fi

    main() {
        local force_source=0

        # Parse command-line arguments
        for arg in "$@"; do
            case "$arg" in
            --force | -f) force_source=1 ;;
            --help)
                echo "Usage: rossrc [OPTIONS]"
                echo "Source the current workspace and the global ROS installation if necessary."
                echo
                echo "Options:"
                echo "  -f, --force    Source the current workspace even if it is already sourced."
                echo "  --help         Show this help message."
                return 0
                ;;
            *)
                echo "Unknown option: $arg"
                return 1
                ;;
            esac
        done

        # Source the ROS installation if not already done
        if [ -z "$ROS_DISTRO" ]; then
            echo "Sourcing ROS installation"
            __rossrc_source_global_ros_env
        fi

        # If heuristic is not satisfied, we can return early
        if ! __rossrc_is_within_workspace_heuristic "$(pwd)"; then
            return
        fi

        # Make sure we are in a workspace and determine the workspace root
        local ws_root
        ws_root=$(__rossrc_get_workspace_root "$(pwd)")
        if [ -z "$ws_root" ]; then
            return
        fi

        local active_profile
        active_profile=$(__rossrc_get_active_profile "$ws_root")
        local setup_script_dir
        setup_script_dir=$(__rossrc_get_path_to_setup_dir "$ws_root" "$active_profile")
        local setup_file
        setup_file=$(__rossrc_get_setup_file "$setup_script_dir")

        # No need to re-source if the setup file is already sourced unless forced
        if [[ $force_source -eq 0 && "$ROS_SETUP_FILE" == "$setup_file" ]]; then
            return
        fi
        # Warn when overlaying workspaces
        if [ -n "$ROS_WORKSPACE" ] && [ "$ROS_WORKSPACE" != "$ws_root" ]; then
            echo -e "\e[33m\n" \
                "Warning: Sourcing $ws_root will overlay $ROS_WORKSPACE.\n" \
                "         Open a new terminal if that's not what you want." \
                "\e[0m\n"
        fi

        if [ -f "$setup_file" ]; then
            echo "Sourcing workspace: $ws_root (profile: $active_profile)"
            source "$setup_file"
        else
            echo "No valid setup.bash found in $ws_root for profile ($active_profile)."
            return
        fi

        export ROS_SETUP_FILE="$setup_file"
        export ROS_WORKSPACE="$ws_root"
    }

    main "$@"
}
