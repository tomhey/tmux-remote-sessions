#!/usr/bin/env bash
set -e

TMP_FILE="$(mktemp)"

tmux -f /dev/null -L temp start-server \; list-keys > $TMP_FILE
tmux unbind-key -a
tmux source-file $TMP_FILE
