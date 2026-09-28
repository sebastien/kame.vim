" Vim syntax file
" Language: Kame build language
" Maintainer: Sebastien Pierre

if exists('b:current_syntax')
  finish
endif

syn case match

" ---------------------------------------------------------------------------
" Rule recipes are one shell script, so embed the runtime shell syntax.
" sh.vim reads g:is_bash, g:is_posix, g:is_kornshell, and g:is_dash to pick a
" dialect. Set g:kame_no_shell_syntax to skip the embedding entirely.
" ---------------------------------------------------------------------------
if get(g:, 'kame_no_shell_syntax', 0)
  " kameShellDisabled is intentionally undefined so @kameShell stays empty and
  " kameRecipe falls back to its own group when shell is off.
  syn cluster kameShell contains=kameShellDisabled
  let s:templateContexts = 'kameRecipe,kameString'
else
  syn include @kameShell syntax/sh.vim
  unlet! b:current_syntax
  let s:templateContexts = 'kameRecipe,kameString,sh.*'
endif

" ---------------------------------------------------------------------------
" Clusters
" ---------------------------------------------------------------------------
syn cluster kameValueGroup contains=kameExpression,kameList,kameString,kameInterpolation,kameNumber,kameBoolean,kameSymbol,kameName,kameRecordKey,kamePath,kameCapture,kameSpecialForm,kameOperator
syn cluster kameTemplateGroup contains=kameTemplateExpression,kameTemplateReference,kameSelectorInput,kameSelectorOutput,kameSelectorArgument,kameEscape,kameInterpolation
syn cluster kameHeaderGroup contains=kameRuleKind,kameRuleSeparator,kameTargetName,kamePath,kameCapture,kameString,kameTemplateExpression,kameTemplateReference,kameEscape
syn cluster kameRecipeGroup contains=kameTemplateExpression,kameTemplateReference,kameSelectorInput,kameSelectorOutput,kameSelectorArgument,kameEscape

" ---------------------------------------------------------------------------
" Expressions and lists.
" ---------------------------------------------------------------------------
syn region kameExpression matchgroup=kameDelimiter start=/(/ end=/)/ contains=@kameValueGroup
syn region kameList matchgroup=kameDelimiter start=/\[/ end=/\]/ contains=@kameValueGroup

" ---------------------------------------------------------------------------
" Value atoms: numbers, symbols, names, paths, and captures.
" ---------------------------------------------------------------------------
" sh.vim adds '-' to the syntax iskeyword characters, which drops the word
" boundary between a sign and its digits, so numbers use explicit lookbehinds.
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
syn keyword kameRuleKind task service contained

syn match kamePath /\%(\.\.\?\)\?\/\%([^{}()\[\] \t|]\+\|{[^}() \t]*}\)*/ contains=kameCapture
syn region kameCapture start=/{/ end=/}/ contains=kameCaptureName,kameGlob
syn match kameCaptureName /[A-Za-z_][A-Za-z0-9_-]*\ze\%(:\|}\)/ contained
syn match kameGlob /[*?]\|\[\%([!^]\?[^]]*\)\]/ contained

" ---------------------------------------------------------------------------
" Special forms and operators.
" ---------------------------------------------------------------------------
syn keyword kameSpecialForm def let eval contained
syn match kameSpecialForm /([ \t]*\zs?/ contained
syn match kameOperator /|/ contained

" ---------------------------------------------------------------------------
" Strings, interpolation, and template expansions. Template items also match
" inside shell quoting, command substitution, and here-documents because Kame
" expands recipe text before the shell runs it.
" ---------------------------------------------------------------------------
syn region kameString start=/"/ skip=/\\./ end=/"/ contains=@kameTemplateGroup
syn region kameInterpolation matchgroup=kameInterpolationDelimiter start=/{(/ end=/)}/ contained contains=@kameValueGroup
execute 'syn region kameTemplateExpression matchgroup=kameTemplateDelimiter start=/@(/ end=/)/ contains=@kameValueGroup containedin=' . s:templateContexts
execute 'syn match kameTemplateReference /@{[^}]*}/ containedin=' . s:templateContexts
execute 'syn match kameSelectorInput /@<\%([*#]\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)\?/ contained containedin=' . s:templateContexts
execute 'syn match kameSelectorOutput /@>\%([*#]\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)\?/ contained containedin=' . s:templateContexts
execute 'syn match kameSelectorArgument /@\%(_\|\*\|#\|[+-]\?\d*\.\.[+-]\?\d*\|[+-]\?\d\+\)/ contained containedin=' . s:templateContexts
execute 'syn match kameEscape /\\[@\\{}]/ contained containedin=' . s:templateContexts

" ---------------------------------------------------------------------------
" Top-level directives.
" ---------------------------------------------------------------------------
syn keyword kameDirective include nextgroup=kameIncludePath skipwhite
syn match kameIncludePath /\%("[^"]*"\|[^ \t#]\+\)/ contained

" ---------------------------------------------------------------------------
" Line-level constructs. They are defined after the value atoms so that they
" win at the same start position (later definitions have priority), while the
" value atoms remain available through their "contains" lists.
" ---------------------------------------------------------------------------
syn match kameRuleHeader /^\%(\%(task\|service\)[ \t]\+\)\?\%(\[\|\/\/\)\@!\%([^ \t=(#]\S*\)\%([ \t]\+\S\+\)*[ \t]*:\%([ \t].*\)\?$/ contains=@kameHeaderGroup
syn match kameRuleSeparator /:/ contained

syn match kameDefinition /^[A-Za-z_][A-Za-z0-9_-]*[?!]\?[ \t]*=/ contains=kameDefinitionName,kameDefinitionOperator
syn match kameDefinitionName /^[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze[ \t]*=/ contained
syn match kameDefinitionOperator /=/ contained

syn match kameFunctionDefinition /^([^)\n]*)[ \t]*=/ contains=kameFunctionName,kameFunctionParameter,kameDefinitionOperator
syn match kameFunctionParameter /[^ \t()]\+/ contained
syn match kameFunctionName /^([ \t]*\zs[^ \t(]\+/ contained

syn region kameRecipe start=/^[ \t]\+/ end=/^\ze\S/ keepend contains=@kameShell,@kameRecipeGroup

syn match kameComment /^[ \t]*#.*$/ contains=@Spell
syn match kameComment /^[ \t]*\/\/.*$/ contains=@Spell

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
hi def link kamePath Directory
hi def link kameCapture Type
hi def link kameCaptureName Identifier
hi def link kameGlob SpecialChar
hi def link kameSpecialForm Statement
hi def link kameOperator Operator
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
hi def link kameDelimiter Delimiter

let b:current_syntax = 'kame'
