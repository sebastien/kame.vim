" Resolve a Kame source path to its layer. This is the single place that maps a
" suffix or file name to the layer recorded in b:kame_lang:
"   .km/.kmd   expr  value program: comments, includes, definitions, expressions
"   .kmk       rule  value layer plus rule headers, target templates, recipes
"   Kamefile   rule  the same rule program, selected by file name
"   .kash/.ksh kash  the Kash command and process language
" Unknown paths fall back to 'expr' so `set filetype=kame` still works.
function! kame#lang_of(file) abort
  let l:ext = tolower(fnamemodify(a:file, ':e'))
  if l:ext ==# 'kmk'
    return 'rule'
  elseif l:ext ==# 'kash' || l:ext ==# 'ksh'
    return 'kash'
  endif
  if fnamemodify(a:file, ':t') ==# 'Kamefile'
    return 'rule'
  endif
  return 'expr'
endfunction
