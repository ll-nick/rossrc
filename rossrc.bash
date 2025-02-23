#TODO: Split into smaller functions
#TODO: What if workspace packages changes?
rossrc() {
    source_global_env() {
        echo "Sourcing global environment..."
        source /opt/mrtsoftware/setup.bash
        source /opt/mrtros/setup.bash
    }

    is_within_workspace_heuristic() {
        local ws_dir="$1"
        if [[ "$ws_dir" != *_ws* ]]; then
            return 1
        fi
        return 0
    }

    is_workspace() {
        local ws_dir="$1"
        if [ -d "$ws_dir/.catkin_tools" ]; then
            return 0
        fi
        return 1
    }

    # Source global ROS setup if not already sourced
    # TODO: Make sourcing the global env a configurable function to make this tool more generic
    # (e.g. if not global_env() then global_env_default())
    if [ -z "$ROS_DISTRO" ]; then
        source_global_env
    fi

    ws_dir=$(pwd)

    # Not a catkin workspace if not in a directory with _ws in the name
    # Replace with function:
    if ! is_within_workspace_heuristic "$ws_dir"; then
        return
    fi

    # Walk up the directory tree to find workspace root
    # TODO: Remove while loop, just cut path after _ws
    while [ "$ws_dir" != "/" ]; do
        if ! is_workspace "$ws_dir"; then
            ws_dir=$(dirname "$ws_dir")
            continue
        fi

        # Determine the active profile
        # TODO: Make the devel dir function configurable
        local profile_file="$ws_dir/.catkin_tools/profiles/profiles.yaml"
        local devel_dir="devel"
        if [ -f "$profile_file" ]; then
            local active_profile
            active_profile=$(sed 's/active: //' < "$profile_file")
            if [ "$active_profile" != "release" ]; then
                devel_dir="devel_$active_profile"
            fi
        fi

        # Source the correct setup file
        # TODO: If the workspace changed, re-source the global setup (but not if only the profile changed)
        local setup_file="$ws_dir/$devel_dir/setup.bash"

        # Avoid re-sourcing if already in the same workspace
        if [ "$ROS_SETUP_BASH" == "$setup_file" ]; then
            echo "Aldready sourced workspace: $ws_dir (profile: $active_profile)"
            return
        fi

        # Store the new workspace path
        export ROS_SETUP_BASH="$setup_file"
        export ROS_WORKSPACE="$ws_dir"
        if [ -f "$setup_file" ]; then
            echo "Sourcing workspace: $setup_file (profile: $active_profile)"
            source "$setup_file"
        else
            echo "No valid setup.bash found for profile ($active_profile)."
        fi
        return
    done
}
