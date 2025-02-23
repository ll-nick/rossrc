#TODO: What if workspace packages changes?
rossrc() {
    if ! declare -f __rossrc_source_global_ros_env > /dev/null; then
        __rossrc_source_global_ros_env() {
            local global_setup_file="/opt/ros/noetic/setup.bash"
            if [ ! -f "$global_setup_file" ]; then
                echo "No ROS installation found at $global_setup_file"
                exit
            fi
            source "$global_setup_file"
        }
    fi

    if ! declare -f __rossrc_is_within_workspace_heuristic > /dev/null; then
        __rossrc_is_within_workspace_heuristic() {
            local dir="$1"
            if [[ "$dir" != *_ws* ]]; then
                return 1
            fi
            return 0
        }
    fi

    if ! declare -f __rossrc_is_workspace_root > /dev/null; then
        __rossrc_is_workspace_root() {
            local dir="$1"
            if [ -d "$dir/.catkin_tools" ]; then
                return 0
            fi
            return 1
        }
    fi

    if ! declare -f __rossrc_get_workspace_root > /dev/null; then
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

    if ! declare -f __rossrc_get_path_to_setup_dir > /dev/null; then
        __rossrc_get_path_to_setup_dir() {
            local ws_root="$1"
            echo "$ws_root/devel"
        }
    fi

    if ! declare -f __rosscr_get_setup_file > /dev/null; then
        __rosscr_get_setup_file() {
            local setup_dir="$1"
            echo "$setup_dir/setup.bash"
        }
    fi

    main() {
        # Source the ROS installation if not already done
        if [ -z "$ROS_DISTRO" ]; then
            echo "Sourcing global environment..."
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

        local setup_script_dir
        setup_script_dir=$(__rossrc_get_path_to_setup_dir "$ws_root")
        local setup_file
        setup_file=$(__rosscr_get_setup_file "$setup_script_dir")

        # No need to re-source if the setup file is already sourced
        if [ "$ROS_SETUP_FILE" == "$setup_file" ]; then
            return
        fi
        # If the workspace changed, re-source the global setup to avoid workspace overlaying
        if [ -n "$ROS_WORKSPACE" ] && [ "$ROS_WORKSPACE" != "$ws_root" ]; then
            echo "Changing workspace from $ROS_WORKSPACE to $ws_root"
            echo "Sourcing global ROS environment to avoid workspace overlaying..."
            __rossrc_source_global_ros_env
        fi

        if [ -f "$setup_file" ]; then
            echo "Sourcing workspace: $setup_file (profile: $active_profile)"
            source "$setup_file"
        else
            echo "No valid setup.bash found for profile ($active_profile)."
            return
        fi

        export ROS_SETUP_FILE="$setup_file"
        export ROS_WORKSPACE="$ws_root"
    }

    main "$@"
}
