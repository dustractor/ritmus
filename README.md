# ritmus

*(Run in tmux session)*

---

Provides currently one zero-argument command: ``:Ritmus``.

``:Ritmus`` looks at the the currently-edited file, looks for a tmux session with the same name as the folder it's in, creates the session as necessary, attaches (using urxvt) to an existing session if found, looks among the windows of the session for one having the same name as the file in the buffer, creates or activates the window if necessary, and lastly, sends a command to be executed in the window in the tmux session in the urxvt terminal **without mode-blocking vim**.

