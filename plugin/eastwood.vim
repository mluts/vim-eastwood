" eastwood.vim - Clojure linting and code cleanup plugin
" Maintainer:   Venantius <venantius at gmail dot com>
" Version:      0.2

if exists('g:syntastic_extra_filetypes')
    call add(g:syntastic_extra_filetypes, 'clojure')
else
    let g:syntastic_extra_filetypes = ['clojure']
endif

function! s:fireplaceConnected() abort
  return exists('*fireplace#client') && has_key(fireplace#client(), 'connection')
endfunc

function! g:EastwoodRequire() abort
    if !s:fireplaceConnected()
      return 0
    endif

    try
        call fireplace#session_eval("(require 'eastwood.lint)")
        return 1
    catch /Clojure:|Fireplace:/
        return 0
    endtry
endfunction

function! g:EastwoodLintNS(...) abort
    if !g:EastwoodRequire()
      return []
    endif

    let opts = a:0 ? a:1 : {}
    let add_linters = exists('opts.add_linters') ? opts.add_linters : []

    let cmd = "(->> (eastwood.lint/lint { " .
            \     " :namespaces '[" . fireplace#ns() . "]" .
            \     " :add-linters [" . join(map(copy(add_linters), '":" . v:val'), " ") ."]" .
            \ " })" .
            \ " :warnings" .
            \ " (map (fn [e]" .
            \     "{:text (:msg e)" .
            \     " :lnum (:line e)"  .
            \     " :col (:column e)" .
            \     " :valid true"  .
            \     " :bufnr " . bufnr('%')  .
            \     " :type \"E\"})))"
    try
        return fireplace#query(cmd)
    catch /^Clojure:.*/
        return []
    endtry
endfunction
