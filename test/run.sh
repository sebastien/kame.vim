#!/usr/bin/env bash
# Check Kame syntax highlight groups with headless Neovim.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
km_fixture="$root/test/fixture.km"
kash_fixture="$root/test/fixture.kash"
kmt_fixture="$root/test/fixture.kmt"
shell_fixture="$root/test/fixture.shell.km"

run_assertions() {
  local label="$1" fixture="$2" assertions="$3"
  shift 3
  echo "$label:"
  nvim --headless -u NONE -i NONE -n \
    --cmd "set runtimepath^=$root" \
    --cmd 'filetype on' \
    --cmd 'syntax on' \
    --cmd 'set loadplugins' \
    --cmd 'runtime! plugin/**/*.vim' \
    "$@" \
    -c 'syntax sync fromstart' \
    -c "luafile $assertions" \
    -c 'qa!' \
    "$fixture"
}

check_group() {
  local label="$1" file="$2" line="$3" col="$4" expected="$5"
  shift 5
  nvim --headless -u NONE -i NONE -n \
    --cmd "set runtimepath^=$root" \
    --cmd 'filetype on' \
    --cmd 'syntax on' \
    --cmd 'set loadplugins' \
    --cmd 'runtime! plugin/**/*.vim' \
    "$@" \
    -c "edit $file" \
    -c 'syntax sync fromstart' \
    -c "lua local group = vim.fn.synIDattr(vim.fn.synID($line, $col, 1), 'name'); if group ~= '$expected' then io.stderr:write('$label: expected $expected, got ' .. (group ~= '' and group or '<none>') .. '\\n') vim.cmd('cquit 1') end" \
    -c 'qa!'
}

run_assertions 'Kame program (fixture.km)' "$km_fixture" "$root/test/assertions_km.lua"
run_assertions 'Kash action block (fixture.kash)' "$kash_fixture" "$root/test/assertions_kash.lua"
run_assertions 'document template (fixture.kmt)' "$kmt_fixture" "$root/test/assertions_kmt.lua"
run_assertions "foreign-shell recipes (g:kame_recipe_lang = 'shell')" "$shell_fixture" "$root/test/assertions_shell.lua" --cmd "let g:kame_recipe_lang = 'shell'"
run_assertions "foreign-shell recipes (SHELL = \"sh\")" "$shell_fixture" "$root/test/assertions_shell.lua"

echo 'recipe modes:'
check_group 'SHELL = "sh" recipe' "$shell_fixture" 4 2 'shStatement'
check_group 'g:kame_recipe_lang = kash' "$km_fixture" 31 4 'kameKashCommand' --cmd "let g:kame_recipe_lang = 'kash'"
check_group 'g:kame_recipe_lang = none' "$km_fixture" 31 4 'kameRecipe' --cmd "let g:kame_recipe_lang = 'none'"

detect() {
  local label="$1" file="$2" expected_lang="$3"
  nvim --headless -u NONE -i NONE -n \
    --cmd "set runtimepath^=$root" \
    --cmd 'filetype on' \
    --cmd 'set loadplugins' \
    --cmd 'runtime! plugin/**/*.vim' \
    -c "edit $file" \
    -c "lua if vim.bo.filetype ~= 'kame' then io.stderr:write('$label: expected filetype kame, got ' .. vim.bo.filetype .. '\n') vim.cmd('cquit 1') end" \
    -c "lua if '$expected_lang' ~= '' and vim.b.kame_lang ~= '$expected_lang' then io.stderr:write('$label: expected kame_lang $expected_lang, got ' .. tostring(vim.b.kame_lang) .. '\n') vim.cmd('cquit 1') end" \
    -c 'qa!'
}

echo 'filetype detection:'
detect 'fixture.km' "$km_fixture" 'expr'
detect 'fixture.kash' "$kash_fixture" 'kash'
detect 'fixture.kmt' "$kmt_fixture" 'template'

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp "$km_fixture" "$tmp/Kamefile"
cp "$km_fixture" "$tmp/Makefile.km"
cp "$km_fixture" "$tmp/make.km"
cp "$km_fixture" "$tmp/fixture.kame"
cp "$kash_fixture" "$tmp/fixture.ksh"
cp "$kmt_fixture" "$tmp/fixture.kmt"
detect 'Kamefile' "$tmp/Kamefile" 'expr'
detect 'Makefile.km' "$tmp/Makefile.km" 'expr'
detect 'make.km' "$tmp/make.km" 'expr'
detect 'fixture.kame' "$tmp/fixture.kame" 'expr'
detect 'fixture.ksh' "$tmp/fixture.ksh" 'kash'
detect 'fixture.kmt' "$tmp/fixture.kmt" 'template'

echo 'kame syntax: ok'
