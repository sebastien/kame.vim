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

One source language covers values, declarations, actions, and templates. The
suffix selects the context; detection sets `filetype=kame` for every suffix and
records the layer in `b:kame_lang`.

| Suffix | Layer | Contents |
| --- | --- | --- |
| `.km` | `expr` | Kame program: lazy definitions, imports, includes, rules, tasks, services, and declaration-time control flow |
| `.kame` | `expr` | the same Kame program grammar |
| `Kamefile` | `expr` | the same program grammar, selected by file name |
| `.kash` | `kash` | Kash program: the top level is an action block |
| `.ksh` | `kash` | exactly the same grammar as `.kash` |
| `.kmt` | `template` | document template: host text with `@` directives and `@{...}` interpolation |

The layer identifiers (`expr`, `kash`, `template`) match the value recorded in
`b:kame_lang`. The contexts share one expression grammar: value and declaration
contexts use expressions, Kash action blocks use command syntax, and document
templates stay literal except for directives and interpolation. `$(COMMAND)`,
`$?(COMMAND)`, and `$&(COMMAND)` contain an action block in every layer.

Kame discovery names (`Makefile.km`, `make.km`) also match Vim's built-in
Makefile detection, and `.ksh` matches its shell detection, so the plugin
registers the suffixes with Neovim's `vim.filetype` matcher at a higher priority
and also ships an `ftdetect` override for Vim.

## Usage

Commands:

- `:KameFormat` saves the current file and formats it in place with
  `kame do fmt -i`.
- `:KameLint` saves the current file and parses it with
  `kame do parse`. The parser language follows the suffix: `--lang km` for
  `.km`/`.kame`/`Kamefile`, `--lang kash` for `.kash`/`.ksh`, and
  `--lang template` for `.kmt`. Parse errors are listed in the quickfix window.

Set `g:kame_command` to the executable path if Kame is not on `PATH`:

```vim
let g:kame_command = '/path/to/kame'
```

Linting checks source syntax; it does not perform build-graph, recipe, or style
analysis.

## Recipe highlighting

A rule, task, or service body is a **Kash action block** by default. In that
mode the same Kash command and statement highlighting is used everywhere, so
`$inputs.0`, `(EXPRESSION)`, control statements, pipelines, and redirections are
visible inside recipe bodies.

A build-wide `SHELL = "bash"` or per-rule `; {shell: "bash"}` selects a foreign
shell. Kame renders that body as a document template, so only `@{EXPR}`,
`@@`, and `@if`/`@for`/... directives are Kame; the rest belongs to the shell.
Set `g:kame_recipe_lang` before the syntax loads to choose how indented bodies
are highlighted:

```vim
let g:kame_recipe_lang = 'kash'   " default: Kash action blocks
let g:kame_recipe_lang = 'shell'  " foreign-shell bodies with syntax/sh.vim
let g:kame_recipe_lang = 'none'   " keep indented bodies plain
```

`shell` embeds Vim's shell syntax and picks its dialect from the same globals
as `syntax/sh.vim`:

```vim
let g:is_bash = 1
```

When `g:kame_recipe_lang` is unset, a buffer-level `SHELL = "..."` or
`SHELL = kash` selects the matching recipe layer for the file:

```kame
SHELL = "bash"

task build ; {shell: "sh"}
	@if release
	cc -O2 @{inputs.0} -o @{outputs.0}
	@else
	cc -g @{inputs.0} -o @{outputs.0}
	@end
```

Per-rule metadata is not inspected by the highlighter; set `g:kame_recipe_lang`
when one file mixes interpreters. `g:kame_no_shell_syntax = 1` is the legacy
spelling of `'none'` and is still honored when `g:kame_recipe_lang` is unset.

In a `.kmt` template, directives are recognized as whole lines (plain style)
and as complete host-comment directives (`<!-- @if x -->`, `# @for ...`,
`// @end`, ...). `@raw` bodies stay literal through `@end`.

## Highlighting

Highlight groups and their default links:

| Group | Default link | Highlights |
| --- | --- | --- |
| `kameComment` | `Comment` | `#` comments (never `//`, and never in templates) |
| `kameDirective` | `Include` | `include`, `include?`, `import`, `from`, `export`, `as` |
| `kameRuleKeyword` | `Keyword` | `rule`, `task`, `service` |
| `kameRuleModifier` | `Keyword` | `always`, `cached` |
| `kameRuleSeparator` | `Operator` | the `:` and `;` in a rule header |
| `kameRuleOrderOnly` | `Operator` | the `\|` before order-only inputs |
| `kameRuleGroupSeparator` | `Delimiter` | `,` input sequence groups |
| `kameRuleBodyOperator` | `Operator` | `=` expression bodies in a rule header |
| `kameTargetName` | `Function` | task and service target names |
| `kamePath` | `Directory` | `./`, `../`, `/`, `~/`, and `@{...}/` paths |
| `kameCapture` | `Type` | `{...}` pattern and target groups |
| `kameCaptureName` | `Identifier` | capture names |
| `kameCapturePattern` | `SpecialChar` | `{name:*}`, `{path:**}`, `{*}` |
| `kameCaptureRegex` | `SpecialChar` | `{name:~REGEX}` |
| `kameCaptureDefault` | `String` | `{region=us-east}` default text |
| `kameSymbol` | `Constant` | `:symbol`, `:+name`, `:-name` |
| `kameBoolean` | `Boolean` | `true`, `false`, `nil` |
| `kameNumber` | `Number` | numbers, including a literal leading `-` |
| `kameName` | `Identifier` | other names |
| `kameVariable` | `Constant` | `UPPER_CASE` environment-style names |
| `kameFunctionCall` | `Function` | lowercase and kebab-case names |
| `kameStdlibFunction` | `Special` | standard-library operations |
| `kameReference` | `Identifier` | `project.name`, `files.0`, `x/uv`, `env/NAME`, `module/dir` |
| `kamePlaceholder` | `Special` | `_`, `__`, `___`, `_N` placeholder atoms |
| `kameRecordKey` | `Identifier` | record keys such as `name:` |
| `kameKeyword` | `Statement` | `def`, `let`, `set`, `if`, `then`, `match`, `for`, `while`, `return`, `yield`, `exit`, `defer`, `with`, `stream`, ... |
| `kameLogicalOperator` | `Operator` | `and`, `or` |
| `kameOperator` | `Operator` | `+`, `-`, `*`, `/`, `%` |
| `kameComparisonOperator` | `Operator` | `==`, `!=`, `<`, `>`, `<=`, `>=` |
| `kameLambdaOperator` | `Operator` | `=>` |
| `kameSpreadOperator` | `Operator` | `...` |
| `kameValuePipe` | `Operator` | `\|>` |
| `kameFallbackOperator` | `Operator` | `??` |
| `kameDelimiter` | `Delimiter` | `(` and `[` delimiters |
| `kameString` | `String` | `"..."`, `'...'`, and `"""..."""` strings |
| `kameTemplateInterpolation` | `Special` | `@{EXPR}` interpolation |
| `kameTemplateDelimiter` | `Special` | `@{` and `}` |
| `kameTemplateDirective` | `PreProc` | template directives `@if`, `@for`, `@end`, ... |
| `kameTemplateDirectiveLabel` | `Keyword` | the label after `@end` |
| `kameTemplateTrim` | `SpecialChar` | template whitespace trim markers |
| `kameEscape` | `SpecialChar` | `@@` and backslash escapes |
| `kameCommandSubstitution` | `Special` | `$(COMMAND)`, `$?(COMMAND)`, `$&(COMMAND)` |
| `kameCommandSubstitutionDelimiter` | `Special` | the capture delimiters |
| `kameKashBuiltin` | `Function` | `cd`, `wait`, `kill`, `out!`, `err!`, ... |
| `kameKashCommand` | `Function` | executable words |
| `kameKashOption` | `Identifier` | `-c`, `--watch`, `-O2` |
| `kameKashSetupKey` | `Keyword` | `cwd:`, `timeout:`, `env:`, `accept-exit:`, `NODE_ENV:` |
| `kameKashReference` | `Identifier` | `$ref`, `${ref}`, `$project.name`, `$...list` |
| `kameKashPipeline` | `Operator` | `\|` |
| `kameKashSequential` | `Operator` | `&&`, `\|\|` |
| `kameKashRedirection` | `Operator` | `<`, `>`, `>>`, `2>`, `2>&1`, `>@` |
| `kameKashChannel` | `Special` | `>&out`, `>&err`, `>&name`, `<&name`, `&name` |
| `kameKashAcceptance` | `Operator` | `?` |
| `kameKashAsync` | `Operator` | `&` |
| `kameKashMux` | `Operator` | `\|(merge)`, `\|(frame)`, `\|(tee)`, ... |
| `kameKashMuxKey` | `Keyword` | `:buffer`, `:items`, `:order`, `:append`, ... |
| `kameKashStreamName` | `Special` | the name in `stream NAME` |
| `kameDefinitionName` | `Define` | definition, `let`, `set`, and loop binder names |
| `kameDefinitionOperator` | `Operator` | `=`, `?=`, `+=` definitions and assignments |
| `kameFunctionName` | `Function` | function definition name |
| `kameFunctionParameter` | `Identifier` | function parameters |

Override any of them with `:hi! link` or `:hi`, for example:

```vim
hi! link kameTargetName Identifier
```

## Testing

`test/run.sh` loads `test/fixture.km` (program, rules, and recipes),
`test/fixture.kash` (action block), `test/fixture.kmt` (document template), and
`test/fixture.shell.km` (foreign-shell recipe) in headless Neovim and asserts
the highlight group at representative positions. It also verifies filetype
detection for `Kamefile`, `Makefile.km`, `make.km`, `.km`, `.kame`, `.kash`,
`.ksh`, and `.kmt`. It requires Neovim on `PATH`:

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
./test/preview.sh --type=kash                  # one type
./test/preview.sh test/showcase.kmt            # one file
./test/preview.sh --recipe-lang=shell --clean  # shell recipes, isolated
```

With no argument every type is shown, each under a `== type ==` header:

| Type | Fixture | Layer |
| --- | --- | --- |
| `expr` | `test/showcase.km` | `expr` program |
| `rule` | `test/showcase.rules.km` | `expr` program focused on rules and recipes |
| `template` | `test/showcase.kmt` | `template` document |
| `kash` | `test/showcase.kash` | `kash` action block |

`--type` selects one, and a file argument previews one file.
`--recipe-lang`, `--no-shell`, and `--clean` behave as before.
