cd() {
    builtin cd "$@" || return

    if ! __rossrc_is_within_workspace_heuristic "$(pwd)"; then
        return
    fi

    rossrc
}
