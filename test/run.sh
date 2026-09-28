#!/usr/bin/env bash
# Check Kame syntax highlight groups with headless Neovim.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$root/test/fixture.km"
assertions="$root/test/assertions.lua"

run() {
  nvim --headless -u NONE -i NONE -n \
    --cmd "set runtimepath^=$root" \
    --cmd 'syntax on' \
    "$@" \
    -c 'set filetype=kame' \
    -c "luafile $assertions" \
    -c 'qa!' \
    "$fixture"
}

echo 'default highlighting:'
run
echo 'g:kame_no_shell_syntax = 1:'
run --cmd 'let g:kame_no_shell_syntax = 1'
echo 'Makefile.km detection:'
nvim --headless -u NONE -i NONE -n \
  --cmd "set runtimepath^=$root" \
  --cmd 'filetype on' \
  -c "edit $root/test/Makefile.km" \
  -c 'lua if vim.bo.filetype ~= "kame" then io.stderr:write("expected filetype kame, got " .. vim.bo.filetype .. "\n") vim.cmd("cquit 1") end' \
  -c 'qa!'
echo 'kame syntax: ok'
