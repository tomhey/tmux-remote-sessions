#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(cd $(dirname $0) && pwd)

cd $SCRIPT_DIR

apply-remote-session-bindings() {

  ./apply-remote-tmux-keys.sh
  tmux display-message "applied remote session key bindings"

  toggle_remote_session=$(tmux show-option -gqv @remote-session-toggle-key)
  if [ -n $toggle-remote-session ]; then
      tmux bind-key -T prefix $toggle_remote_session run-shell $SCRIPT_DIR/toggle-remote-tmux.sh
  fi
}

# Returns the next prefix key (by ascii ordering b -> c)
# Output written into stdout
next_prefix() {
  prefix=$(tmux show-option -gqv prefix)

  key_ascii=$(printf "%d" \'${prefix:2})
  key_ascii=$(($key_ascii+1))
  new_prefix_key=$(printf \\$(printf '%03o' $key_ascii))
  new_prefix="${prefix:0:1}-$new_prefix_key"

  echo "$new_prefix"
}

apply-manual-session-bindings() {

  prefix=$(tmux show-option -gqv prefix)
  new_prefix=$(tmux show-option -gqv @remote-session-manual-prefix)
  if [ -z $new_prefix ]; then
    new_prefix=$(next_prefix)
  fi

  tmux display-message "Prefix: $prefix New Prefix: $new_prefix"

  bind -n S-up \
          set -qg window-status-current-style bg=green \; \
          set -qg status-bg colour25 \; \
          set -qg prefix $new_prefix
  
  bind -n S-down \
          set -qg window-status-current-style bg=colour25 \; \
          set -qg status-bg colour25 \; \
          set -qg prefix $prefix
}


remote_session_mode=$(tmux show-option -gqv @remote-session-mode)
remote_session_bind_delay=$(tmux show-option -gqv remote-session-bind-delay)

case "$remote_session_mode" in

  auto|"")
    (sleep ${remote_session_bind_delay:-10}; apply-remote-session-bindings) &
  ;;

  manual)
    apply-manual-session-bindings
  ;;

  disable)
  ;;

  *)
    tmux display-message "Unknown remote-session-mode '$remote_session_mode' disabling tmux-remote-sessions plugin"
  ;;
esac
