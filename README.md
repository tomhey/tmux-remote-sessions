# tmux-remote-sessions

A (hopefully) less painful approach for working with remote tmux sessions from a local tmux instance.

## Plugin Use Case

You work with using tmux sessions to segregate your work into different projects or contexts, such as writing a plugin, a development activity, support on a remote customer site. One or more of these projects are an SSH connection onto a remote tmux session.

The aim is to make controlling the remote tmux session less painful. Previously you would have used various tricks to make this work, namely:
- different prefix keys on the local and remote tmux servers
- multiple prefix key presses to interact with the nested session
- unbinding and rebinding the prefix key manually

This plugin's approach is to rebind commands that should be routed to the remote sessions and include a test based on the session's name that conditionally handles the command locally or forwards it to the remote session. Effectively this gives you something close to the manual unbinding and rebinding approach without the need to do anything manually. 

## Installation

### Installation with Tmux Plugin Manager (recommended)

Add plugin to the list of TPM plugins in .tmux.conf:

set -g @plugin 'tomhey/tmux-remote-sessions'

Hit prefix + I to fetch the plugin and source it. That's it!

### Manual Installation

Clone the repo:

$ git clone https://github.com/tomhey/tmux-remote-sessions ~/clone/path
Add this line to the bottom of .tmux.conf:

run-shell ~/clone/path/tmux-remote-sessions.tmux
Reload TMUX environment with $ tmux source-file ~/.tmux.conf, and that's it.

### Configuration

Add the following options to your ~/.tmux.conf as appropiate:

- remote-session-toggle-key: Prefix key binding for toggling sessions between local (aka normal) and remote modes. No default, when this setting is omitted remote sessions can be set by changing the session name to end "-remote".
- remote-session-mode: Either 'auto' or 'manual' (default 'auto'). In 'auto' mode session will be remote or local based on the session name, any name ending "-remote" is remote. In 'manual' mode command forwarding is controlled via Shift-Up and Shift-Down.
 
## Usage

To start a session with a remote tmux server:
- create a new local session with a single window.
- connect (SSH) to the remote tmux server and select the session you want from the remote tmux server.
- rename your local session with a name ending "- remote".

Once renamed the following prefix based commands will be forward to the remote tmux session. Sessions that are not named "- remote" will continue to receive prefix based commands normally:

- break-pane
- choose-buffer
- choose-tree -Zw
- clock-mode
- copy-mode
- delete-buffer
- display-message
- display-panes
- find-window
- kill-pane
- kill-window
- last-pane
- last-window
- list-buffers
- move-window
- new-window
- next-layout
- paste-buffer
- rename-window
- resize-pane
- rotate-window
- select-layout
- select-pane
- select-window
- split-window
- swap-pane
- previous-window
- next-window

## ToDo (Things I'd like to do next)

* Tmux version testing, to fallback to the shell test command when the matching operator is not supported by "if-shell -F"
* Installation configuration/ flexiblity
* Key binding to enable/ disable remote sessions, automating renaming with/ without the "- remote" postfix
* Whitelist and blacklist support to override which binding/ commands are forwarded into a remote tmux session
* Support for forwarding non-prefix commands
* Better support for reloading configuration - at the moment bindings from other plugins will be clobbered on a configuration reload!

## Limitiations

* This plugin does not communicate with session commands on the remote tmux server. If you need to interact with session commands on the remote server, for example, to select a remote session then you have to fallback to double pressing the prefix key.
* Settings such as the prefix key and which commands to forward are hardcoded, where they should be plugin settings.
* Forwarding of mouse control commands is not supported.
* There is no select, copy and paste integration between the remote and local tmux session.

This plugin is a work in progress, and over time I hope to address some of these limitations.

## Implementation Details

Example implementation, using if-shell to conditionally examine the session name.

Old form (earlier tmux - requires external shell)

```bash
  tmux bind-key -T prefix 9 if-shell "test #{=-6:session_name} = remote" "display matched" "display different"
```

New form (version 2.7? - no external process)

```bash
  tmux bind-key -T prefix 9 if-shell -F "#{m:*remote,#{session_name}}" "display matched" "display different"
```

## References

Useful alternatives/ references for dealing with remote tmux sessions

- https://simplyian.com/2014/03/29/using-tmux-remotely-within-a-local-tmux-session
- http://stahlke.org/dan/tmux-nested
- https://github.com/samoshkin/tmux-config
- https://github.com/dojoteef/tmux-navigate
