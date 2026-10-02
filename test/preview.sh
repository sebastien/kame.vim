#!/usr/bin/env bash
# Render Kame syntax highlighting to the terminal with Neovim colors, then
# list every kame* group in its own style.
#
# With no argument, every source type is shown in turn: expr, script, rule,
# template, and kash. Pass a file to preview just that file. --type selects a
# single registered type.
#
# By default your nvim config is used (colorscheme, etc.); the local
# kame.vim checkout is prepended to 'runtimepath' so you preview these
# sources, not an installed copy.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
preview="$root/test/preview.lua"

# type -> fixture. Order here is the default run order. Names match the layer
# recorded in b:kame_lang, except that script (a .kmk script program focused on
# definitions) and rule (a .kmk rule program focused on headers and recipes)
# share the rule layer by design.
declare -A fixtures=(
  [expr]="$root/test/showcase.km"
  [script]="$root/test/showcase.script.kmk"
  [rule]="$root/test/showcase.kmk"
  [template]="$root/test/showcase.paml.ktmpl"
  [kash]="$root/test/showcase.kash"
)
order=(expr script rule template kash)

type=all
file=""
clean=0
no_shell=0
recipe_lang=""
for arg in "$@"; do
  case "$arg" in
    --clean) clean=1 ;;
    --no-shell) no_shell=1 ;;
    --recipe-lang=*) recipe_lang="${arg#--recipe-lang=}" ;;
    --type=*) type="${arg#--type=}" ;;
    -h|--help)
      cat >&2 <<EOF
Usage: test/preview.sh [FILE] [--type=TYPE] [--no-shell] [--recipe-lang=kash|shell|none] [--clean]
  no argument: show every type in turn ($(IFS=', '; echo "${order[*]}"))
  FILE:        preview one file
  --type:      restrict to one type: $(IFS=', '; echo "${order[*]}"), or all
  --no-shell:  set g:kame_no_shell_syntax=1 (recipe-lang=none)
  --recipe-lang: highlight recipe bodies as kash, shell, or none
  --clean:     -u NONE isolated defaults (CI)
EOF
      exit 0
      ;;
    --*) echo "test/preview.sh: unknown option: $arg" >&2; exit 2 ;;
    *) file="$arg" ;;
  esac
done

if [[ -n $file && $type != all ]]; then
  echo "test/preview.sh: FILE and --type are mutually exclusive" >&2
  exit 2
fi

if [[ -n $file ]]; then
  if [[ ! -f $file ]]; then
    echo "test/preview.sh: file not found: $file" >&2
    exit 1
  fi
  files=("$file")
  labels=("")   # single file: preview.lua prints its own File: line.
  single=1
else
  if [[ $type == all ]]; then
    files=()
    labels=()
    for t in "${order[@]}"; do
      files+=("${fixtures[$t]}")
      labels+=("$t")
    done
  else
    if [[ -z ${fixtures[$type]+x} ]]; then
      echo "test/preview.sh: unknown type: $type (expected: ${order[*]})" >&2
      exit 2
    fi
    files=("${fixtures[$type]}")
    labels=("$type")
  fi
  single=0
fi

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

# Render each section without the legend, then print the legend once at the end
# so a multi-type run does not repeat it five times. Section labels only apply
# to files that exist; a missing host syntax degrades to plain text.
for i in "${!files[@]}"; do
  f="${files[$i]}"
  label="${labels[$i]}"
  if [[ ! -f $f ]]; then
    echo "test/preview.sh: skipped missing fixture: $f" >&2
    continue
  fi

  nvim "${base[@]}" \
    --cmd "set runtimepath^=$root" \
    --cmd 'set termguicolors' \
    --cmd 'filetype on' \
    --cmd 'syntax on' \
    --cmd 'set loadplugins' \
    --cmd 'runtime! plugin/**/*.vim' \
    --cmd "let g:kame_preview_section = '$label'" \
    --cmd "let g:kame_preview_single = $single" \
    --cmd 'let g:kame_preview_legend = 0' \
    "${extra[@]}" \
    -c "luafile $preview" \
    -c 'qa!' \
    "$f"
  echo
done

# Legend once, from the rule fixture so rule/recipe groups are defined.
nvim "${base[@]}" \
  --cmd "set runtimepath^=$root" \
  --cmd 'set termguicolors' \
  --cmd 'filetype on' \
  --cmd 'syntax on' \
  --cmd 'set loadplugins' \
  --cmd 'runtime! plugin/**/*.vim' \
  --cmd 'let g:kame_preview_legend = 1' \
  --cmd 'let g:kame_preview_body = 0' \
  --cmd 'let g:kame_preview_single = 1' \
  "${extra[@]}" \
  -c "luafile $preview" \
  -c 'qa!' \
  "${fixtures[rule]}"
