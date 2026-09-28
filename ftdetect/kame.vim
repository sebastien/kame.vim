" Detect Kame build scripts. Kame's discovery names (Makefile.km, Makefile.kmk,
" make.km, make.kmk) also match Vim's built-in Makefile detection, so override
" it explicitly with :set (not :setfiletype).
au BufRead,BufNewFile *.km,*.kmk set filetype=kame
