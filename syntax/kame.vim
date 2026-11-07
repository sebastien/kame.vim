" Vim syntax file
" Language: Kame value programs (.km/.kmd), rule programs (.kmk), and Kash
"           process programs (.kash/.ksh)
" Maintainer: Sebastien Pierre

if exists('b:current_syntax')
  finish
endif

syn case match

" Standard-library operations (including the build-effect vocabulary). Names
" contain '?', '!', and '-' characters that are not keyword characters, so
" this is a match rather than a `syn keyword` item.
let s:stdlib = 'not\|bool\|str\|json\|parse-json\|fail!\|'
      \ . 'count\|get\|first\|nth\|list\|nop\|apply\|items\|set\|merge\|'
      \ . 'nil?\|bool?\|int?\|float?\|string?\|bytes?\|list?\|record?\|'
      \ . 'callable?\|resource?\|pattern?\|process?\|number?\|empty?\|'
      \ . 'has-key?\|success?\|blank?\|digest\|'
      \ . 'map\|flatmap\|filter\|filter-out\|in?\|reduce\|concat\|slice\|'
      \ . 'sorted\|unique\|'
      \ . 'join\|split\|strip\|line\|sub\|sub-token\|replace\|match?\|'
      \ . 'includes?\|starts?\|ends?\|uppercase\|lowercase\|template-cat\|'
      \ . 'text\|render\|pattern\|regex-match\|capture\|resub\|'
      \ . 'basename\|dirname\|splitext\|ext\|joinpath\|relpath\|abspath\|'
      \ . 'source-dir\|resource\|now\|monotonic\|parse-args\|read\|exists?\|'
      \ . 'stat\|lstat\|readlink\|wildcard\|files\|dirs\|write!\|publish!\|'
      \ . 'env\|sh!\|shell-template!\|tool\|kash\|'
      \ . 'out!\|err!\|yield!\|eq?\|ne?\|lt?\|gt?\|lte?\|gte?\|has?\|is'

" ---------------------------------------------------------------------------
" Source layer. Detection sets b:kame_lang; fall back to the suffix or file name
" through kame#lang_of so `set filetype=kame` still works.
"   expr  value program: comments, includes, definitions, expressions
"   rule  rule program (.kmk, Kamefile): the value layer plus headers, targets,
"         and recipes
"   kash  Kash process program (.kash, .ksh)
" ---------------------------------------------------------------------------
let s:lang = get(b:, 'kame_lang', '')
if empty(s:lang)
  let s:lang = kame#lang_of(expand('%:p'))
endif
let s:kash_top = s:lang ==# 'kash'
let s:rule = s:lang ==# 'rule'
let s:template = s:lang ==# 'template'

" ---------------------------------------------------------------------------
" Document template layer (.HOST.ktmpl). The host language is the outer layer;
" Kame directives and inline expansions are layered on top. Detection records
" b:kame_host and b:kame_host_syntax; fall back to kame#host_syntax so
" `set filetype=kame` and an explicit g:kame_host_syntax still work.
" ---------------------------------------------------------------------------
if s:template
  let s:host_syntax = get(b:, 'kame_host_syntax', '')
  if empty(s:host_syntax)
    let s:host_syntax = kame#host_syntax(expand('%:p'))
  endif
  if !empty(s:host_syntax)
    execute 'syn include @kameHost syntax/' . s:host_syntax . '.vim'
    unlet! b:current_syntax
    let s:hostContains = '@kameHost'
  else
    let s:hostContains = ''
  endif
endif

" ---------------------------------------------------------------------------
" Recipe language: hybrid (default), kash, kame, shell, or none.
"
" "hybrid" assumes a Kash-style rule body while still recognizing the template
" forms @{reference}, @(expression), selectors, and directives, so both
" `$x/uv` and `@{x/uv}` are visible in ordinary rules. Use "shell" to match
" Kame's external-shell runtime default exactly, or "kash" for strict direct
" Kash without template forms.
"
" g:kame_no_shell_syntax is the legacy spelling of "none". An unknown value
" falls back to hybrid. When no explicit global is configured, a buffer-level
" `SHELL = kash`, `SHELL = kame`, or other `SHELL = ...` chooses the recipe
" language for the file. Per-rule `[shell: ...]` metadata still requires
" g:kame_recipe_lang.
" ---------------------------------------------------------------------------
let s:recipe = get(g:, 'kame_recipe_lang', '')
let s:recipe_explicit = !empty(s:recipe) || get(g:, 'kame_no_shell_syntax', 0)
if empty(s:recipe)
  let s:recipe = get(g:, 'kame_no_shell_syntax', 0) ? 'none' : 'hybrid'
elseif s:recipe !=# 'kash' && s:recipe !=# 'shell' && s:recipe !=# 'kame'
      \ && s:recipe !=# 'hybrid' && s:recipe !=# 'none'
  let s:recipe = 'hybrid'
endif
if s:rule && !s:recipe_explicit
  for s:line in getline(1, '$')
    if s:line =~# '^\s*SHELL\s*=\s*kash\s*$'
      let s:recipe = 'kash'
      break
    elseif s:line =~# '^\s*SHELL\s*=\s*kame\s*$'
      let s:recipe = 'kame'
      break
    elseif s:line =~# '^\s*SHELL\s*=\s*\S'
      let s:recipe = 'shell'
      break
    endif
  endfor
  unlet! s:line
endif

" ---------------------------------------------------------------------------
" Embedded shell recipes. sh.vim reads g:is_bash, g:is_posix, g:is_kornshell,
" and g:is_dash to pick a dialect. External-shell recipes are document
" templates: Kame expansions and directives are layered over the shell text.
" Direct Kash recipes are not template-expanded, so @(...) and selectors only
" apply to expression strings and paths there, never to the recipe text.
" ---------------------------------------------------------------------------
if s:rule && s:recipe ==# 'shell'
  syn include @kameShell syntax/sh.vim
  unlet! b:current_syntax
  let s:templateContexts = 'kameRecipe,kameString,kamePath,sh.*'
elseif s:recipe ==# 'kash' || s:recipe ==# 'kame'
  let s:templateContexts = 'kameString,kamePath'
else
  let s:templateContexts = 'kameRecipe,kameString,kamePath'
endif

" ---------------------------------------------------------------------------
" Document template layer (.HOST.ktmpl). A template is host text plus Kame
" directive lines and inline expansions; the host syntax is embedded above.
" Document templates use the value/expression grammar inside @(...); they do
" not use the rule, recipe, or Kash layers, and $REF / ${REF} / $(COMMAND) are
" emitted literally (016-templates.md), so those forms are not defined here.
" ---------------------------------------------------------------------------
if s:template
  " Inline expansions.
  syn cluster kameValueGroup contains=kameExpression,kameList,kameString,kameNumber,kameBoolean,kameSymbol,kameVariable,kameName,kameFunctionCall,kameStdlibFunction,kameRecordKey,kamePath,kameCapture,kameSpecialForm,kameOperator,kameComparisonOperator,kameReference,kamePlaceholder,kameCommandSubstitution,kameTemplateReference,kameSelectorInput,kameSelectorOutput,kameSelectorArgument

  syn region kameExpression matchgroup=kameDelimiter start=/(/ end=/)/ contained contains=@kameValueGroup
  syn region kameList matchgroup=kameDelimiter start=/\[/ end=/\]/ contained contains=@kameValueGroup

  " Value atoms: only meaningful inside @(...), so every one is contained.
  syn match kameNumber /-\?\%([0-9A-Za-z_]\)\@<!0[xX][0-9A-Fa-f]\%(_\?[0-9A-Fa-f]\)*\>/ contained
  syn match kameNumber /-\?\%([0-9A-Za-z_]\)\@<!0[bB][01]\%(_\?[01]\)*\>/ contained
  syn match kameNumber /-\?\%([0-9A-Za-z_]\)\@<!0[oO][0-7]\%(_\?[0-7]\)*\>/ contained
  syn match kameNumber /-\?\%([0-9A-Za-z_]\)\@<!\d\%(_\?\d\)*\%(\.\d\%(_\?\d\)*\)\?\%([eE][+-]\?\d\%(_\?\d\)*\)\?\>/ contained
  syn match kameSymbol /:[A-Za-z_][A-Za-z0-9_-]*/ contained
  syn match kameBoolean /:\%(true\|false\|nil\)\>/ contained
  syn match kameVariable /\<[A-Z][A-Z0-9_]*\ze\%([^A-Za-z0-9_-]\|$\)/ contained
  syn match kameName /\<[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze\%([^A-Za-z0-9_-]\|$\)/ contained
  syn match kameFunctionCall /\<[a-z][A-Za-z0-9_-]*[?!]\?\ze\%([^A-Za-z0-9_-]\|$\)/ contained
  execute 'syn match kameStdlibFunction /\<\%(' . s:stdlib . '\)\ze\%([^A-Za-z0-9_-]\|$\)/ contained'
  syn match kameRecordKey /[A-Za-z_][A-Za-z0-9_-]*:/ contained
  syn match kameReference /[A-Za-z_][A-Za-z0-9_-]*\%(\%(\.[A-Za-z0-9_+{},.-]\+\|\/[A-Za-z0-9_+{},.-]\+\)\)\+[?!]\?/ contained
  syn match kamePlaceholder /_\{2,}\ze\%([^A-Za-z0-9_]\|$\)/ contained
  syn match kamePlaceholder /_\d\+\ze\%([^A-Za-z0-9_]\|$\)/ contained
  syn match kamePlaceholder /_\ze\%([^A-Za-z0-9_]\|$\)/ contained
  syn match kamePath /\%(\.\.\?\)\?\/\%([^{}()\[\] \t|]\+\|{[^}() \t]*}\)*/ contained contains=kameCapture
  syn region kameCapture start=/{/ end=/}/ contained contains=kameCaptureName,kameCapturePattern,kameCaptureDefault
  syn match kameCaptureName /\%(=\)\@<![A-Za-z_][A-Za-z0-9_-]*\ze}/ contained
  syn match kameCaptureName /[A-Za-z_][A-Za-z0-9_-]*\ze\%(:\|=\)/ contained
  syn match kameCapturePattern /:\zs\%([*?]\|\[\%([!^]\?[^]]*\)\]\)\+\ze}/ contained
  syn match kameCaptureDefault /=\zs[^}]*/ contained
  syn keyword kameSpecialForm def let eval if and or match with run! pipe! await finally! contained
  syn match kameSpecialForm /([ \t]*\zs?/ contained
  syn match kameOperator /|/ contained
  syn match kameComparisonOperator /==\|!=\|<=\|>=\|=\|<\|>/ contained
  syn region kameString start=/"/ skip=/\\./ end=/"/ contained
  syn region kameString start=/"""/ end=/"""/ keepend contained
  syn region kameCommandSubstitution matchgroup=kameCommandSubstitutionDelimiter start=/\$(/ end=/)/ contained

  " Inline @(EXPRESSION): the native document-template form. Selectors are
  " shared with recipes; Kame escape sequences \@ and \\ are recognized so an
  " escaped @ is treated as host text by the template renderer.
  "
  " containedin=ALL lets these entry points appear inside host regions (a
  " comment, an attribute value, a string) whose own contains list knows
  " nothing about Kame, which is the whole point of layering over an arbitrary
  " host language.
  syn region kameTemplateExpression matchgroup=kameTemplateDelimiter start=/@(/ end=/)/ contains=@kameValueGroup containedin=ALL
  " @{reference}: read and render a binding without invoking it. Selection
  " braces may nest one level, as in @{config.{host,port}}.
  syn match kameTemplateReference /@{[^{}]*\%({[^{}]*}[^{}]*\)*}/ containedin=ALL
  syn match kameSelectorInput /@<\%([*#?]\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)\?/ containedin=ALL
  syn match kameSelectorOutput /@>\%([*#]\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)\?/ containedin=ALL
  syn match kameSelectorArgument /@\%(_\|\*\|#\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)/ containedin=ALL
  syn match kameEscape /\\[@\\{}]/ containedin=ALL

  " Directive lines. A directive is keyword-gated and whole-line: nothing but
  " the host comment prefix may precede @keyword, and nothing but an optional
  " "(...)" argument list, the comment suffix, and whitespace may follow.
  " Directive lines are recognized for every comment style plus the bare plain
  " style; the keyword highlights, the wrapper stays host text.
  "
  " The head is a lookbehind so the syntax item starts at @, not at the comment
  " prefix. Host syntaxes commonly claim the prefix char with their own matcher
  " (PAML's tag match, for example); starting at @ keeps the overlay independent
  " of that, while the lookbehind still enforces the whole-line gate.
  let s:kw = '@-\?\%(if\|elif\|else\|for\|with\|let\|include\|match\|case\|raw\|end\)\>'
  let s:plainTail = '-\?\%(([^)]*)\)\?-\?\s*$'
  let s:cTail = '-\?\%(([^)]*)\)\?-\?\s*$'
   execute 'syn match kameTemplateDirective /\%(^\s*\)\@<=' . s:kw . '\ze' . s:plainTail . '/ containedin=ALL'
   execute 'syn match kameTemplateDirective /\%(^\s*#\s*\)\@<=' . s:kw . '\ze' . s:cTail . '/ containedin=ALL'
   execute 'syn match kameTemplateDirective /\%(^\s*\/\/\s*\)\@<=' . s:kw . '\ze' . s:cTail . '/ containedin=ALL'
   execute 'syn match kameTemplateDirective /\%(^\s*;\s*\)\@<=' . s:kw . '\ze' . s:cTail . '/ containedin=ALL'
   execute 'syn match kameTemplateDirective /\%(^\s*%\s*\)\@<=' . s:kw . '\ze' . s:cTail . '/ containedin=ALL'
   execute 'syn match kameTemplateDirective /\%(^\s*--\s*\)\@<=' . s:kw . '\ze' . s:cTail . '/ containedin=ALL'
   execute 'syn match kameTemplateDirective /\%(^\s*\/\*\s*\)\@<=' . s:kw . '\ze\%(([^)]*)\)\?\s*\*\/\s*$/ containedin=ALL'
   execute 'syn match kameTemplateDirective /\%(^\s*<!--\s*\)\@<=' . s:kw . '\ze\%(([^)]*)\)\?\s*-->\s*$/ containedin=ALL'
  " @@ at the directive position emits a literal @; highlight the escape.
  execute 'syn match kameEscape /\%(^\s*\S*\s*\)\@<=@@/ containedin=ALL'
  unlet! s:kw s:plainTail s:cTail

  " The overlay entry points, as a cluster hosts can name in their own
  " contains= to let Kame expansions nest inside a host match or region.
  " Raw blocks are not suppressed here: overlay items use containedin=ALL so
  " they can reach arbitrary host regions and matches. Recipe raw blocks,
  " whose items are cluster-contained, are handled by kameRecipeRaw.
   syn cluster kameTemplate contains=kameTemplateExpression,kameTemplateReference,kameSelectorInput,kameSelectorOutput,kameSelectorArgument,kameEscape,kameTemplateDirective

  " -------------------------------------------------------------------------
  " Host shims. A host matcher that spans template text can hide the overlay:
  " Vim picks the item that starts first, and a match without contains= cannot
  " nest another item. containedin=ALL covers host regions, but not host
  " matches. For PAML (the first .ktmpl host) re-declare the matches that run
  " over template text so they carry contains=@kameTemplate. Guarded so a host
  " rename or a different PAML build does not error.
  " -------------------------------------------------------------------------
  if s:host_syntax ==# 'paml' && hlexists('pamlLabel')
    " pamlLabel is ":.*": everything after ':' runs to end of line. Redefining
    " it is what lets `@(...)` in a label (e.g. `<title:@(title)`) be seen:
    " without contains= a host match cannot nest another syntax item.
    syn match pamlLabel /:.*/ contained contains=@kameTemplate
    " Attribute values run to ',' or ')'.
    syn match pamlAttributeVal /[^,\)]*/ contained contains=@kameTemplate
    " The attribute region. pamlAttributeVal is reached through pamlAttribute's
    " nextgroup, not listed directly: listing it would let its longer `[^,\)]*`
    " match beat pamlAttribute at the same start. The end chains back to
    " pamlLabel and pamlClass so a tag whose label follows its attributes
    " (`<a(href=...): label`) still highlights the label; stock PAML stops at ')'.
    syn region pamlAttributes start=+(+ end=+)+ contains=pamlAttribute,pamlAttributeSep,@kameTemplate nextgroup=pamlLabel,pamlClass,pamlClassSep
    " The tag. Keep @kameTemplate in nextgroup so a tag whose text is a bare
    " expansion (`<h1 @(heading)`) reaches the overlay.
    syn match pamlTag /\s*<\w*[^\W\(\.#:]/ nextgroup=pamlId,pamlClassSep,pamlLabel,pamlAttributes,pamlClass,@kameTemplate
  endif

  " Highlighting for the template layer.
  hi def link kameTemplateExpression Special
  hi def link kameTemplateDelimiter Special
  hi def link kameTemplateReference PreProc
  hi def link kameSelectorInput Special
  hi def link kameSelectorOutput PreProc
  hi def link kameSelectorArgument Identifier
  hi def link kameEscape SpecialChar
   hi def link kameTemplateDirective PreProc
  hi def link kameComment Comment
  hi def link kameDirective Include
  hi def link kameIncludePath Directory
  hi def link kameSymbol Constant
  hi def link kameBoolean Boolean
  hi def link kameNumber Number
  hi def link kameName Identifier
  hi def link kameVariable Constant
  hi def link kameFunctionCall Function
  hi def link kameStdlibFunction Special
  hi def link kameRecordKey Identifier
  hi def link kameReference Identifier
  hi def link kamePlaceholder Special
  hi def link kamePath Directory
  hi def link kameCapture Type
  hi def link kameCaptureName Identifier
  hi def link kameCapturePattern SpecialChar
  hi def link kameCaptureDefault String
  hi def link kameSpecialForm Statement
  hi def link kameOperator Operator
  hi def link kameComparisonOperator Operator
  hi def link kameString String
  hi def link kameCommandSubstitution Special
  hi def link kameCommandSubstitutionDelimiter Special
  hi def link kameDelimiter Delimiter

  let b:current_syntax = 'kame'
  finish
endif

" ---------------------------------------------------------------------------
" Clusters. Value atoms are shared by every source layer; the template and
" recipe clusters add the embedded expansions.
" ---------------------------------------------------------------------------
syn cluster kameValueGroup contains=kameExpression,kameList,kameString,kameNumber,kameBoolean,kameSymbol,kameVariable,kameName,kameFunctionCall,kameStdlibFunction,kameRecordKey,kamePath,kameCapture,kameSpecialForm,kameOperator,kameComparisonOperator,kameReference,kamePlaceholder,kameCommandSubstitution,kameTemplateReference,kameSelectorInput,kameSelectorOutput,kameSelectorArgument,kameDirective
syn cluster kameTemplateGroup contains=kameTemplateExpression,kameTemplateReference,kameSelectorInput,kameSelectorOutput,kameSelectorArgument,kameEscape
syn cluster kameHeaderGroup contains=kameRuleKind,kameRuleModifier,kameRuleSeparator,kameRuleOrderOnly,kameRuleGroupSeparator,kameTargetName,kamePath,kameCapture,kameString,kameRecordKey,kameSymbol,kameBoolean,kameTemplateExpression,kameTemplateReference,kameEscape
syn cluster kameRecipeGroup contains=kameTemplateExpression,kameTemplateReference,kameSelectorInput,kameSelectorOutput,kameSelectorArgument,kameEscape,kameRecipeDirective,kameRecipeRaw

" ---------------------------------------------------------------------------
" Expressions and lists.
" ---------------------------------------------------------------------------
syn region kameExpression matchgroup=kameDelimiter start=/(/ end=/)/ contains=@kameValueGroup
syn region kameList matchgroup=kameDelimiter start=/\[/ end=/\]/ contains=@kameValueGroup

" ---------------------------------------------------------------------------
" Value atoms: numbers, symbols, names, references, placeholders, paths, and
" captures. sh.vim adds '-' to the syntax iskeyword characters, which drops the
" word boundary between a sign and its digits, so numbers use explicit
" lookbehinds.
" ---------------------------------------------------------------------------
syn match kameNumber /-\?\%([0-9A-Za-z_]\)\@<!0[xX][0-9A-Fa-f]\%(_\?[0-9A-Fa-f]\)*\>/
syn match kameNumber /-\?\%([0-9A-Za-z_]\)\@<!0[bB][01]\%(_\?[01]\)*\>/
syn match kameNumber /-\?\%([0-9A-Za-z_]\)\@<!0[oO][0-7]\%(_\?[0-7]\)*\>/
syn match kameNumber /-\?\%([0-9A-Za-z_]\)\@<!\d\%(_\?\d\)*\%(\.\d\%(_\?\d\)*\)\?\%([eE][+-]\?\d\%(_\?\d\)*\)\?\>/
syn match kameSymbol /:[A-Za-z_][A-Za-z0-9_-]*/
" Boolean after Symbol so :true/:false/:nil win at the same start position.
syn match kameBoolean /:\%(true\|false\|nil\)\>/
syn match kameVariable /\<[A-Z][A-Z0-9_]*\ze\%([^A-Za-z0-9_-]\|$\)/
syn match kameName /\<[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze\%([^A-Za-z0-9_-]\|$\)/
syn match kameFunctionCall /\<[a-z][A-Za-z0-9_-]*[?!]\?\ze\%([^A-Za-z0-9_-]\|$\)/
execute 'syn match kameStdlibFunction /\<\%(' . s:stdlib . '\)\ze\%([^A-Za-z0-9_-]\|$\)/ contained'
syn match kameTargetName /\<[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze\%([^A-Za-z0-9_-]\|$\)/ contained
syn match kameRecordKey /[A-Za-z_][A-Za-z0-9_-]*:/ contained

" A reference is a name followed by slash names or dot components: tool and
" context names (x/uv, inputs/changed), fields, indexes, slices, and key
" selections. Defined after kameName so it wins at the shared start position,
" both at the top level and inside the value cluster.
syn match kameReference /[A-Za-z_][A-Za-z0-9_-]*\%(\%(\.[A-Za-z0-9_+{},.-]\+\|\/[A-Za-z0-9_+{},.-]\+\)\)\+[?!]\?/

" A placeholder atom is '_', a run of underscores, or '_' plus decimal digits.
syn match kamePlaceholder /_\{2,}\ze\%([^A-Za-z0-9_]\|$\)/ contained
syn match kamePlaceholder /_\d\+\ze\%([^A-Za-z0-9_]\|$\)/ contained
syn match kamePlaceholder /_\ze\%([^A-Za-z0-9_]\|$\)/ contained

syn match kamePath /\%(\.\.\?\)\?\/\%([^{}()\[\] \t|]\+\|{[^}() \t]*}\)*/ contains=kameCapture
syn region kameCapture start=/{/ end=/}/ contains=kameCaptureName,kameCapturePattern,kameCaptureDefault
syn match kameCaptureName /\%(=\)\@<![A-Za-z_][A-Za-z0-9_-]*\ze}/ contained
syn match kameCaptureName /[A-Za-z_][A-Za-z0-9_-]*\ze\%(:\|=\)/ contained
syn match kameCapturePattern /:\zs\%([*?]\|\[\%([!^]\?[^]]*\)\]\)\+\ze}/ contained
syn match kameCaptureDefault /=\zs[^}]*/ contained

" ---------------------------------------------------------------------------
" Special forms and operators.
" ---------------------------------------------------------------------------
syn keyword kameSpecialForm def let eval if and or match with run! pipe! await finally! contained
syn match kameSpecialForm /([ \t]*\zs?/ contained
syn match kameOperator /|/ contained
syn match kameComparisonOperator /==\|!=\|<=\|>=\|=\|<\|>/ contained

" ---------------------------------------------------------------------------
" Strings and template expansions. Template items also match inside shell
" quoting, command substitution, and here-documents because Kame expands
" external-shell recipe text before the shell runs it. A bare {( ... )} is
" literal text in the current grammar; only @{reference} and @(expression)
" interpolate.
" ---------------------------------------------------------------------------
syn region kameString start=/"/ skip=/\\./ end=/"/ contains=@kameTemplateGroup
" A verbatim string is a run of three or more quotes; define it last so it wins
" over the ordinary quoted string at the shared start position.
syn region kameString start=/"""/ end=/"""/ keepend
execute 'syn region kameTemplateExpression matchgroup=kameTemplateDelimiter start=/@(/ end=/)/ contains=@kameValueGroup containedin=' . s:templateContexts
let s:referencePrefix = s:kash_top ? '\%(^\s*\)\@<!' : ''
execute 'syn match kameTemplateReference /' . s:referencePrefix . '@{[^{}]*\%({[^{}]*}[^{}]*\)*}/ containedin=' . s:templateContexts
unlet! s:referencePrefix
execute 'syn match kameSelectorInput /@<\%([*#?]\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)\?/ contained containedin=' . s:templateContexts
execute 'syn match kameSelectorOutput /@>\%([*#]\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)\?/ contained containedin=' . s:templateContexts
execute 'syn match kameSelectorArgument /@\%(_\|\*\|#\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)/ contained containedin=' . s:templateContexts
execute 'syn match kameEscape /\\[@\\{}]/ contained containedin=' . s:templateContexts

" `$(COMMAND)` is a Kame expression atom whose contents are Kash. It is shared
" by every layer: expressions, rule inputs, and Kash command words.
syn region kameCommandSubstitution matchgroup=kameCommandSubstitutionDelimiter start=/\$(/ end=/)/ contains=@kameKash

" ---------------------------------------------------------------------------
" Kash process syntax. Defined through a helper so the same items are
" top-level in a .kash source and contained everywhere else (recipes and
" command substitutions).
" ---------------------------------------------------------------------------
" Hybrid rule recipes layer the template overlay over Kash strings too, so
" `"release @>-1"` and `"@{TARGET}"` remain visible while editing. Strict
" direct Kash keeps its strings literal.
let s:kashStringTemplate = s:rule && s:recipe ==# 'hybrid' ? ',@kameTemplateGroup' : ''

function! s:DefineKash(contained) abort
  let c = a:contained ? 'contained ' : ''

  " A '#' at the start of a word comments through the end of the line.
  execute 'syn match kameComment /\%(^\|[ \t;|(,]\)\zs#.*$/ ' . c . 'contains=@Spell'

  " $REFERENCE, ${REFERENCE}, and explicit argv spread $...REFERENCE /
  " $...{REFERENCE}. The reference grammar accepts slash names (x/uv,
  " inputs/changed), fields, indexes, slices, and key selections; a trailing ?
  " or ! belongs to the name.
  execute 'syn match kameKashReference /\$\%(\.\.\.\)\?{[^{}]*\%({[^{}]*}[^{}]*\)*}/ ' . c
  execute 'syn match kameKashReference /\$\%(\.\.\.\)\?[A-Za-z_][A-Za-z0-9_-]*\%(\%(\.[A-Za-z0-9_+{},.-]\+\|\/[A-Za-z0-9_+{},.-]\+\)\)*[?!]\?/ ' . c

  " The executable is the first word of a command stage: line start, after a
  " pipe or semicolon, after a sequential operator, after $(, or after one or
  " more :KEY VALUE setup pairs. Substitutions and expressions are excluded so
  " their own items win at the same position.
  let s:setupvalue = '\%(\%([^)]*)\)\|\%(\[[^]]*\]\)\|"[^"]*"\|\S\+\)'
  let s:setup = ':[^ \t]\+[ \t]\+' . s:setupvalue . '[ \t]\+'
  let s:stage = '\%(^[ \t]*\|\$([ \t]*\|[|;][ \t]*\|&&[ \t]*\|||[ \t]*\)'
  let s:stagepat = '\%(\$(\|[|;]\|&&\|||\)[ \t]*'
  let s:stagebe = '\%(' . s:stagepat . '\)\@<='
  execute 'syn match kameKashCommand /^[ \t]*\zs[^ \t|;&<>#"@$(:]\+/ ' . c
  execute 'syn match kameKashCommand /\%(\%(\$(\|[|;]\|&&\|||\|)\|[?]\)[ \t]*\)\@<=[^ \t|;&<>#"@$(:]\+/ ' . c
  execute 'syn match kameKashOption /\%(^\|[ \t]\)\zs-\{1,2\}[A-Za-z0-9][A-Za-z0-9-]*/ ' . c

  " A parenthesized Kash group can hold commands, stream operators, and
  " embedded Kame expressions. It is defined after the shared expression region
  " so it wins inside Kash while still delegating values to the value cluster.
  execute 'syn region kameKashGroup matchgroup=kameDelimiter start=/(/ end=/)/ contains=@kameValueGroup,@kameKash ' . c

  " A comma before the closing ')' marks a process group rather than an
  " embedded expression. Its first members are executables, not calls.
  execute 'syn region kameKashProcessGroup matchgroup=kameDelimiter start=/(\ze\%([^()"]\|"[^"]*"\)*,\%([^()"]\|"[^"]*"\)*)/ end=/)/ contains=kameKashGroupCommand,@kameValueGroup,@kameKash ' . c
  execute 'syn match kameKashGroupCommand /\%(([ \t]*\|,[ \t]*\)\@<=[^ \t|;&<>#"@$(:]\+/ contained containedin=kameKashProcessGroup ' . c

  " Process operators. Longer forms are defined after shorter ones so they win
  " at the shared start position.
  execute 'syn match kameKashPipeline /|/ ' . c
  execute 'syn match kameKashSeparator /;/ ' . c
  execute 'syn match kameKashRedirection /</ ' . c
  execute 'syn match kameKashRedirection />/ ' . c
  execute 'syn match kameKashRedirection />>/ ' . c
  execute 'syn match kameKashRedirection /2>/ ' . c
  execute 'syn match kameKashRedirection /2>>/ ' . c
  execute 'syn match kameKashRedirection /2>&1/ ' . c
  execute 'syn match kameKashRedirection />@/ ' . c
  execute 'syn match kameKashChannel />&/ ' . c
  execute 'syn match kameKashChannel />&[A-Za-z_][A-Za-z0-9_-]*/ ' . c
  execute 'syn match kameKashChannel /<&/ ' . c
  execute 'syn match kameKashChannel /<&[A-Za-z_][A-Za-z0-9_-]*/ ' . c
  execute 'syn match kameKashAcceptance /?/ ' . c
  execute 'syn match kameKashRecovery /??/ ' . c
  execute 'syn match kameKashAsync /&/ ' . c
  execute 'syn match kameKashSequential /&&\|||/ ' . c
  execute 'syn match kameKashChannel /&[A-Za-z_][A-Za-z0-9_-]*/ ' . c

  " Block and statement keywords. Defined after the command head so a keyword
  " line wins over the first-word executable match.
  execute 'syn match kameKashKeyword /^[ \t]*\zs\%(if\|elif\|else\|match\|case\|def\|let\|defer\|return\|exit\|for\|while\|break\|continue\|with\|stream\)\ze\%([ \t]\|$\)/ ' . c
  execute 'syn match kameKashKeyword /\%(^[ \t]*for[ \t]\+\S\+[ \t]\+\)\@<=\%(in\|from\)\ze[ \t]/ ' . c

  " Stage setup keys: ':cwd', ':timeout', ':accept-exit', ':ENV' before the
  " executable. Defined after the command head so ':key' wins there.
  execute 'syn match kameKashSetup /' . s:stage . '\zs\%(' . s:setup . '\)\+/ contains=kameKashSetupKey nextgroup=kameKashCommand skipwhite ' . c
  execute 'syn match kameKashSetup /' . s:stagebe . '\%(' . s:setup . '\)\+/ contains=kameKashSetupKey nextgroup=kameKashCommand skipwhite ' . c
  execute 'syn match kameKashCommand /\%(^[ \t]*\%(' . s:setup . '\)\+\)\@<=[^ \t|;&<>#"@$(:]\+/ ' . c
  execute 'syn match kameKashCommand /\%(' . s:stagepat . '\%(' . s:setup . '\)\+\)\@<=[^ \t|;&<>#"@$(:]\+/ ' . c
  execute 'syn match kameKashSetupKey /:[A-Za-z_][A-Za-z0-9_-]*/ contained ' . c
  " A with block header accepts setup pairs, values, and references.
  execute 'syn region kameKashWithHeader start=/^[ \t]*with\>/ end=/$/ contains=kameKashKeyword,kameKashSetupKey,kameKashReference ' . c
  " Stream declarations: `stream NAME`.
  execute 'syn region kameKashStreamHeader start=/^[ \t]*stream\>/ end=/$/ contains=kameKashKeyword,kameKashChannelName ' . c
  execute 'syn match kameKashChannelName /[ \t]\zs[A-Za-z_][A-Za-z0-9_-]*/ contained ' . c

  " Explicit graph operators: `|(merge)`, `|(frame :lines)`, `|(tee PATH)`,
  " and their policy keys. The region starts at the '(' after a '|', so plain
  " parenthesized Kash expressions keep using kameKashGroup.
  execute 'syn region kameKashMuxRegion matchgroup=kameDelimiter start=/\%(|\)\@<=(/ end=/)/ contains=kameKashMux,kameKashMuxKey,@kameValueGroup,@kameKash ' . c
  execute 'syn match kameKashMux /\%(merge\|broadcast\|balance\|tee\|frame\|filter\|encode\|each\)\>/ contained ' . c
  execute 'syn match kameKashMuxKey /:[A-Za-z_][A-Za-z0-9_-]*/ contained ' . c

  " Kash strings allow reference and command-capture substitutions, not
  " template @(...), selectors, or brace interpolation.
  execute 'syn match kameEscape /\\[\\"$@ntr]/ contained ' . c
  execute 'syn region kameKashString start=/"/ skip=/\\./ end=/"/ contains=kameEscape,kameKashReference,kameCommandSubstitution' . s:kashStringTemplate . ' ' . c
endfunction

call s:DefineKash(s:kash_top ? 0 : 1)

syn cluster kameKash contains=kameKashKeyword,kameKashSetup,kameKashSetupKey,kameKashCommand,kameKashOption,kameKashPipeline,kameKashRedirection,kameKashAcceptance,kameKashRecovery,kameKashAsync,kameKashSequential,kameKashChannel,kameKashReference,kameKashString,kameKashWithHeader,kameKashStreamHeader,kameKashGroup,kameKashProcessGroup,kameKashMuxRegion,kameDefinition,kameFunctionDefinition,kameCommandSubstitution,kameComment

" ---------------------------------------------------------------------------
" Comments. '#' and '//' begin a comment on the value and rule layers; '//' is
" literal Kash command text, so a Kash source only defines '#'.
" ---------------------------------------------------------------------------
syn match kameComment /^[ \t]*#.*$/ contains=@Spell
if !s:kash_top
  syn match kameComment /^[ \t]*\/\/.*$/ contains=@Spell
endif

" ---------------------------------------------------------------------------
" Includes are a value-program and rule-program directive; headers, recipes,
" and recipe directives belong to the rule program.
" ---------------------------------------------------------------------------
syn match kameDirective /\<include[?]\=\ze\%([ \t)]\|$\)/ nextgroup=kameIncludePath skipwhite
syn match kameIncludePath /\%("[^"]*"\|[^ \t#)]\+\)/ contained

if s:rule
  " Header paths do not absorb a following comma: commas separate input groups.
  syn match kamePath /\%(\.\.\?\)\?\/\%(\%([^{}()\[\] \t|,]\+\)\|\%({[^}() \t]*}\)\)*/ contained contains=kameCapture
  syn match kameRuleHeader /^\%(\%(task\|service\)[ \t]\+\)\?\%(always[ \t]\+\)\?\%(\[\|\/\/\)\@!\%([^ \t=(#]\S*\)\%([ \t]\+\S\+\)*[ \t]*\%(:\|<-\)\%([ \t].*\)\?$/ contains=@kameHeaderGroup
  syn match kameRuleSeparator /:\|<-/ contained
  syn keyword kameRuleKind task service contained
  syn match kameRuleModifier /always/ contained
  syn match kameRuleOrderOnly /|/ contained
  syn match kameRuleGroupSeparator /,/ contained

  " Whole-line, keyword-gated recipe directives retain no shell text.
  syn match kameRecipeDirective /^[ \t]*@-\?\%(if\|elif\|else\|for\|with\|let\|include\|match\|case\|raw\|end\)\>-\?/ contained
  syn match kameRecipeDirective /^[ \t]*@@/ contained
  " Raw regions are literal: no shell, template, or directive matching inside.
  syn region kameRecipeRaw matchgroup=kameRecipeDirective start=/^[ \t]*@raw\>/ end=/^[ \t]*@end\>/ keepend contained

  if s:recipe ==# 'shell'
    let s:recipeContains = '@kameShell,@kameRecipeGroup'
  elseif s:recipe ==# 'kash'
    " Strict direct Kash recipes are parsed as Kash, not rendered as document
    " templates, so template directives and selectors do not apply.
    let s:recipeContains = '@kameKash'
  elseif s:recipe ==# 'hybrid'
    " Editor convenience: Kash command syntax plus the template overlay.
    let s:recipeContains = '@kameKash,@kameRecipeGroup'
  elseif s:recipe ==# 'kame'
    " A value-producing [shell: kame] body is one Kame expression.
    let s:recipeContains = '@kameValueGroup'
  else
    let s:recipeContains = '@kameRecipeGroup'
  endif
  execute 'syn region kameRecipe start=/^[ \t]\+/ end=/^\ze\S/ keepend contains=' . s:recipeContains
endif

" ---------------------------------------------------------------------------
" Definitions are shared by the value, rule, and Kash layers. They are defined
" after the rule layer and the Kash command words so a definition header wins
" over a rule header and over a first-word command match.
" ---------------------------------------------------------------------------
syn match kameDefinition /^[ \t]*[A-Za-z_][A-Za-z0-9_-]*[?!]\?[ \t]*=/ contains=kameDefinitionName,kameDefinitionOperator
syn match kameDefinitionName /^[ \t]*[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze[ \t]*=/ contained
syn match kameDefinitionOperator /=/ contained

if !s:kash_top
  syn match kameDefinition /^[ \t]*[A-Za-z_][A-Za-z0-9_-]*[?!]\?[ \t]*\%(?=\|+=\)/ contains=kameDefinitionName,kameDefinitionOperator
  syn match kameDefinitionName /^[ \t]*[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze[ \t]*\%(?=\|+=\)/ contained
  syn match kameDefinitionOperator /\%(?=\|+=\)/ contained
endif

syn match kameFunctionDefinition /^[ \t]*([^)\n]*)[ \t]*=/ contains=kameFunctionName,kameFunctionParameter,kameDefinitionOperator
syn match kameFunctionParameter /[^ \t()]\+/ contained
syn match kameFunctionName /^[ \t]*([ \t]*\zs[^ \t(]\+/ contained

" Kash statement headers that name a binding: let NAME, def NAME, and
" for NAME. Defined after the shared function-call and definition items so the
" binder wins over the generic lowercase-name match.
function! s:DefineKashNames(contained) abort
  let c = a:contained ? 'containedin=kameRecipe ' : ''
  execute 'syn match kameDefinitionName /\%(^[ \t]*for[ \t]\+\)\@<=[A-Za-z_][A-Za-z0-9_-]*[?!]\?/ ' . c
  execute 'syn match kameDefinitionName /\%(^[ \t]*let[ \t]\+\)\@<=[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze[ \t]*=/ ' . c
  execute 'syn match kameDefinitionOperator /\%(^[ \t]*let[ \t]\+\S\+[ \t]*\)\@==/ ' . c
  execute 'syn match kameFunctionName /\%(^[ \t]*def[ \t]\+\)\@<=[A-Za-z_][A-Za-z0-9_-]*[?!]\?/ ' . c
  execute 'syn match kameFunctionParameter /\%(^[ \t]*def[ \t]\+\S\+[ \t]\+\)\@<=[^ \t#]\+\%([ \t]\+[^ \t#]\+\)*/ ' . c
endfunction
if s:kash_top
  call s:DefineKashNames(0)
elseif s:rule && s:recipe ==# 'kash'
  call s:DefineKashNames(1)
endif

" ---------------------------------------------------------------------------
" Highlighting. Groups without a link below (kameRuleHeader, kameRecipe,
" kameExpression, kameList, kameDefinition, kameFunctionDefinition) only exist
" for containment and stay uncolored.
" ---------------------------------------------------------------------------
hi def link kameComment Comment
hi def link kameDirective Include
hi def link kameIncludePath Directory
hi def link kameRuleKind Keyword
hi def link kameRuleModifier Keyword
hi def link kameRuleSeparator Operator
hi def link kameRuleOrderOnly Operator
hi def link kameRuleGroupSeparator Delimiter
hi def link kameTargetName Function
hi def link kameDefinitionName Define
hi def link kameDefinitionOperator Operator
hi def link kameFunctionName Function
hi def link kameFunctionParameter Identifier
hi def link kameSymbol Constant
hi def link kameBoolean Boolean
hi def link kameNumber Number
hi def link kameName Identifier
hi def link kameVariable Constant
hi def link kameFunctionCall Function
hi def link kameStdlibFunction Special
hi def link kameRecordKey Identifier
hi def link kameReference Identifier
hi def link kamePlaceholder Special
hi def link kamePath Directory
hi def link kameCapture Type
hi def link kameCaptureName Identifier
hi def link kameCapturePattern SpecialChar
hi def link kameCaptureDefault String
hi def link kameSpecialForm Statement
hi def link kameOperator Operator
hi def link kameComparisonOperator Operator
hi def link kameString String
hi def link kameTemplateExpression Special
hi def link kameTemplateDelimiter Special
hi def link kameTemplateReference PreProc
hi def link kameSelectorInput Special
hi def link kameSelectorOutput PreProc
hi def link kameSelectorArgument Identifier
hi def link kameEscape SpecialChar
hi def link kameCommandSubstitution Special
hi def link kameCommandSubstitutionDelimiter Special
hi def link kameRecipeDirective PreProc
hi def link kameKashKeyword Conditional
hi def link kameKashCommand Function
hi def link kameKashGroupCommand Function
hi def link kameKashOption Identifier
hi def link kameKashSetupKey Keyword
hi def link kameKashPipeline Operator
hi def link kameKashRedirection Operator
hi def link kameKashAcceptance Operator
hi def link kameKashRecovery Operator
hi def link kameKashAsync Operator
hi def link kameKashSequential Operator
hi def link kameKashSeparator Delimiter
hi def link kameKashChannel Special
hi def link kameKashChannelName Special
hi def link kameKashMux Operator
hi def link kameKashMuxKey Keyword
hi def link kameKashReference Identifier
hi def link kameKashString String
hi def link kameDelimiter Delimiter

let b:current_syntax = 'kame'
