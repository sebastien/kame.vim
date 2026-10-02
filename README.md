# kame.vim

Vim filetype detection, syntax highlighting, formatting, and parse diagnostics
for the [Kame](https://github.com/sebastien/kame) build system.

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

## Source layers

The suffix names the independently usable outer language. Detection sets
`filetype=kame` for every suffix and records the layer in `b:kame_lang`.

| Suffix | Layer | Contents |
| --- | --- | --- |
| `.km` | `expr` | value program: comments, blank lines, includes, lazy definitions, and one or more top-level expressions |
| `.kmd` | `expr` | the same value-program grammar (multiple expressions) |
| `.kmk` | `rule` | the value layer plus rule headers, target templates, and recipes |
| `Kamefile` | `rule` | the same rule-program grammar, selected by file name |
| `.kash` | `kash` | the Kash command and process language |
| `.ksh` | `kash` | exactly the same grammar as `.kash` |

The layer identifiers (`expr`, `rule`, `kash`) match the value recorded in
`b:kame_lang`. The three layers compose: value expressions appear in rule
inputs and definitions; `$(COMMAND)` is a value atom whose contents are a Kash
process; and Kash embeds value expressions through `@(EXPRESSION)` and value
references through `$REFERENCE` / `${REFERENCE}`. Rule headers and recipes are
only highlighted in a rule program (`.kmk`, `Kamefile`); a value program
(`.km`/`.kmd`) is expression-only.

Rule sources `Makefile.kmk` and `make.kmk` also match Vim's built-in Makefile
detection, and `.ksh` matches its shell detection, so the plugin registers the
suffixes with Neovim's `vim.filetype` matcher at a higher priority and also
ships an `ftdetect` override for Vim.

## Usage

Commands:

- `:KameFormat` saves the current file and formats it in place with
  `kame do fmt -i`.
- `:KameLint` saves the current file and parses it with
  `kame do parse`. The parser language follows the suffix: `--lang script` for
  `.km`/`.kmd`/`.kmk` and `--lang kash` for `.kash`/`.ksh`. Parse errors are
  listed in the quickfix window.

Set `g:kame_command` to the executable path if Kame is not on `PATH`:

```vim
let g:kame_command = '/path/to/kame'
```

Linting checks source syntax; it does not perform build-graph, recipe, or style
analysis.

## Recipe highlighting

A rule-program recipe body (`.kmk`, `Kamefile`) is highlighted with the Kash
layer by default, since Kash is composed into rule programs, including command
arguments, pipelines, redirections, and `$REFERENCE` / `@(EXPRESSION)` /
`$(COMMAND)` expansions, with Kame string-template expansions (`@(expression)`,
selectors, and `{(...)}` interpolation) layered on top.

Set `g:kame_recipe_lang` before the syntax loads to choose the recipe language:

```vim
let g:kame_recipe_lang = 'shell'   " highlight recipes with syntax/sh.vim
let g:kame_recipe_lang = 'none'    " keep recipes plain
```

`shell` embeds Vim's shell syntax and picks its dialect from the same globals
as `syntax/sh.vim`:

```vim
let g:is_bash = 1
```

`g:kame_no_shell_syntax = 1` is the legacy spelling of `'none'` and is still
honored when `g:kame_recipe_lang` is unset.

## Highlighting

Highlight groups and their default links:

| Group | Default link | Highlights |
| --- | --- | --- |
| `kameComment` | `Comment` | `#` and `//` comments (Kash: `#` only) |
| `kameDirective` | `Include` | `include` |
| `kameIncludePath` | `Directory` | path after `include` |
| `kameRuleKind` | `Keyword` | `task`, `service` |
| `kameRuleSeparator` | `Operator` | the `:` in a rule header |
| `kameTargetName` | `Function` | logical target names |
| `kamePath` | `Directory` | `./`, `../`, and `/` paths |
| `kameCapture` | `Type` | `{...}` target and pattern groups |
| `kameCaptureName` | `Identifier` | capture names |
| `kameCapturePattern` | `SpecialChar` | `{name:*}` pattern part |
| `kameSymbol` | `Constant` | `:symbol` |
| `kameBoolean` | `Boolean` | `:true`, `:false`, `:nil` |
| `kameNumber` | `Number` | numbers |
| `kameName` | `Identifier` | names |
| `kameReference` | `Identifier` | `project.name`, `files.1..4`, `config.{host,port}` |
| `kamePlaceholder` | `Special` | `_`, `__`, `_0` placeholder atoms |
| `kameRecordKey` | `Identifier` | record keys such as `name:` |
| `kameSpecialForm` | `Statement` | `def`, `let`, `eval`, `if`, `and`, `or`, `match`, `with`, `?` |
| `kameOperator` | `Operator` | `\|` |
| `kameComparisonOperator` | `Operator` | `=`, `==`, `!=`, `<`, `>`, `<=`, `>=` |
| `kameDelimiter` | `Delimiter` | `(` and `[` delimiters |
| `kameString` | `String` | quoted and verbatim strings |
| `kameInterpolation` | `Special` | `{(...)}` interpolation |
| `kameInterpolationDelimiter` | `Special` | `{(` and `)}` |
| `kameTemplateExpression` | `Special` | `@(...)` expansions |
| `kameTemplateDelimiter` | `Special` | `@(` and `)` |
| `kameSelectorInput` | `Special` | `@<...` selectors |
| `kameSelectorOutput` | `PreProc` | `@>...` selectors |
| `kameSelectorArgument` | `Identifier` | `@_`, `@*`, `@#`, `@N` selectors |
| `kameEscape` | `SpecialChar` | `\@`, `\\`, `\{`, `\}` escapes |
| `kameCommandSubstitution` | `Special` | `$(COMMAND)` substitution |
| `kameCommandSubstitutionDelimiter` | `Special` | `$(` and `)` |
| `kameRecipeDirective` | `PreProc` | recipe directive lines `@if`, `@else`, `@end`, ... |
| `kameTemplateDirective` | `PreProc` | document-template directive lines `@if`, `@for`, `@end`, ... |
| `kameKashKeyword` | `Conditional` | `if`, `elif`, `else`, `match`, `case` |
| `kameKashCommand` | `Function` | executable words |
| `kameKashOption` | `Identifier` | `-c`, `--watch`, `-O2` |
| `kameKashSetupKey` | `Keyword` | `:cwd`, `:timeout`, `:NODE_ENV` |
| `kameKashPipeline` | `Operator` | `\|` |
| `kameKashRedirection` | `Operator` | `<`, `>`, `>>` |
| `kameKashAcceptance` | `Operator` | `?` |
| `kameKashRecovery` | `Operator` | `??` |
| `kameKashAsync` | `Operator` | `&` |
| `kameKashSeparator` | `Delimiter` | `;` |
| `kameKashMeta` | `PreProc` | reserved `@NAME`, `@tmpl(...)` |
| `kameKashReference` | `Identifier` | `$ref`, `${ref}`, `$project.name` |
| `kameKashString` | `String` | Kash `"..."` words with substitutions |
| `kameDefinitionName` | `Define` | definition names |
| `kameDefinitionOperator` | `Operator` | the `=` in a definition |
| `kameFunctionName` | `Function` | function definition name |
| `kameFunctionParameter` | `Identifier` | function parameters |
| `kameVariable` | `Constant` | UPPER_CASE variable references |
| `kameFunctionCall` | `Function` | lowercase and kebab-case function references |
| `kameStdlibFunction` | `Special` | standard-library operation names (including build effects) |

Override any of them with `:hi! link` or `:hi`, for example:

```vim
hi! link kameTargetName Identifier
```

## Testing

`test/run.sh` loads `test/fixture.km` (value program) and `test/fixture.kmk`
(rule program) in headless Neovim and asserts the highlight group at
representative positions, exercising each recipe mode (`kash`, `shell`, `none`,
and the legacy `g:kame_no_shell_syntax`). It also checks `test/fixture.kash`
and verifies filetype detection for `Makefile.kmk`, `Kamefile`, `.kash`, `.ksh`,
and `.kmd`. It requires Neovim on `PATH`:

```sh
./test/run.sh
```

`test/showcase.*` exercise every `kame*` group across the source types. Render
them to the terminal with true-color ANSI taken from Neovim's own highlighting,
followed by a legend showing each group in its own style. Your nvim config is
used by default (so you see your colorscheme); the local checkout is prepended
to `runtimepath`:

```sh
./test/preview.sh                              # every type in turn
./test/preview.sh --type=rule                  # one type
./test/preview.sh test/showcase.kash           # one file
./test/preview.sh --recipe-lang=shell --clean  # shell recipes, isolated
```

With no argument every type is shown, each under a `== type ==` header:

| Type | Fixture | Layer |
| --- | --- | --- |
| `expr` | `test/showcase.km` | `expr` value program |
| `script` | `test/showcase.script.kmk` | `rule` layer, script composition (definitions and expressions) |
| `rule` | `test/showcase.kmk` | `rule` layer, headers, captures, and recipes |
| `template` | `test/showcase.paml.ktmpl` | `template` layer over a PAML host |
| `kash` | `test/showcase.kash` | `kash` process language |

`script` and `rule` are both `.kmk` scripts (the `rule` layer); they differ in
what they emphasize. `--type` selects one, and a file argument previews one
file. The template section needs the host's syntax on `'runtimepath'` (PAML
here); without it, the host text renders uncolored and the Kame overlay still
shows. `--recipe-lang`, `--no-shell`, and `--clean` behave as before.
