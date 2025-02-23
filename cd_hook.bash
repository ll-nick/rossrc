cd() {
    builtin cd "$@" || return
    rossrc
}
