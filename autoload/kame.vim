" Resolve a Kame source path to its layer. This is the single place that maps a
" suffix or file name to the layer recorded in b:kame_lang:
"   .km/.kame/Kamefile  expr      Kame program: definitions, declarations, rules
"   .kash/.ksh          kash      Kash program: the top level is an action block
"   .kmt                template  Kame document template
" Unknown paths fall back to 'expr' so `set filetype=kame` still works.
function! kame#lang_of(file) abort
  let l:ext = tolower(fnamemodify(a:file, ':e'))
  if l:ext ==# 'kash' || l:ext ==# 'ksh'
    return 'kash'
  elseif l:ext ==# 'kmt'
    return 'template'
  endif
  return 'expr'
endfunction
