# 🧠 rossrc - Intelligent ROS Environment Sourcing

[![Unit Test Status](https://img.shields.io/github/actions/workflow/status/ll-nick/rossrc/run-tests.yml?branch=main&label=tests)](https://github.com/ll-nick/rossrc/actions/workflows/run-tests.yml?query=branch%3Amain)

`rossrc` is a lightweight Bash utility designed to intelligently source the appropriate ROS (Robot Operating System) environment only when required.

The script ensures that the global ROS installation is sourced only when necessary and selects the correct workspace environment dynamically when working within a recognized ROS workspace.
This can significantly reduce Bash startup time if you work with large ROS installations.

## ✨ Features
- **Minimizes Shell Startup Overhead**: Only sources ROS when required for quick shell startup.
- **Lightweight Workspace Detection**: Uses heuristics to quickly estimate if the current directory is within a ROS workspace.
- **Prevents Redundant Sourcing**: Avoids re-sourcing the workspace if it has already been set up.
- **Supports Customization**: Allows users to override internal functions for custom behavior.
- **Workspace Switching Handling**: Detects when moving between different workspaces and properly reconfigures the environment.
- **Automagic**: Source the provided cd hook to automatically source the workspace when changing directories.

## 🚀 Usage

Whenever you want to source the ROS environment, simply run the `rossrc` command.
If you are already in a workspace, it will source the workspace environment.
If you sourced the cd hook, you actually don't need to do anything, simple `cd` into your workspace and the environment will be sourced automatically.

To force re-sourcing of the workspace (e.g. after adding new packages), use the `-f` or `--force` option.

## ⚡️ Assumptions

Without any customization, `rossrc` makes the following assumptions:

1. Workspaces have `_ws` in their name.
2. The workspace root contains a `.catkin_tools` directory.
3. The `setup.bash` file is located in the `devel` directory of the workspace.

All of these assumptions can be customized by overriding the relevant functions in a custom configuration as described below.

## 📦 Setup

<details>
<summary>Prerequisites</summary>

- ROS 1 installation (I know I'm a bit late to the party. It should be easy to adapt this for ROS 2 though).
- Bash shell (sorry, no Zsh support yet).

</details>

<details>
<summary>Using a Provided Configuration</summary>

Just clone this repository and source the relevant `rossrc.*.bash` file in your `.bashrc`.

```bash
git clone https://github.com/ll-nick/rossrc.git ~/.rossrc
```

```bash
# Source the relevant config in your .bashrc, e.g.
source ~/.rossrc/rossrc.noetic.bash
```
</details>

<details>
<summary>Using a Custom Configuration</summary>

You can also create a custom configuration using individual implementations for some functions, e.g.:

```bash
# Create a custom rossrc file, e.g. ~/rossrc.custom.bash
#!/bin/bash

__rossrc_source_global_ros_env() {
    source /opt/some_custom_ros/setup.bash
}

source ~/.rossrc/rossrc.base.bash"
```

Then source this file in your `.bashrc`:

```bash
source ~/rossrc.custom.bash
```

Some key functions that can be overridden include:
- `__rossrc_is_within_workspace_heuristic()`: Estimates if the current directory is inside a workspace using a lightweight heuristic.
- `__rossrc_source_global_ros_env()`: Sources the global ROS installation.
- `__rossrc_get_workspace_root()`: Finds the root of the workspace containing the current working directory.

Check the provided `rossrc.base.bash` file for more details.

</details>

<details>
<summary>Automagic Workspace Sourcing using cd hook</summary>

You can also add the provided `cd` hook to automatically source the workspace when changing directories.
To do this, add the following line to your `.bashrc`:

```bash
source ~/.rossrc/cd_hook.bash
```
</details>

## License
This project is released under the MIT License.

