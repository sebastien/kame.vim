" Detect Kame sources for Vim, and for Neovim when plugin/kame.vim has not
" registered the suffixes with vim.filetype. Kame's discovery names
" (Makefile.kmk, make.kmk) also match Vim's built-in Makefile detection, and
" .ksh matches its shell detection, so override explicitly with :set (not
" :setfiletype). Do not clobber a layer already recorded by the Neovim filetype
" registration. kame#lang_of names the layer from the suffix or file name.
au BufRead,BufNewFile *.km,*.kmd,*.kmk,Kamefile,*.kash,*.ksh if !exists('b:kame_lang') | let b:kame_lang = kame#lang_of(expand('%:p')) | endif | set filetype=kame

" Kame document templates: .HOST.ktmpl (page.paml.ktmpl). Record the host dialect
" and its syntax so syntax/kame.vim can embed it under the template layer. A
" host plugin may claim the path first (PAML detects `*.paml*`); plugin/kame.vim
" converts that filetype back to kame on its FileType event.
au BufRead,BufNewFile *.ktmpl if !exists('b:kame_lang') | let b:kame_lang = kame#lang_of(expand('%:p')) | let b:kame_host = kame#host_of(expand('%:p')) | let b:kame_host_syntax = kame#host_syntax(expand('%:p')) | endif | set filetype=kame
