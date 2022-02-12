
function! ritmus#version()
    return '0.0.3'
endfunction

let s:data = {}

function! s:data.init() dict
    let self.filepath = expand("%:p")
    let self.filename = expand("%:p:t:r")
    let self.parent_dir = expand("%:p:h")
    let self.parentname = expand("%:p:h:t")
    let self.pparentdir = expand("%:p:h:h")
    let self.win_name = self.filename
    let self.ses_name = self.parentname
    let self.prog = "python3"
    let self.module_run = "cd \"".self.pparentdir."\" & ".self.prog." -m %s"
    let self.script_run = self.prog." %s"
    let self.make_rule = ""
    let self.run_as_make = "make ".self.make_rule
    let self.new_session_cmd = printf(
                \ "sh -c 'urxvt -cd \"%s\" -e tmux new-session -AD -s%s -n%s &'",
                \ self.parent_dir,self.ses_name,self.win_name)
    let self.new_window_cmd = printf(
                \ "tmux new-window -a -c \"%s\" -t%s -n%s",
                \ self.parent_dir,self.ses_name,self.win_name)
    let self.session_attached_query = printf(
                \ "tmux ls -F\"#S #{session_attached}\"|awk -e'/%s/{print $2}'",
                \ self.ses_name)
    let self.window_active_query = printf(
                \ "tmux lsw -F\"#W #{window_active}\" -t%s|awk -e'/%s/{print $2}'",
                \ self.ses_name,self.win_name)
    let self.attach_session_cmd = printf(
                \ "sh -c 'urxvt -cd \"%s\" -e tmux attach -t%s:%s -d &'",
                \ self.parent_dir,self.ses_name,self.win_name)
    let self.command_string = self.format_run_cmd()
endfunction

function! s:data.has_pyinit() dict
    return filereadable(self.parent_dir."/__init__.py")
endfunction

function! s:data.has_pymain() dict
    return filereadable(self.parent_dir."/__main__.py")
endfunction

function! s:data.has_makefile() dict
    return filereadable(self.parent_dir."/Makefile")
endfunction

function! s:data.get_session_list() dict
    return systemlist("tmux list-sessions -F#S 2>/dev/null")
endfunction

function! s:data.get_window_list() dict
    return systemlist(printf(
                \ "tmux list-windows -F#W -t=%s 2>/dev/null",self.ses_name))
endfunction

function! s:data.session_exists() dict
    echom "looking for session ".self.ses_name
    for l:ses in self.get_session_list()
        if l:ses == self.ses_name
            return 1
        endif
    endfor
    return 0
endfunction

function! s:data.new_session() dict
    echom "new session with:"
    echom self.new_session_cmd
    call system(self.new_session_cmd)
endfunction

function! s:data.window_exists() dict
    echom "looking for window ".self.win_name
    for l:win in self.get_window_list()
        if l:win =~ self.win_name
            echom "window found"
            return 1
        endif
    endfor
    echom "window found"
    return 0
endfunction

function! s:data.new_window() dict
    echom "new window with command:"
    echom self.new_window_cmd
    call system(self.new_window_cmd)
endfunction

function! s:data.session_attached() dict
    echom "querying with:"
    echom self.session_attached_query
    return system(self.session_attached_query)
endfunction

function! s:data.attach_session() dict
    echom "attaching with:"
    echom self.attach_session_cmd
    call system(self.attach_session_cmd)
endfunction

function! s:data.window_active() dict
    echom "is window active?"
    echom self.window_active_query
    return system(self.window_active_query)
endfunction

function! s:data.activate_window() dict
    let l:cmd = printf("tmux select-window -t%s:%s",self.ses_name,self.win_name)
    echom l:cmd
    call system(l:cmd)
endfunction

function! s:data.ensure_session() dict
    if !self.session_exists()
        echom "making session"
        call self.new_session()
    else
        echom "session found"
        if !self.session_attached()
            echom "attaching to session"
            call self.attach_session()
        endif
        if !self.window_exists()
            echom "creating window"
            call self.new_window()
        endif
        if !self.window_active()
            echom "activating window"
            call self.activate_window()
        endif
    endif
endfunction

function! s:data.format_run_cmd() dict
    let l:arg = self.filepath
    let l:run = self.script_run
    if self.has_pyinit()
        let l:arg = self.parent_dir
        if !self.has_pymain()
            let l:arg = self.pparentdir
            let l:run = self.module_run
        endif
    endif
    return printf("tmux send-keys -t%s:%s %s Enter",
                \ self.ses_name,self.win_name,
                \ substitute(printf(l:run,l:arg)," "," Space ","g"))
endfunction

function! s:data.send_command() dict
    call system(self.command_string)
endfunction

function! ritmus#ritmus()
    call s:data.init()
    call s:data.ensure_session()
    call s:data.send_command()
endfunction

