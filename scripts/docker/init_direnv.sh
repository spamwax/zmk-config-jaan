#!/bin/bash

export PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:"$PATH"
# shellcheck disable=SC1090
source ~/.bashrc >/dev/null 2>&1
cd /root/zmk-workspace || exit

eval "$(direnv export bash)"
direnv exec . just init >/dev/null 2>&1
direnv exec . just build all

