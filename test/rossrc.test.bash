__rossrc_source_global_ros_env() {
    export ROS_DISTRO=testora
}

__rossrc_get_path_to_setup_dir() {
    local ws_root="$1"
    local profile_file="$ws_root/.catkin_tools/profiles/profiles.yaml"
    local setup_dir="devel"

    if [ -f "$profile_file" ]; then
        local active_profile
        active_profile=$(sed 's/active: //' < "$profile_file")
        if [ "$active_profile" != "release" ]; then
            setup_dir="devel_$active_profile"
        fi
    fi
    echo "$ws_root/$setup_dir"
}

source "$(dirname "${BASH_SOURCE[0]}")/../rossrc.base.bash"
