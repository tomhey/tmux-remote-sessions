#!/bin/bash -e

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
source $SCRIPT_DIR/escape-util

# test function
function test_quote_semicolons {
  input="$1"
  expected_output="$2"

  quote_semicolons "$input"

  if [ "$expected_output" == "$return_value" ]; then
    echo -e "\e[32mPASS\e[0m   input:$input"
  else
    echo -e "\e[31mFAIL\e[0m   input:$input"
    echo    "  output-exp: $expected_output"
    echo    "  output-act: $return_value"
  fi
}

# And some tests
test_quote_semicolons "select-pane -t = ; send-keys \"-M;\" and another thing ';'ssdf" \
	              "select-pane -t = \\; send-keys \"-M;\" and another thing ';'ssdf"

test_quote_semicolons "\"select-pane\" -t = ; send-keys \"-M;\" and another thing ;" \
                      "\"select-pane\" -t = \\; send-keys \"-M;\" and another thing \\;"

test_quote_semicolons "; xselect-pane" \
                      "\\; xselect-pane"

test_quote_semicolons "abc \\\"; xselect-pane\\\"" \
                      "abc \\\"\\; xselect-pane\\\""

test_quote_semicolons "; \"xsel'ect-pane' ; \"" \
                      "\\; \"xsel'ect-pane' ; \""

test_quote_semicolons "\"xselect-pane\\\" ;x\"" \
                      "\"xselect-pane\\\" ;x\""

test_quote_semicolons "'xselect-pane\\' ;'" \
                      "'xselect-pane\\' ;'"
