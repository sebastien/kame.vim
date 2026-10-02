#!/usr/bin/env bash
# Render a Kame file to the terminal with Neovim highlight colors,
# then list every kame* group in its own style.
#
# By default your nvim config is used (colorscheme, etc.); the local
# kame.vim checkout is prepended to 'runtimepath' so you preview these
# sources, not an installed copy.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
preview="$root/test/preview.lua"
default_file="$root/test/showcase.km"

file="$default_file"
clean=0
no_shell=0
recipe_lang=""
for arg in "$@"; do
  case "$arg" in
    --clean) clean=1 ;;
    --no-shell) no_shell=1 ;;
    --recipe-lang=*) recipe_lang="${arg#--recipe-lang=}" ;;
    -h|--help)
      echo "Usage: test/preview.sh [file] [--no-shell] [--recipe-lang=kash|shell|none] [--clean]" >&2
      echo "  default: use your nvim config + local kame.vim" >&2
      echo "  --no-shell: set g:kame_no_shell_syntax=1 (recipe-lang=none)" >&2
      echo "  --recipe-lang: highlight recipe bodies as kash, shell, or none" >&2
      echo "  --clean: -u NONE isolated defaults (CI)" >&2
      exit 0
      ;;
    *) file="$arg" ;;
  esac
done

base=(--headless -i NONE -n)
if [[ $clean == 1 ]]; then
  base+=(-u NONE)
fi
extra=()
if [[ $no_shell == 1 ]]; then
  extra+=(--cmd 'let g:kame_no_shell_syntax = 1')
fi
if [[ -n $recipe_lang ]]; then
  extra+=(--cmd "let g:kame_recipe_lang = '$recipe_lang'")
fi

if [[ ! -f "$file" ]]; then
  echo "test/preview.sh: file not found: $file" >&2
  exit 1
fi

nvim "${base[@]}" \
  --cmd "set runtimepath^=$root" \
  --cmd 'set loadplugins' \
  --cmd 'runtime! plugin/**/*.vim' \
  --cmd 'set termguicolors' \
  --cmd 'syntax on' \
  "${extra[@]}" \
  -c 'filetype on' \
  -c "luafile $preview" \
  -c 'qa!' \
  "$file"
