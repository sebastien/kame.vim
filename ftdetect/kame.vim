" Detect Kame sources for Vim, and for Neovim when plugin/kame.vim has not
" registered the suffixes with vim.filetype. Kame discovery names (Kamefile,
" Makefile.km, make.km) also match Vim's built-in Makefile detection, and
" .ksh matches its shell detection, so override explicitly with :set (not
" :setfiletype). Do not clobber a layer already recorded by the Neovim filetype
" registration. kame#lang_of names the layer from the suffix or file name.
au BufRead,BufNewFile *.km,*.kame,*.kmt,Kamefile if !exists('b:kame_lang') | let b:kame_lang = kame#lang_of(expand('%:p')) | endif | set filetype=kame
au BufRead,BufNewFile *.kash,*.ksh if !exists('b:kame_lang') | let b:kame_lang = 'kash' | endif | set filetype=kame
