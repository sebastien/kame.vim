" Vim syntax file
" Language: Kame programs (.km, .kame, Kamefile), Kash actions (.kash, .ksh),
"           and Kame document templates (.kmt)
" Maintainer: Sebastien Pierre

if exists('b:current_syntax')
  finish
endif

syn case match

" ---------------------------------------------------------------------------
" Source layer. Detection sets b:kame_lang; fall back to the suffix or file name
" through kame#lang_of so `set filetype=kame` still works.
"   expr      Kame program: definitions, declarations, rules, expressions
"   kash      Kash program: the top level is an action block
"   template  document template: host text with @ directives and @{...}
" ---------------------------------------------------------------------------
let s:lang = get(b:, 'kame_lang', '')
if empty(s:lang)
  let s:lang = kame#lang_of(expand('%:p'))
endif
let s:kash_top = s:lang ==# 'kash'
let s:template = s:lang ==# 'template'

" Standard-library operations. Names contain '?', '!', and '-' characters that
" are not keyword characters, so this is a match rather than a `syn keyword`
" item. Reserved words (match, set, ...) are deliberately absent.
let s:stdlib = 'not\|bool\|str\|json\|parse-json\|fail!\|'
      \ . 'count\|get\|first\|nth\|list\|nop\|apply\|items\|put\|merge\|'
      \ . 'nil?\|bool?\|int?\|float?\|string?\|bytes?\|list?\|record?\|'
      \ . 'callable?\|resource?\|pattern?\|process?\|number?\|empty?\|'
      \ . 'has-key?\|success?\|blank?\|digest\|'
      \ . 'map\|flatmap\|filter\|filter-out\|in?\|reduce\|collect!\|concat\|'
      \ . 'slice\|sorted\|unique\|'
      \ . 'join\|split\|strip\|line\|subst\|sub-token\|match?\|includes?\|'
      \ . 'starts?\|ends?\|uppercase\|lowercase\|template-cat\|text\|render\|'
      \ . 'pattern\|regex-match\|capture\|bind\|regex-group\|resub\|'
      \ . 'basename\|dirname\|splitext\|ext\|joinpath\|relpath\|abspath\|'
      \ . 'wildcard\|files\|dirs\|now\|monotonic\|parse-args\|read\|exists?\|'
      \ . 'stat\|lstat\|readlink\|write!\|publish!\|sh!\|shell-template!\|tool\|'
      \ . 'resource\|out!\|err!\|eq?\|ne?\|lt?\|gt?\|lte?\|gte?\|'
      \ . 'add\|sub\|mul\|div\|mod\|neg\|black\|red\|green\|yellow\|blue\|'
      \ . 'magenta\|cyan\|white\|bold\|dim'

" Shared fragments.
let s:name = '[A-Za-z_][A-Za-z0-9_-]*[?!]\?'
let s:boundary = '\%([^A-Za-z0-9_-]\|$\)'
" A path atom: ./ ../ / ~/ or an interpolated head, then segments. Brace
" groups, wildcards and interpolations may appear inside.
let s:pathHead = '\%(\.\.\?\/\|[~]\/\|\%([A-Za-z0-9_-]\)\@<!\/\|@{[^{}]*}\/\)'
let s:pathSeg = '\%([^{}()\[\] \t,;|<>@\\]\+\|@{[^{}]*}\|@@\|\\\\.\|{[^{}]*}\|\[[^\]]*\]\)'
let s:templateKeywords = '\%(if\|elif\|else\|for\|with\|let\|include\|raw\|match\|case\|end\)'
" A command word starts with a letter, '.', '/', or '~'. Paths and references
" are redefined after it so they win at a shared start.
let s:commandWord = '[A-Za-z_.~/][^ \t|;&<>#"@$(:\[\]{}]*'
let s:stageStart = '\%(^[ \t]*\|\%(|\|;\|&&\|||\|(\|,\)[ \t]*\)'

" ---------------------------------------------------------------------------
" Value grammar. In a template only @{...} and directive operands hold Kame
" values, so every atom is `contained` there; in programs the same items also
" match at the top level.
" ---------------------------------------------------------------------------
function! s:DefineValues(contained) abort
  let c = a:contained ? ' contained' : ''
  let co = a:contained ? 'contained ' : ''

  " Strings. '@@' is a literal at-sign and '@{EXPR}' interpolates. Raw and
  " verbatim strings take no escapes or interpolation. In program text a double
  " quoted string also carries command-word $REFERENCE words, because recipes
  " are Kash action blocks.
  let extra = a:contained ? '' : ',kameKashReference,kameCommandSubstitution'
  execute 'syn region kameString ' . co . 'start=/"""/ end=/"""/ keepend contains=NONE'
  execute 'syn region kameString ' . co . 'start=/"\%(""\)\@!/ skip=/\\./ end=/"/ contains=kameEscape,kameTemplateInterpolation' . extra
  execute 'syn region kameString ' . co . "start=/'/ end=/'/ contains=NONE"

  " Inline interpolation is the one native inline template form. It stays
  " non-contained so it also matches at the top of a document template.
  syn region kameTemplateInterpolation matchgroup=kameTemplateDelimiter start=/@{/ end=/}/ contains=@kameValueGroup

  execute 'syn match kameEscape /@@\|\\\\./' . c

  " Numbers. A leading '-' directly before a digit belongs to the literal.
  execute 'syn match kameNumber /\%([0-9A-Za-z_-]\)\@<!-\?0[xX][0-9A-Fa-f]\%(_\?[0-9A-Fa-f]\)*\>/' . c
  execute 'syn match kameNumber /\%([0-9A-Za-z_-]\)\@<!-\?0[bB][01]\%(_\?[01]\)*\>/' . c
  execute 'syn match kameNumber /\%([0-9A-Za-z_-]\)\@<!-\?0[oO][0-7]\%(_\?[0-7]\)*\>/' . c
  execute 'syn match kameNumber /\%([0-9A-Za-z_-]\)\@<!-\?\d\%(_\?\d\)*\%(\.\d\%(_\?\d\)*\)\?\%([eE][+-]\?\d\%(_\?\d\)*\)\?\>/' . c

  " Literals and names.
  execute 'syn match kameSymbol /\%([A-Za-z0-9_-]\)\@<!:[+-]\?' . s:name . '/' . c
  execute 'syn match kameVariable /\<[A-Z][A-Z0-9_]*\ze' . s:boundary . '/' . c
  execute 'syn match kameName /\<' . s:name . '\ze' . s:boundary . '/' . c
  execute 'syn match kameFunctionCall /\<[a-z][A-Za-z0-9_-]*[?!]\?\ze' . s:boundary . '/' . c
  execute 'syn match kameStdlibFunction /\<\%(' . s:stdlib . '\)\ze' . s:boundary . '/' . c
  execute 'syn match kameBoolean /\<\%(true\|false\|nil\)\ze' . s:boundary . '/' . c
  execute 'syn match kamePlaceholder /_\{2,}\ze\%([^A-Za-z0-9_]\|$\)/' . c
  execute 'syn match kamePlaceholder /_\d\+\ze\%([^A-Za-z0-9_]\|$\)/' . c
  execute 'syn match kamePlaceholder /_\ze\%([^A-Za-z0-9_]\|$\)/' . c

  " Pattern captures live only inside path atoms.
  syn region kameCapture start=/\%(@\)\@<!{/ end=/}/ contained contains=kameCaptureName,kameCapturePattern,kameCaptureRegex,kameCaptureDefault
  syn match kameCaptureName /[A-Za-z_][A-Za-z0-9_-]*\ze\%([:=}]\|$\)/ contained
  syn match kameCapturePattern /:\zs\%([*?]\+\|\*\*\)\ze}/ contained
  syn match kameCapturePattern /\%({\)\@<=[*?]\+\ze}/ contained
  syn match kameCaptureDefault /=\zs[^}]*/ contained
  syn match kameCaptureRegex /:\zs[~][^}]*/ contained

  " Records, lists, and grouped expressions.
  execute 'syn region kameList matchgroup=kameDelimiter ' . co . 'start=/\[/ end=/\]/ contains=@kameValueGroup'
  execute 'syn region kameExpression matchgroup=kameDelimiter ' . co . 'start=/(/ end=/)/ contains=@kameValueGroup'
  execute 'syn region kameRecord ' . co . 'start=/{/ end=/}/ contains=kameRecordKey,@kameValueGroup'
  syn match kameRecordKey /\<[A-Za-z_][A-Za-z0-9_-]*\ze[ \t]*:/ contained

  " Operators. '=' is never an expression operator: definitions use '=',
  " lambdas use '=>', and comparisons use '=='.
  execute 'syn match kameLambdaOperator /=>/' . c
  execute 'syn match kameSpreadOperator /\.\.\./' . c
  execute 'syn match kameOperator /[+*%]/' . c
  execute 'syn match kameOperator /\%([ \t(]\)\@<=-\ze\%([ \t)]\|$\)/' . c
  execute 'syn match kameOperator /\%([ \t(]\)\@<=\/\ze\%([ \t)]\|$\)/' . c
  execute 'syn match kameComparisonOperator /==\|!=\|<=\|>=\|<\|>/' . c
  execute 'syn match kameLogicalOperator /\<\%(and\|or\)\ze' . s:boundary . '/' . c
  execute 'syn match kameValuePipe /|>/' . c
  execute 'syn match kameFallbackOperator /??/' . c
endfunction

" ---------------------------------------------------------------------------
" Reserved words. Defined after command heads so they win at a shared start.
" ---------------------------------------------------------------------------
function! s:DefineKeywords(contained) abort
  let c = a:contained ? ' contained' : ''
  execute 'syn match kameKeyword /\<\%(def\|let\|set\|generate\|if\|then\|elif\|else\|match\|for\|in\|while\|break\|continue\|return\|yield\|exit\|defer\|with\|stream\|sep\)\ze' . s:boundary . '/' . c
  execute 'syn match kameDirective /\<\%(include?\=\|import\|export\|from\|as\)\ze' . s:boundary . '/' . c
endfunction

" ---------------------------------------------------------------------------
" Path atoms and references. Defined after command heads so './x' and 'x/uv'
" keep their location spelling instead of becoming executables.
" ---------------------------------------------------------------------------
function! s:DefineLocations(contained) abort
  let c = a:contained ? ' contained' : ''
  execute 'syn match kamePath /' . s:pathHead . s:pathSeg . '\+/' . c . ' contains=kameTemplateInterpolation,kameCapture,kameEscape'
  execute 'syn match kameReference /\<' . s:name . '\%(\/\%(' . s:name . '\|"[^"]*"\)\%(\.[A-Za-z0-9_-]\+\|\."[^"]*"\)*\|\.\%([A-Za-z0-9_-]\+\|"[^"]*"\)\%(\.[A-Za-z0-9_-]\+\|\."[^"]*"\)*\)[?!]\?/' . c
endfunction

syn cluster kameValueGroup contains=kameExpression,kameList,kameRecord,kameString,kameNumber,kameBoolean,kameSymbol,kameVariable,kameName,kameFunctionCall,kameStdlibFunction,kameReference,kamePlaceholder,kamePath,kameOperator,kameComparisonOperator,kameLambdaOperator,kameSpreadOperator,kameLogicalOperator,kameValuePipe,kameFallbackOperator,kameCommandSubstitution,kameTemplateInterpolation,kameEscape,kameKeyword,kameDirective

" ---------------------------------------------------------------------------
" Document template layer (.kmt). Host text is literal; only @ directives and
" @{EXPR} are Kame. There are no comments: '#' is document text.
" ---------------------------------------------------------------------------
if s:template
  call s:DefineValues(1)
  call s:DefineKeywords(1)
  call s:DefineLocations(1)

  " Directive regions. A directive is keyword-gated. Plain style recognizes a
  " whole line; comment styles also accept a complete inline directive comment.
  let s:tplPrefix = '\%(^[ \t]*\|<!--\s*\|' . '\/\*\s*' . '\|' . '\/\/\s*' . '\|<#\s*\|REM\s*\|::\s*\|#\s*\|--\s*\|;\s*\|%\s*\)'
  execute 'syn region kameTemplateDirective matchgroup=kameTemplateDirective start=/' . s:tplPrefix . '\@<=@-\?' . s:templateKeywords . '\>/ end=/\n/ contains=@kameValueGroup,kameTemplateDirectiveLabel,kameTemplateTrim'
  syn match kameTemplateDirectiveLabel /\%(@-\?end[ \t]\+\)\@<=\%(if\|for\|with\|match\|raw\)\>/ contained
  syn match kameTemplateTrim /[ \t]\zs-\ze[ \t]*\%(-->\|#>\|\*\/\|$\)/ contained

  " @raw bodies are literal through @end (or @end raw).
  execute 'syn region kameTemplateRaw matchgroup=kameTemplateDirective start=/' . s:tplPrefix . '\@<=@-\?raw\>/ end=/' . s:tplPrefix . '\@<=@-\?end\%([ \t]\+\%(raw\)\?\)\?\%([ \t]*-\)\?/ keepend contains=NONE'

  " The escape at a directive position: @@ emits a literal at-sign.
  syn match kameEscape /\%(^[ \t]*\)\@<=@@/

  hi def link kameTemplateDirective PreProc
  hi def link kameTemplateDirectiveLabel Keyword
  hi def link kameTemplateTrim SpecialChar
  hi def link kameTemplateInterpolation Special
  hi def link kameTemplateDelimiter Special
  hi def link kameEscape SpecialChar
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
  hi def link kameCaptureRegex SpecialChar
  hi def link kameCaptureDefault String
  hi def link kameKeyword Statement
  hi def link kameDirective Include
  hi def link kameLogicalOperator Operator
  hi def link kameOperator Operator
  hi def link kameComparisonOperator Operator
  hi def link kameLambdaOperator Operator
  hi def link kameSpreadOperator Operator
  hi def link kameValuePipe Operator
  hi def link kameFallbackOperator Operator
  hi def link kameString String
  hi def link kameCommandSubstitution Special
  hi def link kameCommandSubstitutionDelimiter Special
  hi def link kameDelimiter Delimiter

  let b:current_syntax = 'kame'
  finish
endif

" ---------------------------------------------------------------------------
" Programs and Kash actions.
" ---------------------------------------------------------------------------
call s:DefineValues(0)

" Comments start with '#'. '//' is not a comment in revision 2.
syn match kameComment /\%(^\|[ \t]\)\zs#.*$/ contains=@Spell

" Command substitutions: $(COMMAND), $?(COMMAND), and $&(COMMAND).
syn region kameCommandSubstitution matchgroup=kameCommandSubstitutionDelimiter start=/\$[?&]\?(/ end=/)/ contains=@kameAction

" ---------------------------------------------------------------------------
" Action (Kash) syntax. This section comes before declarations and keywords so
" those later items win at a shared start position.
" ---------------------------------------------------------------------------
" $REFERENCE, ${REFERENCE}, $...REFERENCE, and $...{REFERENCE}.
syn match kameKashReference /\$\%(\.\.\.\)\?{[^{}]*\%({[^{}]*}[^{}]*\)*}/
syn match kameKashReference /\$\%(\.\.\.\)\?[A-Za-z_][A-Za-z0-9_-]*\%(\.[A-Za-z0-9_-]\+\|\."[^"]*"\)*[?!]\?/

" Quoted command words use the shared kameString region, which carries
" $REFERENCE and @{...}; no separate region is needed.

let s:setupValue = '\%(([^)]*)\|[^ \t]\+\)'
let s:setupPair = '[A-Za-z_][A-Za-z0-9_]*:[ \t]\+' . s:setupValue . '[ \t]\+'

" Executables: the first word of a stage, after setup pairs, and after a
" process or graph operator. Assignments and keywords win over this match.
execute 'syn match kameKashCommand /^[ \t]*\zs' . s:commandWord . '/'
execute 'syn match kameKashCommand /\%(\%([|;(]\|&&\|||\|,\)[ \t]*\)\@<=' . s:commandWord . '/'
execute 'syn match kameKashCommand /\%(' . s:stageStart . '\%(' . s:setupPair . '\)\+\)\@<=' . s:commandWord . '/'
execute 'syn match kameKashCommand /\%(^[ \t]*defer[ \t]\+\)\@<=' . s:commandWord . '/'
execute 'syn match kameKashCommand /\%(|(\%([^)]*)\)[ \t]*\)\@<=' . s:commandWord . '/'
execute 'syn match kameKashCommand /\%(\$[?&]?(\s*\)\@<=' . s:commandWord . '/'
syn match kameKashOption /\%(^\|[ \t]\)\zs-\{1,2\}[A-Za-z][A-Za-z0-9-]*/

" Stage setup pairs: cwd:, timeout:, env:, accept-exit:, tty:, foreground:,
" and arbitrary KEY: environment overrides.
execute 'syn match kameKashSetup /' . s:stageStart . '\zs\%(' . s:setupPair . '\)\+/ contains=kameKashSetupKey'
syn match kameKashSetupKey /[A-Za-z_][A-Za-z0-9_]*\ze:/ contained
syn match kameKashSetupKey /\%(^[ \t]*with[^\n]*\)\@<=[A-Za-z_][A-Za-z0-9_]*\ze:/

" Explicit graph operators: |(merge), |(frame :lines), |(tee PATH), ...
syn region kameKashMuxRegion matchgroup=kameDelimiter start=/\%(|\)\@<=(/ end=/)/ contains=kameKashMux,kameKashMuxKey,kameNumber,kameBoolean,kameSymbol
syn match kameKashMux /\<\%(merge\|broadcast\|balance\|tee\|frame\|filter\|encode\|each\)\>/ contained
syn match kameKashMuxKey /:[A-Za-z_][A-Za-z0-9_-]*/ contained

" Process operators. Longer spellings are defined after shorter ones.
syn match kameKashPipeline /|\%(>\)\@!/
syn match kameKashSeparator /;/
syn match kameKashRedirection /</
syn match kameKashRedirection />/
syn match kameKashRedirection />>/
syn match kameKashRedirection /2>/
syn match kameKashRedirection /2>>/
syn match kameKashRedirection /2>&1/
syn match kameKashRedirection />@/
syn match kameKashRedirection />&/
syn match kameKashChannel />&[A-Za-z_][A-Za-z0-9_-]*/
syn match kameKashChannel /<&[A-Za-z_][A-Za-z0-9_-]*/
syn match kameKashChannel /<&/
syn match kameKashChannel /&[A-Za-z_][A-Za-z0-9_-]*/
syn match kameKashAcceptance /?/
syn match kameKashAsync /&/
syn match kameKashSequential /&&\|||/

" The value fallback is the same token in expressions and action operands.
syn match kameFallbackOperator /??/

" Builtins that have no standard-library counterpart in command position.
syn match kameKashBuiltin /\<\%(cd\|wait\|kill\|jobs\|fg\|bg\|alias\|unalias\|history\|option\|explain\)\ze[ \t]/
syn match kameKashBuiltin /\<\%(out!\|err!\)\ze[ \t]/

" A parenthesized comma group is a process group. A value group never
" contains a top-level comma, so this cannot hide an expression.
syn region kameKashProcessGroup matchgroup=kameDelimiter start=/\%(|\)\@<!(\ze\%([^()"]\|"[^"]*"\)*,\%([^()"]\|"[^"]*"\)*)/ end=/)/ contains=@kameAction

" Action cluster, used by command substitutions and process groups.
syn cluster kameAction contains=@kameValueGroup,kameKashBuiltin,kameKashCommand,kameKashOption,kameKashSetup,kameKashSetupKey,kameKashPipeline,kameKashSeparator,kameKashRedirection,kameKashChannel,kameKashAcceptance,kameKashAsync,kameKashSequential,kameKashReference,kameKashMuxRegion,kameComment,kameRuleHeader,kameDefinition,kameKashStreamName,kameKashLoopName

" ---------------------------------------------------------------------------
" Reserved words and declaration keywords.
" ---------------------------------------------------------------------------
call s:DefineKeywords(0)

" Binding names in Kash statements.
syn match kameDefinitionName /\%(^[ \t]*\%(let\|set\)[ \t]\+\)\@<=[A-Za-z_][A-Za-z0-9_-]*\%(\/[A-Za-z_][A-Za-z0-9_-]*\)\?[?!]\?/
syn match kameKashStreamName /\%(^[ \t]*stream[ \t]\+\)\@<=[A-Za-z_][A-Za-z0-9_-]*/
syn match kameKashLoopName /\%(^[ \t]*for[ \t]\+\)\@<=[A-Za-z_][A-Za-z0-9_-]*/

" ---------------------------------------------------------------------------
" Rule, task, and service headers. The region gives ':' , ';' and the header
" separators a context; paths, captures, interpolations and metadata records
" keep their own items.
" ---------------------------------------------------------------------------
let s:ruleStart = '^[ \t]*\zs\%(rule\|task\|service\)\>'
syn match kameRuleKeyword /\<\%(rule\|task\|service\)\ze[ \t]/
execute 'syn region kameRuleHeader matchgroup=kameRuleKeyword start=/' . s:ruleStart . '/ end=/$/ contains=kameRuleModifier,kameRuleSeparator,kameRuleOrderOnly,kameRuleGroupSeparator,kameRuleBodyOperator,kameTargetName,@kameValueGroup,kameComment'
syn match kameRuleModifier /\%(^[ \t]*\%(rule\|task\)[ \t]\+\)\@<=\%(always\|cached\)\>/ contained
syn match kameRuleSeparator /[:;]/ contained
syn match kameRuleOrderOnly /|/ contained
syn match kameRuleGroupSeparator /,/ contained
syn match kameRuleBodyOperator /=/ contained
syn match kameTargetName /\%(^[ \t]*\%(task\|service\)[ \t]\+\)\@<=\%(cached\>\)\@![A-Za-z_][A-Za-z0-9_-]*[?!]\?/ contained
syn match kameTargetName /\%(^[ \t]*task[ \t]\+cached[ \t]\+\)\@<=[A-Za-z_][A-Za-z0-9_-]*[?!]\?/ contained

" ---------------------------------------------------------------------------
" Definitions. 'NAME =', 'NAME ?=', and 'NAME +=' are lazy top-level values;
" 'def NAME PARAM...' declares a function; 'let' and 'set' bind in a block.
" ---------------------------------------------------------------------------
syn match kameDefinition /^[ \t]*[A-Za-z_][A-Za-z0-9_-]*[?!]\?[ \t]*\%(=\%([=>]\)\@!\|?=\|+=\)/ contains=kameDefinitionName,kameDefinitionOperator
syn match kameDefinitionName /^[ \t]*[A-Za-z_][A-Za-z0-9_-]*[?!]\?\ze[ \t]*\%(=\%([=>]\)\@!\|?=\|+=\)/ contained
syn match kameDefinitionOperator /\%(=\%([=>]\)\@!\|?=\|+=\)/ contained
syn match kameDefinitionName /\%(^[ \t]*\%(def\|let\|set\)[ \t]\+\)\@<=[A-Za-z_][A-Za-z0-9_-]*\%(\/[A-Za-z_][A-Za-z0-9_-]*\)\?[?!]\?/
syn match kameDefinitionOperator /\%([ \t]\)\@<==\%([=>]\)\@!/
syn match kameFunctionName /\%(^[ \t]*def[ \t]\+\)\@<=[A-Za-z_][A-Za-z0-9_-]*[?!]\?/
syn match kameFunctionParameter /\%(^[ \t]*def[ \t]\+\S\+[ \t]\+\)\@<=[^ \t=#]\+\%([ \t]\+[^ \t=#]\+\)*/

" Paths and references win over command heads.
call s:DefineLocations(0)

" ---------------------------------------------------------------------------
" Template directives also appear in foreign-shell recipe bodies.
" ---------------------------------------------------------------------------
let s:tplPrefix = '\%(^[ \t]*\|<!--\s*\|' . '\/\*\s*' . '\|' . '\/\/\s*' . '\|<#\s*\|REM\s*\|::\s*\|#\s*\|--\s*\|;\s*\|%\s*\)'
execute 'syn region kameTemplateDirective matchgroup=kameTemplateDirective start=/' . s:tplPrefix . '\@<=@-\?' . s:templateKeywords . '\>/ end=/\n/ contains=@kameValueGroup,kameTemplateDirectiveLabel,kameTemplateTrim'
syn match kameTemplateDirectiveLabel /\%(@-\?end[ \t]\+\)\@<=\%(if\|for\|with\|match\|raw\)\>/
syn match kameTemplateTrim /[ \t]\zs-\ze[ \t]*\%(-->\|#>\|\*\/\|$\)/
execute 'syn region kameTemplateRaw matchgroup=kameTemplateDirective start=/' . s:tplPrefix . '\@<=@-\?raw\>/ end=/' . s:tplPrefix . '\@<=@-\?end\%([ \t]\+\%(raw\)\?\)\?\%([ \t]*-\)\?/ keepend contains=NONE'
" The escape at a directive position: @@ emits a literal at-sign.
syn match kameEscape /\%(^[ \t]*\)\@<=@@/

" ---------------------------------------------------------------------------
" Embedded shell recipes. A foreign shell renders the body as a document
" template; Kash recipes use the action grammar above unchanged.
" ---------------------------------------------------------------------------
let s:recipe = get(g:, 'kame_recipe_lang', '')
let s:recipe_explicit = !empty(s:recipe) || get(g:, 'kame_no_shell_syntax', 0)
if empty(s:recipe)
  let s:recipe = get(g:, 'kame_no_shell_syntax', 0) ? 'none' : 'kash'
elseif s:recipe !=# 'kash' && s:recipe !=# 'shell' && s:recipe !=# 'none'
  let s:recipe = 'kash'
endif
if !s:recipe_explicit
  for s:line in getline(1, '$')
    if s:line =~# '^\s*SHELL\s*=\s*["'']\?kash["'']\?\s*$'
      let s:recipe = 'kash'
      break
    elseif s:line =~# '^\s*SHELL\s*=\s*["'']\?[^"'']'
      let s:recipe = 'shell'
      break
    endif
  endfor
  unlet! s:line
endif

if s:recipe ==# 'shell'
  syn include @kameShell syntax/sh.vim
  unlet! b:current_syntax
  syn region kameRecipe start=/^[ \t]\+/ end=/^\ze\S/ keepend contains=@kameShell,kameTemplateDirective,kameTemplateRaw,kameTemplateInterpolation,kameEscape,kameComment
elseif s:recipe ==# 'none'
  syn region kameRecipe start=/^[ \t]\+/ end=/^\ze\S/ keepend contains=NONE
endif

" ---------------------------------------------------------------------------
" Highlighting.
" ---------------------------------------------------------------------------
hi def link kameComment Comment
hi def link kameDirective Include
hi def link kameDefinitionName Define
hi def link kameDefinitionOperator Operator
hi def link kameFunctionName Function
hi def link kameFunctionParameter Identifier
hi def link kameTargetName Function
hi def link kameRuleKeyword Keyword
hi def link kameRuleModifier Keyword
hi def link kameRuleSeparator Operator
hi def link kameRuleOrderOnly Operator
hi def link kameRuleGroupSeparator Delimiter
hi def link kameRuleBodyOperator Operator
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
hi def link kameCaptureRegex SpecialChar
hi def link kameCaptureDefault String
hi def link kameKeyword Statement
hi def link kameLogicalOperator Operator
hi def link kameOperator Operator
hi def link kameComparisonOperator Operator
hi def link kameLambdaOperator Operator
hi def link kameSpreadOperator Operator
hi def link kameValuePipe Operator
hi def link kameFallbackOperator Operator
hi def link kameString String
hi def link kameTemplateInterpolation Special
hi def link kameTemplateDelimiter Special
hi def link kameTemplateDirective PreProc
hi def link kameTemplateDirectiveLabel Keyword
hi def link kameTemplateTrim SpecialChar
hi def link kameEscape SpecialChar
hi def link kameCommandSubstitution Special
hi def link kameCommandSubstitutionDelimiter Special
hi def link kameKashBuiltin Function
hi def link kameKashCommand Function
hi def link kameKashOption Identifier
hi def link kameKashSetupKey Keyword
hi def link kameKashPipeline Operator
hi def link kameKashSeparator Delimiter
hi def link kameKashRedirection Operator
hi def link kameKashChannel Special
hi def link kameKashAcceptance Operator
hi def link kameKashAsync Operator
hi def link kameKashSequential Operator
hi def link kameKashMux Operator
hi def link kameKashMuxKey Keyword
hi def link kameKashReference Identifier
hi def link kameKashStreamName Special
hi def link kameKashLoopName Identifier
hi def link kameDelimiter Delimiter

let b:current_syntax = 'kame'
