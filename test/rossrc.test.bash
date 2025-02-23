__rossrc_source_global_ros_env() {
    export ROS_DISTRO=testora
    GLOBAL_SOURCE_COUNTER=$((GLOBAL_SOURCE_COUNTER + 1))
}

__rossrc_get_path_to_setup_dir() {
    local ws_root="$1"
    local active_profile="$2"
    local setup_dir="devel"

    if [ "$active_profile" != "release" ]; then
        setup_dir="devel_$active_profile"
    fi
    echo "$ws_root/$setup_dir"
}

source "$(dirname "${BASH_SOURCE[0]}")/../rossrc.base.bash"
