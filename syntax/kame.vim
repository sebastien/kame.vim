" Vim syntax file
" Language: Kame build language
" Maintainer: Sebastien Pierre

if exists("b:current_syntax")
  finish
endif

syn case match

" Comments are recognized only when they are the first non-whitespace text.
syn match kameComment /^\s*#.*$/ contains=@Spell
syn match kameComment /^\s*\/\/.*$/ contains=@Spell
hi def link kameComment Comment

" Top-level directives, rule modifiers, and definition operators.
syn keyword kameDirective include
syn keyword kameRuleKind task service
syn keyword kameSpecialForm def let eval
syn match kameDefinition /^[A-Za-z_][A-Za-z0-9_-]*\s*=/ contains=kameDefinitionOperator
syn match kameFunctionDefinition /^([A-Za-z_][A-Za-z0-9_-]*\>[^)]*)\s*=/ contains=kameDefinitionOperator
syn match kameDefinitionOperator /=/ contained
syn match kameRuleOperator /:/
hi def link kameDirective Include
hi def link kameRuleKind Keyword
hi def link kameSpecialForm Statement
hi def link kameDefinition Define
hi def link kameFunctionDefinition Define
hi def link kameDefinitionOperator Operator
hi def link kameRuleOperator Operator

" Expression values and names.
syn match kameSymbol /:\%(true\|false\|nil\)\>/
syn match kameNumber /\<\d\+\%(\.\d\+\%([eE][+-]\?\d\+\)\?\|[eE][+-]\?\d\+\)\?\>/
syn match kameNumber /\<0[xX][0-9A-Fa-f]\%(_\?[0-9A-Fa-f]\)*\>/
syn match kameNumber /\<0[bB][01]\%(_\?[01]\)*\>/
syn match kameName /\<[A-Za-z_][A-Za-z0-9_-]*[?!]\?\>/
hi def link kameBoolean Boolean
hi def link kameSymbol Constant
hi def link kameNumber Number
hi def link kameName Identifier

" Strings and their template expansions.
syn region kameString start=/"/ skip=/\\./ end=/"/ contains=kameTemplateExpression,kameTemplateReference,kameEscape
syn region kameTemplateExpression matchgroup=kameTemplateDelimiter start=/@(/ end=/)/ contains=kameString,kameNumber,kameSymbol,kameName,kameOperator,kameList,kameTemplateExpression
syn match kameTemplateReference /@{[^}]*}/
syn match kameEscape /\\[@\\]/ contained
hi def link kameString String
hi def link kameTemplateExpression Special
hi def link kameTemplateReference PreProc
hi def link kameTemplateDelimiter Special
hi def link kameEscape SpecialChar

" Lisp-like expressions, lists, and operators.
syn region kameExpression matchgroup=kameDelimiter start=/(/ end=/)/ contains=ALLBUT,kameComment
syn region kameList matchgroup=kameDelimiter start=/\[/ end=/\]/ contains=ALLBUT,kameComment
syn match kameOperator /[|]/ contained
hi def link kameExpression Function
hi def link kameList Type
hi def link kameDelimiter Delimiter
hi def link kameOperator Operator

" Target-template captures and glob syntax.
syn region kameCapture start=/{/ end=/}/ contains=kameCaptureName,kameGlob
syn match kameCaptureName /{\zs[A-Za-z_][A-Za-z0-9_-]*\ze\%(:\|}\)/ contained
syn match kameGlob /\*\*\?/ contained
syn match kameGlob /?/ contained
syn match kameGlob /\[[^]]*\]/ contained
hi def link kameCapture Type
hi def link kameCaptureName Identifier
hi def link kameGlob SpecialChar

" Contextual template selectors used in recipes and function definitions.
syn match kameSelector /@<[#*]\?\%([0-9]\+\|[0-9]*\.\.[0-9]*\)\?/
syn match kameSelector /@>[#*]\?\%([0-9]\+\|[0-9]*\.\.[0-9]*\)\?/
syn match kameSelector /@[_*#]\|@[0-9]\+\|@[0-9]*\.\.[0-9]*/
hi def link kameSelector PreProc

" Indented lines are rule recipes; retain highlighting for Kame interpolations.
syn match kameRecipe /^\s\+.*$/ contains=kameSelector,kameTemplateExpression,kameTemplateReference,kameString,kameEscape

let b:current_syntax = "kame"
