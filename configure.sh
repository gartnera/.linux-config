#!/bin/bash

set -e

cd "$(dirname "$0")"
export LINUXCONFIG_BASEPATH="$(pwd)"

source "${LINUXCONFIG_BASEPATH}/utils/which_silent"

export LINUXCONFIG_USERNAME=$USER

# detect gui
if [[ -n "$DISPLAY" ||  -n "$WAYLAND_DISPLAY" ]]; then
	LINUXCONFIG_GUI='yes'
fi
export LINUXCONFIG_GUI

# detect package manager
if which_silent pacman; then
	export LINUXCONFIG_PACMAN='yes'
elif which_silent apt; then
	export LINUXCONFIG_APT='yes'
elif which_silent yum; then
	export LINUXCONFIG_YUM='yes'
fi

# configure overrides here
#unset LINUXCONFIG_GUI

if [[ -n "$LINUXCONFIG_PACMAN" ]]; then
	source "${LINUXCONFIG_BASEPATH}/utils/pacman"
	pacman_sinstall run-parts gettext vim
fi

run-parts configure-parts
