# Linux Config

![](.assets/screenfetch.png)

This repo contains some scripts to configure a new Linux system. Only fully tested on Arch Linux, but it should be able to at least install the dotfiles on other systems (including headless servers).

Usage:

```
cd ~
git clone https://github.com/gartnera/.linux-config
./.linux-config/configure.sh
```

Things you'd need to do:

- Install the system
- Graphics drivers/mesa/vaapi
- Select which chrome(ium) to use

# File Overview

## configure.sh

Sets some environment variables (`LINUXCONFIG_*`) used by the rest of the config. Installs required packages.

## configure-parts

Modular configuration scripts which each do one thing. Executed at the end of `configure.sh` by the `run-parts` command. You could disable a module by running `chmod -x 10-module`. `run-parts` executes in ascending order (10, 20, 30).

## dotfiles

### links

These files are directly symlinked into the home directory.

### copies

These files are copied into the home directory only if they don't already exist.

## files

Miscellaneous files that are referenced/linked by another script.

## scripts-bin

Scripts that I use on my system frequently. Prepended to `$PATH` so that we can override badly behaved system tools.

Note that I also configure `${HOME}/bin` in the path, this is where you should put binaries you download.

## system-configs

These configs are copied directly into the root (`/`) directory. Variables in file/directory paths and file contents are interpolated (see `configure-parts/60-systemconfig`)

## utils

Miscellaneous bash functions that can be `source`'d. Mainly for internal use in this repo, but could be useful elsewhere. Not in `$PATH`. 

# Making Changes

There are a few things hardcoded in the config (like git author name). If you want to update with any changes I make later, you'd either need to `git stash`, `git pull`, `git stash pop`. Alternatively commit your changes, then `git fetch origin` + `git rebase origin/main`. Committing your changes is a good idea if you want to run the same config on multiple systems.

Maybe you like some parts of the config but not others. You could still `git cherry-pick` individual changes onto your fork. In the following example, `origin` is your fork's remote name and `upstream` is this repo's remote name (`git remote add upstream ...`)

- Get upstream history: `git fetch upstream`
- Look through changelog to find commit: `git log upstream/main`
    - You could also specify one file/directory as an argument: `git log upstream/main -- configure-parts`
- `git cherry-pick <commit>`