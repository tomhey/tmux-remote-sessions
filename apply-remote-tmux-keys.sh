#!/usr/bin/env bash
set -e

# ...
# Applies remote tmux key bindings
# bind-key    -T prefix       PPage             copy-mode -u
# bind-key -r -T prefix       Up                select-pane -U

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
source $SCRIPT_DIR/escape-util

if [ $# -ne 0 ]; then
  echo "Usage $0"
  exit 1
fi

declare -a FORWARD_MODE_WHITELIST=("prefix")

declare -a FORWARD_COMMAND_WHITELIST=("break-pane"
                                      "choose-buffer"
                                      "choose-tree -Zw"
                                      "clock-mode"
                                      "copy-mode"
                                      "delete-buffer"
                                      "display-message"
                                      "display-panes"
                                      "find-window"
                                      "kill-pane"
                                      "kill-window"
                                      "last-pane"
                                      "last-window"
                                      "list-buffers"
                                      "move-window"
                                      "new-window"
                                      "next-layout"
                                      "paste-buffer"
                                      "rename-window"
                                      "resize-pane"
                                      "rotate-window"
                                      "select-layout"
                                      "select-pane"
                                      "select-window"
                                      "split-window"
                                      "swap-pane"
                                      "previous-window"
                                      "next-window")


INPUT_FILE="$SCRIPT_DIR/original_bindings.txt"
TMP_FILE="$(mktemp)"
TRIGGER_COMMAND_FILE="$SCRIPT_DIR/trigger_file.sh"

tmux list-keys > $INPUT_FILE

rm -f $TMP_FILE
rm -f $TRIGGER_COMMAND_FILE

echo "#!/usr/bin/env bash"  > $TRIGGER_COMMAND_FILE
echo "set -e"              >> $TRIGGER_COMMAND_FILE
echo ""                    >> $TRIGGER_COMMAND_FILE
echo "case \"\$1\" in"     >> $TRIGGER_COMMAND_FILE
echo ""                    >> $TRIGGER_COMMAND_FILE

bind_command_regexp="^bind-key +((-r) +)?-T ([^ ]+) +([^ ]+) +(.+)$"

while read -r line
do

  if [[ $line =~ $bind_command_regexp ]]; then
    bind_flags="${BASH_REMATCH[2]}"
    bind_key_table="${BASH_REMATCH[3]}"
    bind_key="${BASH_REMATCH[4]}"
    bind_command="${BASH_REMATCH[5]}"

    # A few key names need special quoting or escaping
    if [[ $bind_key == ";" || $bind_key == '\;' ]]; then
        send_key="';'"
        bind_key='\;'
        key_name="SemiColon"
    elif [[ $bind_key == "#" || $bind_key == '\#' ]]; then
        send_key="'#'"
        bind_key="'#'"
        key_name="Hash"
    elif [[ $bind_key == "$" || $bind_key == '\$' ]]; then
        bind_key="'$'"
        send_key="'$'"
        key_name="Dollar"
    elif [[ $bind_key == "'" || $bind_key == "\\'" ]]; then
        send_key="\\'"
        bind_key="\"'\""
        key_name="SingleQuote"
    elif [[ $bind_key == "\"" ]]; then
        bind_key="'\"'"
        send_key="'\\\"'"
        key_name="DoubleQuote"
    elif [[ $bind_key == "~" ]]; then
        bind_key="'~'"
        send_key="'~'"
        key_name="Tilde"
    elif [[ $bind_key == "&" ]]; then
        bind_key="&"
        send_key="&"
        key_name="Ampersand"
    elif [[ $bind_key == '\\' ]]; then
        # unmodified bind_key
        send_key='\\\\'
        key_name="Backslash"
    elif [[ $bind_key == 'C-\\' ]]; then
        # unmodified bind_key
        send_key='C-\\\\'
        key_name="C-Backslash"
    else
        # unmodified bind_key
        send_key="$bind_key"
        key_name="$bind_key"
    fi

    for key_table in ${FORWARD_MODE_WHITELIST[@]}; do
      for tmux_command in "${FORWARD_COMMAND_WHITELIST[@]}"; do

        if [[ "$bind_key_table" == "$key_table" && 
              "$bind_command" = *"$tmux_command"* ]]; then

          remote_keys="\"send-prefix ; send-keys $send_key\""
          remote_test="if-shell -F \"#{m:*remote,#{session_name}}\""

          if [[ $bind_command = *"\""* || $bind_key = *"\""* ]]; then

            echo "  \"${bind_key_table}-${key_name}\")" >> $TRIGGER_COMMAND_FILE
            echo "    tmux $bind_command" >> $TRIGGER_COMMAND_FILE
            echo "    ;;" >> $TRIGGER_COMMAND_FILE
            echo "" >> $TRIGGER_COMMAND_FILE

            echo "unbind-key -T $bind_key_table $bind_key" >> $TMP_FILE
            echo "bind-key $bind_flags -T $bind_key_table $bind_key $remote_test $remote_keys \"run-shell '$TRIGGER_COMMAND_FILE ${bind_key_table}-${key_name}'\"" >> $TMP_FILE

          else

            local_command="\"$bind_command\""
            bind_command="$remote_test $remote_keys $local_command"
            quote_semicolons "$bind_command"
            bind_command="$return_value"

            echo "unbind-key -T $bind_key_table $bind_key" >> $TMP_FILE
            echo "bind-key $bind_flags -T $bind_key_table $bind_key $bind_command" >> $TMP_FILE
          fi
        fi
      done
    done

  else
    echo "Regexp failed to parse bind-key line: '$line'"
    exit 1
  fi
done < "$INPUT_FILE"

chmod +x $TRIGGER_COMMAND_FILE

echo "  *)" >> $TRIGGER_COMMAND_FILE
echo "    echo \"Unknown Input: \$1\"" >> $TRIGGER_COMMAND_FILE
echo "    ;;" >> $TRIGGER_COMMAND_FILE
echo "" >> $TRIGGER_COMMAND_FILE

echo "esac" >> $TRIGGER_COMMAND_FILE

tmux source-file $TMP_FILE
rm -f $TMP_FILE

