let s:save_cpo = &cpo
set cpo&vim

if exists("g:loaded_ritmus") | finish | endif

let g:loaded_ritmus = 1

com! Ritmus call ritmus#ritmus()
com! RitmusCancel call ritmus#sendcancel()

let &cpo = s:save_cpo

unlet s:save_cpo
