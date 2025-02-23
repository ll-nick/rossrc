#TODO: Split into smaller functions
#TODO: What if workspace packages changes?
rossrc() {
    # Source global ROS setup if not already sourced
    # TODO: Make sourcing the global env a configurable function to make this tool more generic
    # (e.g. if not global_env() then global_env_default())
    if [ -z "$ROS_DISTRO" ]; then
        echo "Sourcing mrtsoftware and mrtros..."
        source /opt/mrtsoftware/setup.bash
        source /opt/mrtros/setup.bash
    fi

    ws_dir=$(pwd)

    # Not a catkin workspace if not in a directory with _ws in the name
    if [[ "$ws_dir" != *_ws* ]]; then
        return
    fi

    # Walk up the directory tree to find workspace root
    # TODO: Remove while loop, just cut path after _ws
    while [ "$ws_dir" != "/" ]; do
        if [ ! -d "$ws_dir/.catkin_tools" ]; then
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
        if [ -f "$setup_file" ]; then
            echo "Sourcing workspace: $setup_file (profile: $active_profile)"
            source "$setup_file"
        else
            echo "No valid setup.bash found for profile ($active_profile)."
        fi
        return
    done
}
