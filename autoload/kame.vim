" Resolve a Kame source path to its layer. This is the single place that maps a
" suffix or file name to the layer recorded in b:kame_lang:
"   .km/.kmd       expr     value program: comments, includes, definitions, expressions
"   .kmk           rule     value layer plus rule headers, target templates, recipes
"   Kamefile       rule     the same rule program, selected by file name
"   .kash/.ksh     kash     the Kash command and process language
"   .HOST.ktmpl    template Kame document template layered on a host language
" Unknown paths fall back to 'expr' so `set filetype=kame` still works.
function! kame#lang_of(file) abort
  if kame#is_ktmpl(a:file)
    return 'template'
  endif
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

" A .ktmpl path is a Kame document template, optionally naming a host language
" in the segment before .ktmpl: page.paml.ktmpl has host 'paml'. The host is
" used to embed that language's syntax under the Kame template layer.
function! kame#is_ktmpl(file) abort
  return tolower(fnamemodify(a:file, ':e')) ==# 'ktmpl'
endfunction

" Host dialect named by a .ktmpl path: the last suffix before .ktmpl, lowercased.
" Returns '' when the file is not .ktmpl or names no host (page.ktmpl).
function! kame#host_of(file) abort
  if !kame#is_ktmpl(a:file)
    return ''
  endif
  let l:stem = fnamemodify(a:file, ':r')
  let l:host = tolower(fnamemodify(l:stem, ':e'))
  return l:host
endfunction

" Map a .ktmpl host dialect to the syntax file to embed. b:kame_host_syntax (set
" by detection) and g:kame_host_syntax win and are returned verbatim. Otherwise
" a short table folds common host names onto Vim's syntax names; the first
" candidate whose syntax file exists on 'runtimepath' wins. An unknown dialect
" falls back to itself, so syntax/<dialect>.vim is still tried. Returns '' when
" there is no host or nothing resolves.
function! kame#host_syntax(file) abort
  if exists('b:kame_host_syntax') && !empty(b:kame_host_syntax)
    return b:kame_host_syntax
  endif
  let l:host = kame#host_of(a:file)
  if empty(l:host)
    return ''
  endif
  let l:candidates = get(s:host_syntax, l:host, [l:host])
  for l:candidate in l:candidates
    if !empty(globpath(&runtimepath, 'syntax/' . l:candidate . '.vim'))
      return l:candidate
    endif
  endfor
  return ''
endfunction

" Common host dialects -> Vim syntax file names, most specific first. Names kept
" lowercase; a host not listed resolves to itself. Only names whose spelling
" differs from the dialect need an entry (js -> javascript, sh -> sh, ...).
let s:host_syntax = {
      \ 'paml':   ['paml', 'html'],
      \ 'haml':   ['haml'],
      \ 'slim':   ['slim'],
      \ 'md':     ['markdown'],
      \ 'js':     ['javascript'],
      \ 'mjs':    ['javascript'],
      \ 'cjs':    ['javascript'],
      \ 'ts':     ['typescript'],
      \ 'tsx':    ['typescriptreact', 'typescript'],
      \ 'jsx':    ['javascriptreact', 'javascript'],
      \ 'py':     ['python'],
      \ 'rb':     ['ruby'],
      \ 'rs':     ['rust'],
      \ 'go':     ['go'],
      \ 'sh':     ['sh'],
      \ 'bash':   ['sh'],
      \ 'zsh':    ['zsh'],
      \ 'yml':    ['yaml'],
      \ 'toml':   ['toml'],
      \ 'html':   ['html'],
      \ 'htm':    ['html'],
      \ 'xml':    ['xml'],
      \ 'svg':    ['svg'],
      \ 'css':    ['css'],
      \ 'scss':   ['scss'],
      \ 'sass':   ['sass'],
      \ 'less':   ['less'],
      \ 'java':   ['java'],
      \ 'kt':     ['kotlin'],
      \ 'swift':  ['swift'],
      \ 'php':    ['php'],
      \ 'sql':    ['sql'],
      \ 'lua':    ['lua'],
      \ 'hs':     ['haskell'],
      \ 'clj':    ['clojure'],
      \ 'scm':    ['scheme'],
      \ 'el':     ['lisp'],
      \ 'tex':    ['tex'],
      \ 'r':      ['r'],
      \ 'pl':     ['perl'],
      \ 'asm':    ['asm'],
      \ 'json':   ['json'],
      \ 'vue':    ['vue'],
      \ }
