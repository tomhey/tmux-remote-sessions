#!/usr/bin/env bash
set -e

# Script that takes the output from "tmux list-keys" the key binding text and apply these settings
# to tmux, effectively allowing an earlier dump of tmux key binding to be restored.

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
source $SCRIPT_DIR/escape-util

if [ $# -ne 1 ]; then
  echo "Usage $0: <binding-input-file>"
  exit 1
fi

INPUT_FILE="$1"
TMP_FILE="$(mktemp)"

# bind-key    -T prefix       PPage             copy-mode -u
# bind-key -r -T prefix       Up                select-pane -U

bind_command_regexp="^bind-key +((-r) +)?-T ([^ ]+) +([^ ]+) +(.+)$"

rm -f $TMP_FILE
while read -r line
do
  if [[ $line =~ $bind_command_regexp ]]; then
    bind_flags="${BASH_REMATCH[2]}"
    bind_key_table="${BASH_REMATCH[3]}"
    bind_key="${BASH_REMATCH[4]}"
    bind_command="${BASH_REMATCH[5]}"

    # A few key names need special quoting or escaping
    if [ $bind_key == ";" ]; then
        bind_key="\;"
    elif [ $bind_key == "$" ]; then
        bind_key="'$'"
    elif [ $bind_key == "~" ]; then
        bind_key="'~'"
    elif [ $bind_key == "#" ]; then
        bind_key="'#'"
    elif [ $bind_key == "'" ]; then
        bind_key="\"'\""
    elif [ $bind_key == "\"" ]; then
        bind_key="'\"'"
    fi

    quote_semicolons "$bind_command"
    bind_command="$return_value"

    echo "unbind-key -T $bind_key_table $bind_key" >> $TMP_FILE
    echo "bind-key $bind_flags -T $bind_key_table $bind_key $bind_command" >> $TMP_FILE

  else
    echo "Regexp failed to parse bind-key line: '$line'"
    exit 1
  fi
done < "$INPUT_FILE"

tmux source-file $TMP_FILE

rm -f $TMP_FILE
