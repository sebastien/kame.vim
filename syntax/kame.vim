" Vim syntax file
" Language: Kame value programs (.km/.kmd), rule programs (.kmk), and Kash
"           process programs (.kash/.ksh)
" Maintainer: Sebastien Pierre

if exists('b:current_syntax')
  finish
endif

syn case match

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

" ---------------------------------------------------------------------------
" Recipe language: kash (default), shell, or none. g:kame_no_shell_syntax is
" the legacy spelling of "none". An unknown value falls back to kash.
" ---------------------------------------------------------------------------
let s:recipe = get(g:, 'kame_recipe_lang', '')
if empty(s:recipe)
  let s:recipe = get(g:, 'kame_no_shell_syntax', 0) ? 'none' : 'kash'
elseif s:recipe !=# 'kash' && s:recipe !=# 'shell' && s:recipe !=# 'none'
  let s:recipe = 'kash'
endif

" ---------------------------------------------------------------------------
" Embedded shell recipes (legacy). sh.vim reads g:is_bash, g:is_posix,
" g:is_kornshell, and g:is_dash to pick a dialect.
" ---------------------------------------------------------------------------
if s:rule && s:recipe ==# 'shell'
  syn include @kameShell syntax/sh.vim
  unlet! b:current_syntax
  let s:templateContexts = 'kameRecipe,kameString,sh.*'
else
  let s:templateContexts = 'kameRecipe,kameString'
endif

" ---------------------------------------------------------------------------
" Clusters. Value atoms are shared by every source layer; the template and
" recipe clusters add the embedded expansions.
" ---------------------------------------------------------------------------
syn cluster kameValueGroup contains=kameExpression,kameList,kameString,kameInterpolation,kameNumber,kameBoolean,kameSymbol,kameName,kameRecordKey,kamePath,kameCapture,kameSpecialForm,kameOperator,kameComparisonOperator,kameReference,kamePlaceholder,kameCommandSubstitution
syn cluster kameTemplateGroup contains=kameTemplateExpression,kameTemplateReference,kameSelectorInput,kameSelectorOutput,kameSelectorArgument,kameEscape,kameInterpolation
syn cluster kameHeaderGroup contains=kameRuleKind,kameRuleSeparator,kameTargetName,kamePath,kameCapture,kameString,kameTemplateExpression,kameTemplateReference,kameEscape
syn cluster kameRecipeGroup contains=kameTemplateExpression,kameTemplateReference,kameSelectorInput,kameSelectorOutput,kameSelectorArgument,kameEscape,kameRecipeDirective

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
syn match kameName /\<[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze\%([^A-Za-z0-9_-]\|$\)/
syn match kameTargetName /\<[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze\%([^A-Za-z0-9_-]\|$\)/ contained
syn match kameRecordKey /[A-Za-z_][A-Za-z0-9_-]*:/ contained

" A reference is a name followed by dot components: indexes, slices, and key
" selections. Defined after kameName so it wins at the shared start position,
" both at the top level and inside the value cluster.
syn match kameReference /[A-Za-z_][A-Za-z0-9_-]*\%(\.[A-Za-z0-9_+{},.-]\+\)\+/

" A placeholder atom is '_', a run of underscores, or '_' plus decimal digits.
syn match kamePlaceholder /_\{2,}\ze\%([^A-Za-z0-9_]\|$\)/ contained
syn match kamePlaceholder /_\d\+\ze\%([^A-Za-z0-9_]\|$\)/ contained
syn match kamePlaceholder /_\ze\%([^A-Za-z0-9_]\|$\)/ contained

syn match kamePath /\%(\.\.\?\)\?\/\%([^{}()\[\] \t|]\+\|{[^}() \t]*}\)*/ contains=kameCapture
syn region kameCapture start=/{/ end=/}/ contains=kameCaptureName,kameCapturePattern
syn match kameCaptureName /[A-Za-z_][A-Za-z0-9_-]*\ze\%(:\|}\)/ contained
syn match kameCapturePattern /:\zs\%([*?]\|\[\%([!^]\?[^]]*\)\]\)\+\ze}/ contained

" ---------------------------------------------------------------------------
" Special forms and operators.
" ---------------------------------------------------------------------------
syn keyword kameSpecialForm def let eval if and or match with contained
syn match kameSpecialForm /([ \t]*\zs?/ contained
syn match kameOperator /|/ contained
syn match kameComparisonOperator /==\|!=\|<=\|>=\|=\|<\|>/ contained

" ---------------------------------------------------------------------------
" Strings, interpolation, and template expansions. Template items also match
" inside shell quoting, command substitution, and here-documents because Kame
" expands recipe text before the shell runs it.
" ---------------------------------------------------------------------------
syn region kameString start=/"/ skip=/\\./ end=/"/ contains=@kameTemplateGroup
" A verbatim string is a run of three or more quotes; define it last so it wins
" over the ordinary quoted string at the shared start position.
syn region kameString start=/"""/ end=/"""/ keepend
syn region kameInterpolation matchgroup=kameInterpolationDelimiter start=/{(/ end=/)}/ contained contains=@kameValueGroup
execute 'syn region kameTemplateExpression matchgroup=kameTemplateDelimiter start=/@(/ end=/)/ contains=@kameValueGroup containedin=' . s:templateContexts
execute 'syn match kameTemplateReference /@{[^}]*}/ containedin=' . s:templateContexts
execute 'syn match kameSelectorInput /@<\%([*#]\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)\?/ contained containedin=' . s:templateContexts
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
function! s:DefineKash(contained) abort
  let c = a:contained ? 'contained ' : ''

  " A '#' at the start of a word comments through the end of the line.
  execute 'syn match kameComment /\%(^\|[ \t]\)\zs#.*$/ ' . c . 'contains=@Spell'
  " The executable is the first word of a command stage. Substitutions and
  " expressions are excluded so their own items win at the same position. The
  " second form matches a stage that follows a pipe or semicolon.
  execute 'syn match kameKashCommand /^[ \t]*\zs[^ \t|;&<>#"@$(]\+/ ' . c
  execute 'syn match kameKashCommand /\%([|;]\s*\)\@<=[^ \t|;&<>#"@$(]\+/ ' . c
  execute 'syn match kameKashOption /\%(^\|[ \t]\)\zs-\{1,2\}[A-Za-z0-9][A-Za-z0-9-]*/ ' . c
  " Stage setup keys: ':cwd', ':timeout', ':ENV' before the executable. Defined
  " after the executable so ':key' wins over the first-word match.
  execute 'syn match kameKashSetupKey /^[ \t]*\zs:[A-Za-z_][A-Za-z0-9_]*/ ' . c
  " Block keywords open a sub-block; recognised only on a keyword line.
  " Defined last among the anchored words so they win over the executable.
  execute 'syn match kameKashKeyword /^[ \t]*\zs\%(if\|elif\|else\|match\|case\)\ze\%([ \t]\|$\)/ ' . c
  " Process operators. Recovery is defined after acceptance so '??' wins.
  execute 'syn match kameKashPipeline /|/ ' . c
  execute 'syn match kameKashRedirection />>\|[<>]/ ' . c
  execute 'syn match kameKashAcceptance /?/ ' . c
  execute 'syn match kameKashRecovery /??/ ' . c
  execute 'syn match kameKashAsync /&/ ' . c
  execute 'syn match kameKashSeparator /;/ ' . c
  " Reserved meta-programming forms: @NAME and @tmpl(...).
  execute 'syn match kameKashMeta /@[A-Za-z_][A-Za-z0-9_-]*\%(([^)]*)\)\?/ ' . c
  " Reference wrappers: $REFERENCE and ${REFERENCE}.
  execute 'syn match kameKashReference /\${[^}]*}/ ' . c
  execute 'syn match kameKashReference /\$[A-Za-z_][A-Za-z0-9_-]*\%(\.[A-Za-z0-9_+{},.-]\+\)*/ ' . c
  " Kash strings behave like shell words: all four substitutions are allowed.
  execute 'syn region kameKashString start=/"/ skip=/\\./ end=/"/ contains=@kameTemplateGroup,kameKashReference,kameCommandSubstitution ' . c
endfunction

call s:DefineKash(s:kash_top ? 0 : 1)

syn cluster kameKash contains=kameKashKeyword,kameKashSetupKey,kameKashCommand,kameKashOption,kameKashPipeline,kameKashRedirection,kameKashAcceptance,kameKashRecovery,kameKashAsync,kameKashSeparator,kameKashMeta,kameKashReference,kameKashString,kameCommandSubstitution,kameComment

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
syn keyword kameDirective include nextgroup=kameIncludePath skipwhite
syn match kameIncludePath /\%("[^"]*"\|[^ \t#]\+\)/ contained

if s:rule
  syn match kameRuleHeader /^\%(\%(task\|service\)[ \t]\+\)\?\%(\[\|\/\/\)\@!\%([^ \t=(#]\S*\)\%([ \t]\+\S\+\)*[ \t]*:\%([ \t].*\)\?$/ contains=@kameHeaderGroup
  syn match kameRuleSeparator /:/ contained
  syn keyword kameRuleKind task service contained

  " Whole-line, keyword-gated recipe directives retain no shell text.
  syn match kameRecipeDirective /^[ \t]*@\%(if\|elif\|else\|for\|with\|let\|include\|raw\|end\)\>/ contained
  syn match kameRecipeDirective /^[ \t]*@@/ contained

  if s:recipe ==# 'shell'
    let s:recipeContains = '@kameShell,@kameRecipeGroup'
  elseif s:recipe ==# 'kash'
    let s:recipeContains = '@kameKash,@kameRecipeGroup'
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
syn match kameDefinition /^[A-Za-z_][A-Za-z0-9_-]*[?!]\?[ \t]*=/ contains=kameDefinitionName,kameDefinitionOperator
syn match kameDefinitionName /^[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze[ \t]*=/ contained
syn match kameDefinitionOperator /=/ contained

syn match kameFunctionDefinition /^([^)\n]*)[ \t]*=/ contains=kameFunctionName,kameFunctionParameter,kameDefinitionOperator
syn match kameFunctionParameter /[^ \t()]\+/ contained
syn match kameFunctionName /^([ \t]*\zs[^ \t(]\+/ contained

" ---------------------------------------------------------------------------
" Highlighting. Groups without a link below (kameRuleHeader, kameRecipe,
" kameExpression, kameList, kameDefinition, kameFunctionDefinition) only exist
" for containment and stay uncolored.
" ---------------------------------------------------------------------------
hi def link kameComment Comment
hi def link kameDirective Include
hi def link kameIncludePath Directory
hi def link kameRuleKind Keyword
hi def link kameRuleSeparator Operator
hi def link kameTargetName Function
hi def link kameDefinitionName Define
hi def link kameDefinitionOperator Operator
hi def link kameFunctionName Function
hi def link kameFunctionParameter Identifier
hi def link kameSymbol Constant
hi def link kameBoolean Boolean
hi def link kameNumber Number
hi def link kameName Identifier
hi def link kameRecordKey Identifier
hi def link kameReference Identifier
hi def link kamePlaceholder Special
hi def link kamePath Directory
hi def link kameCapture Type
hi def link kameCaptureName Identifier
hi def link kameCapturePattern SpecialChar
hi def link kameSpecialForm Statement
hi def link kameOperator Operator
hi def link kameComparisonOperator Operator
hi def link kameString String
hi def link kameInterpolation Special
hi def link kameInterpolationDelimiter Special
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
hi def link kameKashOption Identifier
hi def link kameKashSetupKey Keyword
hi def link kameKashPipeline Operator
hi def link kameKashRedirection Operator
hi def link kameKashAcceptance Operator
hi def link kameKashRecovery Operator
hi def link kameKashAsync Operator
hi def link kameKashSeparator Delimiter
hi def link kameKashMeta PreProc
hi def link kameKashReference Identifier
hi def link kameKashString String
hi def link kameDelimiter Delimiter

let b:current_syntax = 'kame'
