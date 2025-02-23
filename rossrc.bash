#TODO: Split into smaller functions
#TODO: What if workspace packages changes?
rossrc() {
    source_global_env() {
        echo "Sourcing global environment..."
        source /opt/mrtsoftware/setup.bash
        source /opt/mrtros/setup.bash
    }

    is_within_workspace_heuristic() {
        local dir="$1"
        if [[ "$dir" != *_ws* ]]; then
            return 1
        fi
        return 0
    }

    is_workspace_root() {
        local dir="$1"
        if [ -d "$dir/.catkin_tools" ]; then
            return 0
        fi
        return 1
    }

    get_workspace_root() {
        local dir="$1"
        while [ "$dir" != "/" ]; do
            if ! is_workspace_root "$dir"; then
                dir=$(dirname "$dir")
                continue
            fi
            echo "$dir"
            return
        done
        echo ""  # Return an empty string if no workspace is found
    }

    get_devel_dir() {
        local ws_root="$1"
        local profile_file="$ws_root/.catkin_tools/profiles/profiles.yaml"
        local devel_dir="devel"

        if [ -f "$profile_file" ]; then
            local active_profile
            active_profile=$(sed 's/active: //' < "$profile_file")
            if [ "$active_profile" != "release" ]; then
                devel_dir="devel_$active_profile"
            fi
        fi
        echo "$devel_dir"
    }

    get_setup_file() {
        local ws_root="$1"
        local devel_dir="$2"
        echo "$ws_root/$devel_dir/setup.bash"
    }

    # Source global ROS setup if not already sourced
    # TODO: Make sourcing the global env a configurable function to make this tool more generic
    # (e.g. if not global_env() then global_env_default())
    if [ -z "$ROS_DISTRO" ]; then
        source_global_env
    fi

    # If heuristic is not satisfied, we can return early
    if ! is_within_workspace_heuristic "$(pwd)"; then
        return
    fi

    # Walk up the directory tree to find workspace root
    # TODO: Remove while loop, just cut path after _ws
    local ws_root
    ws_root=$(get_workspace_root "$(pwd)")
    if [ -z "$ws_root" ]; then
        return
    fi

    # Determine the active profile
    # TODO: Make the devel dir function configurable
    local devel_dir
    devel_dir=$(get_devel_dir "$ws_root")

    # Source the correct setup file
    # TODO: If the workspace changed, re-source the global setup (but not if only the profile changed)
    local setup_file
    setup_file=$(get_setup_file "$ws_root" "$devel_dir")

    # Avoid re-sourcing if already in the same workspace
    if [ "$ROS_SETUP_FILE" == "$setup_file" ]; then
        echo "Aldready sourced workspace: $ws_root (profile: $active_profile)"
        return
    fi

    # Store the new workspace path
    export ROS_SETUP_FILE="$setup_file"
    export ROS_WORKSPACE="$ws_root"
    if [ -f "$setup_file" ]; then
        echo "Sourcing workspace: $setup_file (profile: $active_profile)"
        source "$setup_file"
    else
        echo "No valid setup.bash found for profile ($active_profile)."
    fi
}
