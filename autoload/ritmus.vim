" Ritmus, a vim plugin for running things in tmux windows.
"   Copyright (C) 2022 Shams Kitz
"
"   This program is free software: you can redistribute it and/or modify
"   it under the terms of the GNU General Public License as published by
"   the Free Software Foundation, either version 3 of the License, or
"   (at your option) any later version.
"
"   This program is distributed in the hope that it will be useful,
"   but WITHOUT ANY WARRANTY; without even the implied warranty of
"   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"   GNU General Public License for more details.
"
"   You should have received a copy of the GNU General Public License
"   along with this program.  If not, see <https://www.gnu.org/licenses/>.
"   -------------------------------------------------------------------

function! ritmus#version()
    return '0.0.5'
endfunction

let s:data = {}

function! s:data.init() dict
    "------------------------------------------------------------------
    " xxx-TODO more logic here
    " make configurable overrides for:
    " default program name,
    " caring about existence of makefile or
    " other make-like systems,
    " the make rule,
    " specific session name,
    " window name based on something other than file name
    " etcetera
    "------------------------------------------------------------------

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

function! s:data.get_session_list() dict
    let l:session_list_query = "tmux list-sessions -F#S 2>/dev/null"
    echom l:session_list_query
    let l:tlist = systemlist(l:session_list_query)
    echom l:tlist
    return l:tlist
endfunction

function! s:data.get_window_list() dict
    let l:window_list_query_fmt = "tmux list-windows -F#W -t=%s 2>/dev/null"
    let l:window_list_query = printf(l:window_list_query_fmt,self.ses_name)
    echom l:window_list_query
    let l:tlist = systemlist(l:window_list_query)
    echom l:tlist
    return l:tlist
endfunction

function! s:data.session_exists() dict
    echom "looking for session ".self.ses_name
    for l:ses in self.get_session_list()
        if l:ses == self.ses_name
            echom "session found"
            return 1
        endif
    endfor
    echom "session not found"
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
    echom "querying session attachment with:"
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
        echom "reusing session ".self.ses_name
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
    echom "looking for Makefile in ".self.parent_dir
    let l:makefile = self.parent_dir."/Makefile"
    let l:do_a_make = 0
    let l:send_fmt = "tmux send-keys -t%s:%s %s Enter"
    if filereadable(l:makefile)
        echom "has a Makefile"
        return printf(l:send_fmt,self.ses_name,self.win_name,self.run_as_make)
    else
        echom "no Makefile found, guessing based off file type"
        echom &filetype
    endif
    if &filetype == 'python'
        echom "filetype is python"
        let l:arg = self.filepath
        let l:run = self.script_run
        if filereadable(self.parent_dir."/__init__.py")
            let l:arg = self.parent_dir
            if !filereadable(self.parent_dir."/__main__.py")
                let l:arg = self.pparentdir
                let l:run = self.module_run
            endif
        endif
        let l:runcmd = substitute(printf(l:run,l:arg)," "," Space ","g")
        echom "RUNCMD: ".l:runcmd
        return printf(l:send_fmt,self.ses_name,self.win_name,l:runcmd)
    endif
    " so maybe like what if it's an executable file run by ./itself ?
    " do what now
endfunction

function! s:data.send_command() dict
    call system(self.command_string)
endfunction

function! ritmus#ritmus()
    call s:data.init()
    call s:data.ensure_session()
    call s:data.send_command()
endfunction

