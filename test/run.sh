#!/usr/bin/env bash
# Check Kame syntax highlight groups with headless Neovim.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
km_fixture="$root/test/fixture.km"
kmk_fixture="$root/test/fixture.kmk"
kash_fixture="$root/test/fixture.kash"

run_kmk() {
  nvim --headless -u NONE -i NONE -n \
    --cmd "set runtimepath^=$root" \
    --cmd 'syntax on' \
    "$@" \
    -c 'set filetype=kame' \
    -c "luafile $root/test/assertions_kmk.lua" \
    -c 'qa!' \
    "$kmk_fixture"
}

echo 'value program (fixture.km):'
nvim --headless -u NONE -i NONE -n \
  --cmd "set runtimepath^=$root" \
  --cmd 'syntax on' \
  -c 'set filetype=kame' \
  -c "luafile $root/test/assertions_km.lua" \
  -c 'qa!' \
  "$km_fixture"

echo 'rule program, default highlighting (Kash recipes):'
run_kmk
echo "g:kame_recipe_lang = 'shell':"
run_kmk --cmd "let g:kame_recipe_lang = 'shell'"
echo "g:kame_recipe_lang = 'none':"
run_kmk --cmd "let g:kame_recipe_lang = 'none'"
echo 'g:kame_no_shell_syntax = 1:'
run_kmk --cmd 'let g:kame_no_shell_syntax = 1'

echo 'Kash source highlighting:'
nvim --headless -u NONE -i NONE -n \
  --cmd "set runtimepath^=$root" \
  --cmd 'syntax on' \
  -c "luafile $root/test/assertions_kash.lua" \
  -c 'qa!' \
  "$kash_fixture"

detect() {
  local label="$1" file="$2" expected_lang="$3"
  nvim --headless -u NONE -i NONE -n \
    --cmd "set runtimepath^=$root" \
    --cmd 'set loadplugins' \
    --cmd 'runtime! plugin/**/*.vim' \
    --cmd 'filetype on' \
    -c "edit $file" \
    -c "lua if vim.bo.filetype ~= 'kame' then io.stderr:write('$label: expected filetype kame, got ' .. vim.bo.filetype .. '\n') vim.cmd('cquit 1') end" \
    -c "lua if '$expected_lang' ~= '' and vim.b.kame_lang ~= '$expected_lang' then io.stderr:write('$label: expected kame_lang $expected_lang, got ' .. tostring(vim.b.kame_lang) .. '\n') vim.cmd('cquit 1') end" \
    -c 'qa!'
}

echo 'filetype detection:'
# .kmk (canonical and Makefile.kmk) is a rule program; .ksh is Kash; .km/.kmd
# are value programs; Kamefile is a rule program.
detect 'fixture.kmk' "$kmk_fixture" 'rule'
detect 'Makefile.kmk' "$root/test/Makefile.kmk" 'rule'
detect 'fixture.kash' "$kash_fixture" 'kash'
ksh_fixture="$(mktemp --suffix=.ksh)"
cp "$kash_fixture" "$ksh_fixture"
detect 'fixture.ksh' "$ksh_fixture" 'kash'
rm -f "$ksh_fixture"
kmd_fixture="$(mktemp --suffix=.kmd)"
cp "$km_fixture" "$kmd_fixture"
detect 'fixture.kmd' "$kmd_fixture" 'expr'
rm -f "$kmd_fixture"
kamefile="$(mktemp -d)/Kamefile"
cp "$kmk_fixture" "$kamefile"
detect 'Kamefile' "$kamefile" 'rule'
rm -rf "$(dirname "$kamefile")"

echo 'kame syntax: ok'
