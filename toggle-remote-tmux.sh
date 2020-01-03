#!/usr/bin/env bash
set -e

session_name=$(tmux display-message -p '#S')

if [[ $session_name == *-remote ]]; then
    session_name="${session_name%-remote}"
else
    session_name="${session_name}-remote"
fi

tmux rename-session "$session_name"
