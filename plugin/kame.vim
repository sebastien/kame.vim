" Kame editor commands.
if exists('g:loaded_kame_vim')
  finish
endif
let g:loaded_kame_vim = 1

function! s:RunKame(arguments) abort
  let l:command = shellescape(get(g:, 'kame_command', 'kame')) . ' ' . a:arguments
  return system(l:command)
endfunction

function! s:WriteSource() abort
  if empty(expand('%:p'))
    echoerr 'Kame: save this buffer to a file first'
    return ''
  endif
  update
  return expand('%:p')
endfunction

function! s:Format() abort
  let l:file = s:WriteSource()
  if empty(l:file)
    return
  endif

  let l:view = winsaveview()
  let l:output = s:RunKame('do fmt -i ' . shellescape(l:file))
  if v:shell_error
    echoerr 'Kame format failed: ' . substitute(l:output, '\n$', '', '')
    return
  endif

  " Reload the atomic formatter output while preserving the cursor and viewport.
  silent edit!
  call winrestview(l:view)
  echo 'Kame: formatted ' . expand('%:t')
endfunction

function! s:Lint() abort
  let l:file = s:WriteSource()
  if empty(l:file)
    return
  endif

  let l:output = s:RunKame('--color never do parse --lang script ' . shellescape(l:file))
  if v:shell_error
    let l:lines = split(l:output, "\n")
    call setqflist([], 'r', {'lines': l:lines, 'efm': '%f:%l:%c: %m'})
    if !empty(getqflist())
      copen
      echo 'Kame: parse errors (see quickfix)'
    else
      echoerr 'Kame lint failed: ' . substitute(l:output, '\n$', '', '')
    endif
    return
  endif

  call setqflist([], 'r')
  echo 'Kame: no parse errors'
endfunction

command! KameFormat call <SID>Format()
command! KameLint call <SID>Lint()
