#!/usr/bin/env bash
# Check Kame syntax highlight groups with headless Neovim.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
km_fixture="$root/test/fixture.km"
kmk_fixture="$root/test/fixture.kmk"
kash_fixture="$root/test/fixture.kash"
ktmpl_fixture="$root/test/fixture.paml.ktmpl"

# Optional extra runtimepath for host syntaxes used by .ktmpl tests. Set
# KAME_HOST_RUNTIME to the directory holding the PAML (or other host) syntax/
# tree; when unset, only the template overlay is checked and host checks are
# skipped. Example:
#   KAME_HOST_RUNTIME=~/Workspace/Perso/dotnvim/src/vim ./test/run.sh
host_runtime="${KAME_HOST_RUNTIME:-}"

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

echo 'document template highlighting (.paml.ktmpl):'
# Enable filetype before plugins load, as a normal session does (init runs
# before plugin/), so kame's BufReadPost correction is registered after the
# host's ftdetect. Enabling filetype after load is the reverse of real order.
nvim --headless -u NONE -i NONE -n \
  --cmd "set runtimepath^=$root" \
  ${host_runtime:+--cmd "set runtimepath^=$host_runtime"} \
  --cmd 'filetype on' \
  --cmd 'syntax on' \
  --cmd 'set loadplugins' \
  --cmd 'runtime! plugin/**/*.vim' \
  -c "luafile $root/test/assertions_ktmpl.lua" \
  -c 'qa!' \
  "$ktmpl_fixture"

detect() {
  local label="$1" file="$2" expected_lang="$3" expected_host="${4:-}"
  nvim --headless -u NONE -i NONE -n \
    --cmd "set runtimepath^=$root" \
    --cmd 'filetype on' \
    --cmd 'set loadplugins' \
    --cmd 'runtime! plugin/**/*.vim' \
    -c "edit $file" \
    -c "lua if vim.bo.filetype ~= 'kame' then io.stderr:write('$label: expected filetype kame, got ' .. vim.bo.filetype .. '\n') vim.cmd('cquit 1') end" \
    -c "lua if '$expected_lang' ~= '' and vim.b.kame_lang ~= '$expected_lang' then io.stderr:write('$label: expected kame_lang $expected_lang, got ' .. tostring(vim.b.kame_lang) .. '\n') vim.cmd('cquit 1') end" \
    -c "lua if '$expected_host' ~= '' and vim.b.kame_host ~= '$expected_host' then io.stderr:write('$label: expected kame_host $expected_host, got ' .. tostring(vim.b.kame_host) .. '\n') vim.cmd('cquit 1') end" \
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
# .HOST.ktmpl is the template layer, and the segment before .ktmpl names the host.
detect 'fixture.paml.ktmpl' "$ktmpl_fixture" 'template' 'paml'

echo 'kame syntax: ok'
