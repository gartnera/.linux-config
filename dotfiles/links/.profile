# POSIX shell profile: the single source of truth for session environment.
#
# This file is what uwsm sources when building the graphical session environment
# (uwsm-libexec/prepare-env.sh sources /etc/profile then ~/.profile, in plain sh -- it does
# NOT read any zsh file). ~/.zshenv sources this too, which is what makes the environment
# identical across the GUI, a VT tty login, and ssh (including non-interactive
# `ssh host <cmd>`, which reads ONLY ~/.zshenv).
#
# Keep this POSIX sh. No zsh/bash syntax -- it is sourced by /bin/sh.
#
# Replaces ~/.pam_environment, which has done nothing since Linux-PAM 1.5.0 removed
# support for it (we are on 1.7). Under sway these vars came from /opt/swaylog instead,
# which masked the problem.

export PATH="${HOME}/bin:${HOME}/.linux-config/scripts-bin:${HOME}/go/bin:${HOME}/.local/bin:${PATH}"
export QT_QPA_PLATFORMTHEME=qt5ct
