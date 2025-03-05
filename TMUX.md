# TMUX Command Reference

This document provides a terse summary of tmux commands and their options.

## Session Management

| Command | Alias | Description | Options |
|---------|-------|-------------|---------|
| `attach-session` | `attach` | Attach to an existing session | `-d` (detach other clients), `-r` (read-only), `-x` (not read-only), `-c` (working directory), `-f` (flags), `-t` (target session) |
| `detach-client` | `detach` | Detach from a session | `-a` (all but current client), `-P` (print info), `-E` (shell command on detach), `-s` (target session), `-t` (target client) |
| `has-session` | `has` | Check if a session exists | `-t` (target session) |
| `kill-session` | | Kill a session | `-a` (all but current/specified), `-C` (clear alerts), `-t` (target session) |
| `kill-server` | | Kill the tmux server | |
| `list-clients` | `lsc` | List clients attached to server | `-F` (format), `-f` (filter), `-t` (target session) |
| `list-sessions` | `ls` | List active sessions | `-F` (format), `-f` (filter) |
| `lock-client` | `lockc` | Lock a client | `-t` (target client) |
| `lock-session` | `locks` | Lock all clients attached to a session | `-t` (target session) |
| `new-session` | `new` | Create a new session | `-A` (attach if exists), `-d` (detached), `-D` (detach other clients), `-E` (update environment), `-P` (print info), `-X` (not update environment), `-c` (start directory), `-e` (environment), `-F` (format), `-f` (flags), `-n` (window name), `-s` (session name), `-t` (target session), `-x` (width), `-y` (height), `[shell-command]` (command to execute) |
| `refresh-client` | `refresh` | Refresh a client's display | `-c` (clear), `-D` (delete), `-l` (list), `-L` (reload), `-R` (redraw), `-S` (status line), `-U` (refresh), `-f` (flags), `-t` (target client) |
| `rename-session` | `rename` | Rename a session | `-t` (target session), `new-name` |
| `show-messages` | `showmsgs` | Show client messages | `-J` (jump to bottom), `-T` (title), `-t` (target client) |
| `source-file` | `source` | Execute commands from a file | `-F` (not using formatter), `-n` (dry-run), `-q` (quiet), `-v` (verbose), `-t` (target pane), `path` (file to source) |
| `start-server` | `start` | Start the tmux server | |
| `suspend-client` | `suspendc` | Suspend a client | `-t` (target client) |
| `switch-client` | `switchc` | Switch the client to another session | `-E` (update environment), `-l` (last), `-n` (next), `-p` (previous), `-r` (redraw), `-Z` (zoomed), `-c` (target client), `-t` (target session), `-T` (key-table) |

## Window Management

| Command | Alias | Description | Options |
|---------|-------|-------------|---------|
| `choose-tree` | | Choose a session, window, or pane | `-G` (all sessions in one tree), `-N` (no selection), `-r` (reversed order), `-s` (sessions only), `-w` (windows only), `-Z` (zoomed), `-F` (format), `-f` (filter), `-K` (key format), `-O` (sort-order), `-t` (target pane) |
| `find-window` | `findw` | Find a window matching a pattern | `-C` (match only visible content), `-i` (ignore case), `-N` (index), `-r` (regex), `-T` (all matches), `-Z` (zoomed), `-t` (target pane), `match-string` |
| `kill-window` | `killw` | Kill a window | `-a` (all but current/specified), `-t` (target window) |
| `last-window` | `last` | Select the last window | `-t` (target session) |
| `link-window` | `linkw` | Link a window to another window | `-a` (after target), `-b` (before target), `-d` (no select), `-k` (kill if exists), `-s` (src window), `-t` (dst window) |
| `list-windows` | `lsw` | List windows | `-a` (all sessions with windows), `-F` (format), `-f` (filter), `-t` (target session) |
| `move-window` | `movew` | Move a window | `-a` (after target), `-b` (before target), `-d` (no select), `-k` (kill if exists), `-r` (respects window order), `-s` (src window), `-t` (dst window) |
| `new-window` | `neww` | Create a new window | `-a` (after target), `-b` (before target), `-d` (no select), `-k` (kill if exists), `-P` (print info), `-S` (no shell), `-c` (start directory), `-e` (environment), `-F` (format), `-n` (window name), `-t` (target window), `[shell-command]` (command to execute) |
| `next-window` | `next` | Move to the next window | `-a` (cycle through all windows with alerts), `-t` (target session) |
| `previous-window` | `prev` | Move to the previous window | `-a` (cycle through all windows with alerts), `-t` (target session) |
| `rename-window` | `renamew` | Rename a window | `-t` (target window), `new-name` |
| `respawn-window` | `respawnw` | Reuse a window for a new command | `-k` (kill if running), `-c` (start directory), `-e` (environment), `-t` (target window), `[shell-command]` (command to execute) |
| `rotate-window` | `rotatew` | Rotate positions of panes in a window | `-D` (clockwise), `-U` (counter-clockwise), `-Z` (zoomed), `-t` (target window) |
| `select-window` | `selectw` | Select a window | `-l` (last selected), `-n` (next), `-p` (previous), `-T` (newer activity), `-t` (target window) |
| `swap-window` | `swapw` | Swap two windows | `-d` (no select), `-s` (src window), `-t` (dst window) |
| `unlink-window` | `unlinkw` | Unlink a window | `-k` (kill if last), `-t` (target window) |

## Pane Management

| Command | Alias | Description | Options |
|---------|-------|-------------|---------|
| `break-pane` | `breakp` | Break a pane into a new window | `-a` (after target), `-b` (before target), `-d` (no select), `-P` (print info), `-F` (format), `-n` (window name), `-s` (src pane), `-t` (dst window) |
| `capture-pane` | `capturep` | Capture the contents of a pane | `-a` (alternate screen), `-C` (escape non-printable chars), `-e` (escape special chars), `-J` (join wrapped lines), `-N` (include notification alerts), `-p` (stdout), `-P` (capture pane ID), `-q` (quiet), `-T` (capture window position info), `-b` (buffer name), `-E` (end line), `-S` (start line), `-t` (target pane) |
| `display-panes` | `displayp` | Display visible pane numbers | `-b` (big numbers), `-N` (no timeout), `-d` (duration), `-t` (target client), `[template]` |
| `join-pane` | `joinp` | Join a pane to another window | `-b` (before target), `-d` (no select), `-f` (full window size), `-h` (horizontal split), `-v` (vertical split), `-l` (size), `-s` (src pane), `-t` (dst pane) |
| `kill-pane` | `killp` | Kill a pane | `-a` (all but current/specified), `-t` (target pane) |
| `last-pane` | `lastp` | Select the last active pane | `-d` (no select), `-e` (enable focus reporting), `-Z` (zoomed), `-t` (target window) |
| `list-panes` | `lsp` | List panes | `-a` (all sessions/windows with panes), `-s` (all panes in all windows in current session), `-F` (format), `-f` (filter), `-t` (target window) |
| `move-pane` | `movep` | Move a pane | `-b` (before target), `-d` (no select), `-f` (full width/height), `-h` (horizontal), `-v` (vertical), `-l` (size), `-s` (src pane), `-t` (dst pane) |
| `pipe-pane` | `pipep` | Pipe output from a pane to a shell command | `-I` (stdin to command), `-O` (stdout to command), `-o` (only stdout), `-t` (target pane), `[shell-command]` |
| `resize-pane` | `resizep` | Resize a pane | `-D` (down), `-L` (left), `-R` (right), `-T` (top), `-U` (up), `-M` (mouse drag), `-Z` (toggle zoom), `-x` (width), `-y` (height), `-t` (target pane), `[adjustment]` |
| `respawn-pane` | `respawnp` | Reuse a pane for a new command | `-k` (kill if running), `-c` (start directory), `-e` (environment), `-t` (target pane), `[shell-command]` |
| `select-pane` | `selectp` | Select a pane | `-D` (down), `-d` (disable focus reporting), `-e` (enable focus reporting), `-L` (left), `-l` (last), `-M` (clear marked pane), `-m` (mark pane), `-R` (right), `-U` (up), `-Z` (toggle zoom), `-T` (title), `-t` (target pane) |
| `split-window` | `splitw` | Split a pane into two | `-b` (before target), `-d` (no select), `-e` (update environment), `-f` (full width/height), `-h` (horizontal), `-I` (only new pane gets stdin), `-P` (print info), `-v` (vertical), `-Z` (zoomed), `-c` (start directory), `-e` (environment), `-F` (format), `-l` (size), `-t` (target pane), `[shell-command]` |
| `swap-pane` | `swapp` | Swap two panes | `-d` (no select), `-D` (down), `-U` (up), `-Z` (zoomed), `-s` (src pane), `-t` (dst pane) |

## Layout Management

| Command | Alias | Description | Options |
|---------|-------|-------------|---------|
| `next-layout` | `nextl` | Move to the next layout | `-t` (target window) |
| `previous-layout` | `prevl` | Move to the previous layout | `-t` (target window) |
| `select-layout` | `selectl` | Select a layout | `-E` (spread all panes evenly), `-n` (next layout), `-o` (previous layout), `-p` (previous layout), `-t` (target pane), `[layout-name]` |

## Buffer and Copy Management

| Command | Alias | Description | Options |
|---------|-------|-------------|---------|
| `choose-buffer` | | Choose a paste buffer | `-N` (without preview), `-r` (reversed order), `-Z` (zoomed), `-F` (format), `-f` (filter), `-K` (key format), `-O` (sort-order), `-t` (target pane), `[template]` |
| `clear-history` | `clearhist` | Clear pane history | `-H` (hidden history buffer), `-t` (target pane) |
| `copy-mode` | | Enter copy mode | `-e` (exit after copy ends), `-H` (scroll to bottom), `-M` (search only visible content), `-u` (select full line by default), `-q` (cancel copy mode when key is pressed), `-s` (src pane), `-t` (target pane) |
| `delete-buffer` | `deleteb` | Delete a paste buffer | `-b` (buffer name) |
| `list-buffers` | `lsb` | List paste buffers | `-F` (format), `-f` (filter) |
| `load-buffer` | `loadb` | Load data into a buffer | `-b` (buffer name), `-t` (target client), `path` |
| `paste-buffer` | `pasteb` | Paste a buffer's contents | `-d` (delete after pasting), `-p` (stdout), `-r` (bracket the pasted data), `-s` (separator), `-b` (buffer name), `-t` (target pane) |
| `save-buffer` | `saveb` | Save a buffer to a file | `-a` (append), `-b` (buffer name), `path` |
| `set-buffer` | `setb` | Set the contents of a buffer | `-a` (append), `-w` (overwrite buffer index), `-b` (buffer name), `-n` (new buffer name), `-t` (target client), `data` |
| `show-buffer` | `showb` | Show the contents of a buffer | `-b` (buffer name) |

## Key Binding and Environment

| Command | Alias | Description | Options |
|---------|-------|-------------|---------|
| `bind-key` | `bind` | Bind a key to a command | `-n` (no prefix key), `-r` (key may repeat), `-T` (key table), `-N` (note/comment), `key`, `command [arguments]` |
| `command-prompt` | | Open the command prompt | `-1` (single line), `-b` (exit after command runs), `-F` (create format prompt), `-k` (immediate key input), `-i` (insert mode), `-N` (no prompt), `-I` (inputs), `-p` (prompts), `-t` (target client), `-T` (type) |
| `confirm-before` | `confirm` | Ask for confirmation before running a command | `-b` (delete buffer after command runs), `-y` (default yes), `-c` (confirm key), `-p` (prompt), `-t` (target client), `command` |
| `display-message` | `display` | Display a message | `-a` (all clients), `-I` (identify terminal), `-l` (redirect to status line), `-N` (without client name prefix), `-p` (stdout), `-v` (verbose), `-c` (target client), `-d` (delay), `-F` (format), `-t` (target pane), `[message]` |
| `if-shell` | `if` | Run a command if a shell command succeeds | `-b` (run in background), `-F` (use formatter for shell-command), `-t` (target pane), `shell-command`, `command [command]` |
| `list-keys` | `lsk` | List key bindings | `-1` (include key labels), `-a` (print key aliases), `-N` (include notes), `-P` (prefix string), `-T` (key table), `[key]` |
| `run-shell` | `run` | Execute a command without creating a window | `-b` (run in background), `-C` (clean env), `-c` (start directory), `-d` (delay), `-t` (target pane), `[shell-command]` |
| `send-keys` | `send` | Send key input to a window | `-F` (run input through formatter), `-H` (hex mode), `-K` (as key lookup), `-l` (literal), `-M` (mouse event), `-R` (reset terminal state before input), `-X` (execute command using copy-mode key tables), `-c` (target client), `-N` (repeat count), `-t` (target pane), `key ...` |
| `send-prefix` | | Send the prefix key to a window | `-2` (secondary prefix), `-t` (target pane) |
| `set-environment` | `setenv` | Set an environment variable | `-F` (run value through formatter), `-h` (for current host), `-g` (global), `-r` (remove), `-u` (update processes), `-t` (target session), `name [value]` |
| `set-hook` | | Set a hook to run when an event occurs | `-a` (append to existing), `-g` (global), `-p` (for current pane), `-R` (run hook immediately), `-u` (until next invoked), `-w` (for current window), `-t` (target pane), `hook [command]` |
| `set-option` | `set` | Set a session option | `-a` (append), `-F` (run value through formatter), `-g` (global), `-o` (avoid session inheritance), `-p` (for current pane), `-q` (quiet), `-s` (for server), `-u` (unset), `-U` (unset globally), `-w` (for current window), `-t` (target pane), `option [value]` |
| `set-window-option` | `setw` | Set a window option | `-a` (append), `-F` (run value through formatter), `-g` (global), `-o` (avoid session inheritance), `-q` (quiet), `-u` (unset), `-t` (target window), `option [value]` |
| `show-environment` | `showenv` | Show environment variables | `-h` (for current host), `-g` (global), `-s` (for server), `-t` (target session), `[name]` |
| `show-hooks` | | Show the current hooks | `-g` (global), `-p` (for current pane), `-w` (for current window), `-t` (target pane) |
| `show-options` | `show` | Show session options | `-A` (includes inherited values), `-g` (global), `-H` (includes hooks), `-p` (for current pane), `-q` (quiet), `-s` (server), `-v` (only values), `-w` (for current window), `-t` (target pane), `[option]` |
| `show-window-options` | `showw` | Show window options | `-g` (global), `-v` (only values), `-t` (target window), `[option]` |
| `unbind-key` | `unbind` | Unbind a key | `-a` (remove all bound keys), `-n` (no prefix key), `-q` (quiet), `-T` (key table), `key` |

## Other Commands

| Command | Alias | Description | Options |
|---------|-------|-------------|---------|
| `clear-prompt-history` | `clearphist` | Clear prompt history | `-T` (type) |
| `clock-mode` | | Enter clock mode | `-t` (target pane) |
| `customize-mode` | | Enter customize mode | `-N` (no selection), `-Z` (zoomed), `-F` (format), `-f` (filter), `-t` (target pane) |
| `display-menu` | `menu` | Display a menu | `-M` (monitor for mouse release), `-O` (no close on mouse release), `-b` (border lines style), `-c` (target client), `-C` (starting choice number), `-H` (selected style), `-s` (style), `-S` (border style), `-t` (target pane), `-T` (title), `-x` (position), `-y` (position), `name key command ...` |
| `display-popup` | `popup` | Display a popup | `-B` (no close with ESC), `-C` (close after command finishes), `-E` (close with any key), `-b` (border lines style), `-c` (target client), `-d` (start directory), `-e` (environment), `-h` (height), `-s` (style), `-S` (border style), `-t` (target pane), `-T` (title), `-w` (width), `-x` (position), `-y` (position), `[shell-command]` |
| `server-access` | | Show or set server access | `-a` (allow), `-d` (deny), `-l` (list), `-r` (reset), `-w` (warn), `-t` (target pane), `[user]` |
| `show-prompt-history` | `showphist` | Show prompt history | `-T` (type) |
| `wait-for` | `wait` | Wait for an event | `-L` (lock), `-S` (set), `-U` (unlock), `channel` |

## Common Target Options

| Option | Description |
|--------|-------------|
| `-t target-client` | Specify which client to target |
| `-t target-session` | Specify which session to target |
| `-t target-window` | Specify which window to target |
| `-t target-pane` | Specify which pane to target |