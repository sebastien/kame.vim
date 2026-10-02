" Kame editor commands.
if exists('g:loaded_kame_vim')
  finish
endif
let g:loaded_kame_vim = 1

" Register the Kame suffixes with Neovim's Lua filetype matcher. Its built-in
" table matches Kame discovery names as Makefiles (Makefile.kmk) and .ksh as
" shell, and vim.filetype.match runs before ftdetect/*.vim, so an ftdetect rule
" alone is not enough: without this, opening a .kmk build file sets
" filetype=kame and then re-detects it as make. The callback records the source
" layer in b:kame_lang for the syntax file, using kame#lang_of so the mapping
" lives in one place. Vim falls back to ftdetect.
if has('nvim')
  lua << EOF
local function kame(path)
  return 'kame', function(buf)
    vim.b[buf].kame_lang = vim.fn['kame#lang_of'](path)
    -- A .ktmpl names its host dialect; record it and the syntax to embed so
    -- syntax/kame.vim can layer the template over that host.
    if vim.fn['kame#is_ktmpl'](path) == 1 then
      vim.b[buf].kame_host = vim.fn['kame#host_of'](path)
      vim.b[buf].kame_host_syntax = vim.fn['kame#host_syntax'](path)
    end
  end
end
require('vim.filetype').add({
  pattern = {
    -- Higher priority than Neovim's built-in `^[mM]akefile` (priority 0) so a
    -- Makefile.kmk is Kame, not make.
    ['.*%.km'] = { kame, { priority = 100 } },
    ['.*%.kmd'] = { kame, { priority = 100 } },
    ['.*%.kmk'] = { kame, { priority = 100 } },
    ['.*%.kash'] = { kame, { priority = 100 } },
    ['.*%.ksh'] = { kame, { priority = 100 } },
    ['.*%.ktmpl'] = { kame, { priority = 100 } },
  },
  -- Rule program by file name as well as by suffix.
  filename = {
    Kamefile = kame,
  },
})
EOF
endif

" A host plugin may claim a .HOST.ktmpl before Kame: PAML detects `*.paml*`,
" which matches page.paml.ktmpl. Host detection runs on BufReadPost, and this
" plugin loads after filetype detection in a normal session, so its BufReadPost
" runs after the host's and wins. syntax/kame.vim embeds the host itself, so
" only the outer filetype changes. b:current_syntax may hold the host, so clear
" it for syntax/kame.vim. Host fields are filled in here too, since host order
" can leave them unset.
augroup kame_ktmpl
  autocmd!
  autocmd BufReadPost *.ktmpl if kame#is_ktmpl(expand('%:p')) && &filetype !=# 'kame' | unlet! b:current_syntax | let b:kame_lang = 'template' | let b:kame_host = kame#host_of(expand('%:p')) | let b:kame_host_syntax = kame#host_syntax(expand('%:p')) | set filetype=kame | endif
augroup END

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

" The source layer selects the parser language. expr/rule programs share the
" script parser; kash programs use the Kash parser. kame#lang_of is the single
" mapping from suffix or file name to layer.
function! s:ParseLang(file) abort
  return kame#lang_of(a:file) ==# 'kash' ? 'kash' : 'script'
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

  let l:output = s:RunKame('--color never do parse --lang ' . s:ParseLang(l:file) . ' ' . shellescape(l:file))
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
