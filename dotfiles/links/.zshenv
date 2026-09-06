# Read by zsh in EVERY mode: interactive, login, and -- critically -- non-interactive
# `ssh host <cmd>`, which reads neither .zshrc nor .zprofile. Sourcing the shared POSIX
# profile here is what keeps the environment identical everywhere.

# `path` is tied to PATH; -U makes it a unique array so repeated sourcing (this file runs
# for nested zsh invocations too) collapses duplicates instead of growing PATH.
typeset -U path PATH

# emulate sh so POSIX constructs in .profile are parsed as intended by zsh.
[ -r "${HOME}/.profile" ] && emulate sh -c '. "${HOME}/.profile"'
