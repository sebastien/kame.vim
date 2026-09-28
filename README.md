# kame.vim

Vim filetype detection, syntax highlighting, formatting, and parse diagnostics
for the Kame build system.

## Installation

### Vim package (no plugin manager)

Clone the repository into Vim's package directory:

```sh
git clone https://github.com/sebastien/kame.vim.git \
  ~/.vim/pack/plugins/start/kame.vim
```

Vim will load the plugin automatically on startup. For Neovim, use its site
directory instead:

```sh
git clone https://github.com/sebastien/kame.vim.git \
  ~/.local/share/nvim/site/pack/plugins/start/kame.vim
```

### vim-plug

Add this to your vim-plug configuration, then run `:PlugInstall`:

```vim
Plug 'sebastien/kame.vim'
```

Files ending in `.km` (the default) and `.kmk` are detected as Kame.

## Usage

Commands:

- `:KameFormat` saves the current file and formats it in place with
  `kame do fmt -i`.
- `:KameLint` saves the current file and parses it with
  `kame do parse --lang script`. Parse errors are listed in the quickfix window.

Set `g:kame_command` to the executable path if Kame is not on `PATH`:

```vim
let g:kame_command = '/path/to/kame'
```

Linting currently checks Kame script syntax; it does not perform build-graph,
recipe, or style analysis.

## Highlighting

Rule recipes are shell scripts, so each rule body is highlighted with Vim's
shell syntax (`syntax/sh.vim`): variables, quoting, substitutions, control
flow, and here-documents all get shell colors. Kame string-template
expansions are highlighted on top of the shell text, including inside shell
quoting, command substitution, and here-documents, because Kame expands them
before the shell runs:

- `@(expression)` evaluations and `@{reference}` resolutions.
- Input selectors `@<`, `@<*`, `@<#`, `@<N`, `@<A..B`, output selectors `@>`,
  `@>*`, `@>#`, `@>N`, and argument selectors `@_`, `@*`, `@#`, `@N`.
- `{(expression)}` interpolation in expression strings.

Set `g:kame_no_shell_syntax = 1` before the syntax loads to keep rule bodies
plain. The embedded shell syntax picks its dialect from the same globals as
`syntax/sh.vim`:

```vim
let g:is_bash = 1
```

Highlight groups and their default links:

| Group | Default link | Highlights |
| --- | --- | --- |
| `kameComment` | `Comment` | `#` and `//` comments |
| `kameDirective` | `Include` | `include` |
| `kameIncludePath` | `Directory` | path after `include` |
| `kameRuleKind` | `Keyword` | `task`, `service` |
| `kameRuleSeparator` | `Operator` | the `:` in a rule header |
| `kameTargetName` | `Function` | logical target names |
| `kamePath` | `Directory` | `./`, `../`, and `/` paths |
| `kameCapture` | `Type` | `{...}` target and pattern groups |
| `kameCaptureName` | `Identifier` | capture names |
| `kameGlob` | `SpecialChar` | `*`, `**`, `?`, `[...]` in captures |
| `kameSymbol` | `Constant` | `:symbol` |
| `kameBoolean` | `Boolean` | `:true`, `:false`, `:nil` |
| `kameNumber` | `Number` | numbers |
| `kameName` | `Identifier` | names |
| `kameRecordKey` | `Identifier` | record keys such as `name:` |
| `kameSpecialForm` | `Statement` | `def`, `let`, `eval`, `?` |
| `kameOperator` | `Operator` | `\|` |
| `kameDelimiter` | `Delimiter` | `(` and `[` delimiters |
| `kameString` | `String` | quoted strings |
| `kameInterpolation` | `Special` | `{(...)}` interpolation |
| `kameTemplateExpression` | `Special` | `@(...)` expansions |
| `kameTemplateReference` | `PreProc` | `@{...}` references |
| `kameSelectorInput` | `Special` | `@<...` selectors |
| `kameSelectorOutput` | `PreProc` | `@>...` selectors |
| `kameSelectorArgument` | `Identifier` | `@_`, `@*`, `@#`, `@N` selectors |
| `kameEscape` | `SpecialChar` | `\@`, `\\`, `\{`, `\}` escapes |
| `kameDefinitionName` | `Define` | definition names |
| `kameDefinitionOperator` | `Operator` | the `=` in a definition |
| `kameFunctionName` | `Function` | function definition name |
| `kameFunctionParameter` | `Identifier` | function parameters |

Override any of them with `:hi! link` or `:hi`, for example:

```vim
hi! link kameTargetName Identifier
```

## Testing

`test/run.sh` loads `test/fixture.km` in headless Neovim and asserts the
highlight group at representative positions, both with and without
`g:kame_no_shell_syntax`. It also checks that `test/Makefile.km` is detected
as Kame despite Vim's built-in Makefile detection. It requires Neovim on
`PATH`:

```sh
./test/run.sh
```

`test/showcase.km` exercises every `kame*` group. Render it to the terminal
with true-color ANSI taken from Neovim's own highlighting, followed by a
legend showing each group in its own style. Your nvim config is used by
default (so you see your colorscheme); the local checkout is prepended to
`runtimepath`:

```sh
./test/preview.sh [file] [--no-shell] [--clean]
```


