
function! ritmus#version()
    return '0.0.1'
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
    let self.new_session_cmd = printf("sh -c 'urxvt -cd \"%s\" -e tmux new-session -s%s -n%s &'",self.parent_dir,self.ses_name,self.win_name)
    let self.new_window_cmd = printf("sh -c 'urxvt -cd \"%s\" -e tmux new-window -t%s -n%s &'",self.parent_dir,self.ses_name,self.win_name)
    let self.session_attached_query = printf("tmux ls -F\"#S #{session_attached}\" | awk -e'/%s/{print $2}'",self.ses_name)
    let self.window_active_query = printf("tmux lsw -F\"#W #{window_active}\" -t%s | awk -e'/%s/{print $2}'",self.ses_name,self.win_name)
    let self.attach_session_cmd = printf("sh -c 'urxvt -cd \"%s\" -e tmux attach -t%s:%s -d &'",self.parent_dir,self.ses_name,self.win_name)

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

function! s:data.session_list() dict
    return systemlist("tmux list-sessions -F#S 2>/dev/null")
endfunction

function! s:data.window_list() dict
    return systemlist(printf("tmux list-windows -F#W -t=%s 2>/dev/null",self.ses_name))
endfunction

function! s:data.session_attached() dict
    echom "querying"
    echom self.session_attached_query
    return system(self.session_attached_query)
endfunction

function! s:data.attach_session() dict
    call system(self.attach_session_cmd)
endfunction

function! s:data.new_session() dict
    call system(self.new_session_cmd)
endfunction

function! s:data.new_window() dict
    call system(self.new_window_cmd)
endfunction

function! s:data.window_active() dict
    return system(self.window_active_query)
endfunction

function! s:data.form_run() dict
    let l:arg = self.filepath
    let l:run = self.script_run
    if self.has_pyinit()
        let l:arg = self.parent_dir
        if !self.has_pymain()
            let l:arg = self.pparentdir
            let l:run = self.module_run
        endif
    endif
    return printf(
                \ "tmux send-keys -t%s:%s %s Enter",
                \ self.ses_name,
                \ self.win_name,
                \ substitute(printf(l:run,l:arg)," "," Space ","g")
                \ )
endfunction

function! s:data.session_exists() dict
    echom "looking for session ".self.ses_name
    for l:ses in self.session_list()
        if l:ses == self.ses_name
            return 1
        endif
    endfor
    return 0
endfunction

function! s:data.window_exists() dict
    echom "looking for window ".self.win_name
    for l:win in self.window_list()
        if l:win == self.win_name
            return 1
        endif
    endfor
    return 0
endfunction

function! s:data.select_window() dict
    return printf("tmux select-window -t%s:%s",self.ses_name,self.win_name)
endfunction

function! s:data.activate_window() dict
    call system(self.select_window())
endfunction

function! s:data.send_command() dict
    call system(self.form_run())
endfunction

function! s:data.ensure_session() dict
    if !self.session_exists()
        echom "no session"
        call self.new_session()
    elseif !self.window_exists()
        echom "no window"
        call self.new_window()
    elseif !self.session_attached()
        echom "not attached"
        call self.attach_session()
    elseif !self.window_active()
        echom "not active"
        call self.activate_window()
    endif
endfunction

function! ritmus#pythislinux() abort
    call s:data.init()
    echom "INIT OK"
    echom s:data.session_attached()
    call s:data.ensure_session()
    echom "SESS OK"
    call s:data.send_command()
    echom "SENT OK"
    "{{{2
    "let l:pyname = s:data.prog
    "let l:filepath = expand("%:p")
    "let l:filename = expand("%:p:t:r")
    "let l:parent_dir = expand("%:p:h")
    "let l:parentname = expand("%:p:h:t")
    "let l:pparentdir = expand("%:p:h:h")
    "let l:as_script = s:data.prog . " %s"
    "let l:as_module = "cd \"".l:pparentdir."\" & ".s:data.prog." -m %s"
    "let l:run = l:as_script
    "let l:arg = l:filepath
    "if filereadable(l:parent_dir."/__init__.py")
    "    let l:arg = l:parent_dir
    "    if !filereadable(l:parent_dir."/__main__.py")
    "        let l:arg = l:pparentdir
    "        let l:run = l:as_module
    "    endif
    "endif
    "let l:cmd = printf(l:run,l:arg)
    ""}}}2
    "let l:session_exists = 0
    "let l:window_exists = 0
    "let l:tcmd = substitute(l:cmd," "," Space ","g")
    "let l:send_cmd = printf("tmux send-keys -t%s:%s %s Enter",l:parentname,l:filename,l:tcmd)
    "let l:session_list = systemlist("tmux list-sessions -F#S 2>/dev/null")
    "let l:make_session_cmd = printf("sh -c 'urxvt -cd \"%s\" -e tmux new-session -s%s -n%s &'",l:parent_dir,l:parentname,l:filename)
    "let l:make_window_cmd = printf("sh -c 'urxvt -cd \"%s\" -e tmux new-window -t%s -n%s &'",l:parent_dir,l:parentname,l:filename)
    "for l:sessname in l:session_list
    "    if l:sessname == l:parentname
    "        let l:session_exists = 1
    "        echom "found session"
    "        let l:window_list = systemlist(printf("tmux list-windows -F#W -t=%s 2>/dev/null",l:sessname))
    "        for l:window_name in l:window_list
    "            if l:window_name == l:filename
    "                let l:window_exists = 1
    "                echom "found window"
    "                break
    "            endif
    "        endfor
    "    endif
    "endfor
    "if l:session_exists == 0
    "    echom "making session with"
    "    echom l:make_session_cmd
    "    call system(l:make_session_cmd)
    "    echom "sending with"
    "    echom l:send_cmd
    "    call system(l:send_cmd)
    "else
    "    if l:window_exists == 0
    "        echom "making window with"
    "        echom l:make_window_cmd
    "        call system(l:make_window_cmd)
    "        echom "sending with"
    "        echom l:send_cmd
    "        call system(l:send_cmd)
    "    else
    "        echom "found both"
    "        let l:session_attached_query = printf("tmux ls -F\"#S #{session_attached}\"|awk -e'/%s/{print $2}'",l:parentname)
    "        let l:session_attached = system(l:session_attached_query)
    "        if l:session_attached == 0
    "            echom "attaching with"
    "            let l:attach_session_cmd = printf("sh -c 'urxvt -cd \"%s\" -e tmux attach -t%s:%s -d'",l:parent_dir,l:parentname,l:filename)
    "            echom l:attach_session_cmd
    "            call system(l:attach_session_cmd)
    "        endif
    "        echom "sending with"
    "        echom l:send_cmd
    "        call system(l:send_cmd)
    "    endif
    "endif
endfunction

function! ritmus#ritmus() abort
    if has('win32')
        call ritmus#pythisw32()
    else
        call ritmus#pythislinux()
    endif
endfunction


