#!/bin/bash

__rossrc_source_global_ros_env() {
    source /opt/ros/noetic/setup.bash
}

source "$(dirname "${BASH_SOURCE[0]}")/rossrc.base.bash"
