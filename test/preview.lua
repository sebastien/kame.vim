-- Render the current buffer with Neovim highlight colors as terminal ANSI,
-- then show every kame* group in its own style.
-- Driven by test/preview.sh; output goes to stdout.

vim.cmd("set termguicolors")

-- The preview must exercise the Kame syntax from this checkout, but the user's
-- configuration owns filetype detection and can defeat it: vim-polyglot clears
-- Vim's 'filetypedetect' group (which also disables Neovim's vim.filetype
-- matcher), and a separately installed Kame copy may claim a suffix first. A
-- .kash buffer then reaches this point with no filetype at all, while the other
-- suffixes only lose b:kame_lang (the syntax still falls back to the path).
-- Resolve the layer here, record it the way detection would, and make sure the
-- Kame syntax is loaded.
local preview_file = vim.fn.expand('%:p')
if preview_file ~= '' then
  if vim.fn['kame#is_ktmpl'](preview_file) == 1 then
    vim.b.kame_lang = 'template'
    vim.b.kame_host = vim.fn['kame#host_of'](preview_file)
    vim.b.kame_host_syntax = vim.fn['kame#host_syntax'](preview_file)
  else
    vim.b.kame_lang = vim.fn['kame#lang_of'](preview_file)
  end
  if vim.bo.filetype ~= 'kame' then
    vim.bo.filetype = 'kame'
  end
end

local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function ansi_for(trans_id)
  local parts = {}
  local fg = vim.fn.synIDattr(trans_id, "fg#")
  if fg ~= "" then
    local r, g, b = hex_to_rgb(fg)
    if r then
      table.insert(parts, string.format("38;2;%d;%d;%d", r, g, b))
    end
  end
  local bg = vim.fn.synIDattr(trans_id, "bg#")
  if bg ~= "" then
    local r, g, b = hex_to_rgb(bg)
    if r then
      table.insert(parts, string.format("48;2;%d;%d;%d", r, g, b))
    end
  end
  if vim.fn.synIDattr(trans_id, "bold") == "1" then
    table.insert(parts, "1")
  end
  if vim.fn.synIDattr(trans_id, "italic") == "1" then
    table.insert(parts, "3")
  end
  if vim.fn.synIDattr(trans_id, "underline") == "1" then
    table.insert(parts, "4")
  end
  if #parts == 0 then
    return ""
  end
  return "\27[" .. table.concat(parts, ";") .. "m"
end

local function render_line(lnum)
  local text = vim.fn.getline(lnum)
  if text == "" then
    return ""
  end
  local chunks = {}
  local col = 1
  local width = #text
  while col <= width do
    local trans = vim.fn.synIDtrans(vim.fn.synID(lnum, col, 1))
    local start = col
    while col + 1 <= width and vim.fn.synIDtrans(vim.fn.synID(lnum, col + 1, 1)) == trans do
      col = col + 1
    end
    local chunk = text:sub(start, col)
    local ansi = ansi_for(trans)
    if ansi ~= "" then
      table.insert(chunks, ansi .. chunk .. "\27[0m")
    else
      table.insert(chunks, chunk)
    end
    col = col + 1
  end
  return table.concat(chunks)
end

-- Every linked kame group with its default link and a representative sample.
-- Samples are forced to the group's own colors, not re-parsed.
local groups = {
  { "kameComment", "Comment", "# comment  // comment" },
  { "kameDirective", "Include", "include" },
  { "kameIncludePath", "Directory", "./rules/common.kmk" },
  { "kameRuleKind", "Keyword", "task  service" },
  { "kameRuleSeparator", "Operator", ":" },
  { "kameTargetName", "Function", "default  cached" },
  { "kamePath", "Directory", "./build/app  ../dist  /tmp/stage" },
  { "kameCapture", "Type", "{name}  {**}" },
  { "kameCaptureName", "Identifier", "name  _0" },
  { "kameCapturePattern", "SpecialChar", "{name:*}  {**:*}" },
  { "kameSymbol", "Constant", ":my-symbol" },
  { "kameBoolean", "Boolean", ":true  :false  :nil" },
  { "kameNumber", "Number", "1_000  -3.5  0xFF  0b1010  0o755" },
  { "kameName", "Identifier", "wildcard  count" },
  { "kameReference", "Identifier", "project.name  files.1..4  config.{host,port}" },
  { "kamePlaceholder", "Special", "_  __  _0  _12" },
  { "kameRecordKey", "Identifier", "name:  path:" },
  { "kameSpecialForm", "Statement", "def  let  eval  if  and  or  match  with" },
  { "kameOperator", "Operator", "|" },
  { "kameComparisonOperator", "Operator", "=  ==  !=  <  >  <=  >=" },
  { "kameDelimiter", "Delimiter", "(  [  ]  )" },
  { "kameString", "String", '"building @(count SOURCES)"' },
  { "kameInterpolation", "Special", "{(VERSION)}" },
  { "kameInterpolationDelimiter", "Special", "{(  )}" },
  { "kameTemplateExpression", "Special", "@(count SOURCES)" },
  { "kameTemplateDelimiter", "Special", "@(  )" },
  { "kameTemplateReference", "PreProc", "@{TARGET}" },
  { "kameSelectorInput", "Special", "@<  @<*  @<#  @<2" },
  { "kameSelectorOutput", "PreProc", "@>  @>*  @>#  @>2" },
  { "kameSelectorArgument", "Identifier", "@_  @*  @#  @1" },
  { "kameEscape", "SpecialChar", "\\@  \\\\  \\{  \\}" },
  { "kameCommandSubstitution", "Special", "$(git rev-parse)" },
  { "kameCommandSubstitutionDelimiter", "Special", "$(  )" },
  { "kameRecipeDirective", "PreProc", "@if  @else  @end  @raw" },
  { "kameKashKeyword", "Conditional", "if  elif  else  match  case" },
  { "kameKashCommand", "Function", "git  build  cc" },
  { "kameKashOption", "Identifier", "-c  --watch  -O2" },
  { "kameKashSetupKey", "Keyword", ":cwd  :timeout  :NODE_ENV" },
  { "kameKashPipeline", "Operator", "|" },
  { "kameKashRedirection", "Operator", "<  >  >>" },
  { "kameKashAcceptance", "Operator", "?" },
  { "kameKashRecovery", "Operator", "??" },
  { "kameKashAsync", "Operator", "&" },
  { "kameKashSeparator", "Delimiter", ";" },
  { "kameKashMeta", "PreProc", "@NAME  @tmpl(...)" },
  { "kameKashReference", "Identifier", "$ref  ${ref}  $project.name" },
  { "kameKashString", "String", '"$title  $(date)"' },
  { "kameDefinitionName", "Define", "VERSION  FLAG!" },
  { "kameDefinitionOperator", "Operator", "=" },
  { "kameFunctionName", "Function", "source" },
  { "kameFunctionParameter", "Identifier", "object" },
}

local containers = {
  { "kameRuleHeader", "header line container" },
  { "kameRecipe", "indented recipe container" },
  { "kameExpression", "( ... ) container" },
  { "kameList", "[ ... ] container" },
  { "kameDefinition", "NAME = ... container" },
  { "kameFunctionDefinition", "(args) = ... container" },
}

local function colored(group, text)
  local trans = vim.fn.synIDtrans(vim.fn.hlID(group))
  local ansi = ansi_for(trans)
  if ansi == "" then
    return text
  end
  return ansi .. text .. "\27[0m"
end

local out = {}
local function emit(s)
  table.insert(out, s)
end

-- preview.sh sets g:kame_preview_section (the human label, e.g. "rule") and
-- g:kame_preview_single (1 for an explicit file argument, 0 for the all-types
-- run). The layer comes from the buffer, so a section never has to repeat the
-- suffix -> layer mapping.
local section = vim.g.kame_preview_section
local single = vim.g.kame_preview_single == 1
if section and section ~= '' then
  emit("== " .. section .. " ==")
  emit("")
end

local shown = vim.fn.expand("%:p")
if shown == "" then
  shown = "[No Name]"
end
local rel = vim.fn.fnamemodify(shown, ":t")
local layer = vim.b.kame_lang
if layer == nil or layer == '' then
  layer = "?"
end
-- Recipe language resolves exactly like syntax/kame.vim: g:kame_recipe_lang
-- wins, else the legacy g:kame_no_shell_syntax, else kash.
local recipe_lang = vim.g.kame_recipe_lang
if recipe_lang == nil or recipe_lang == '' then
  recipe_lang = vim.g.kame_no_shell_syntax == 1 and 'none' or 'kash'
elseif recipe_lang ~= 'kash' and recipe_lang ~= 'shell' and recipe_lang ~= 'none' then
  recipe_lang = 'kash'
end
-- Only the rule layer has recipes, so only it reports a recipe language.
local detail = "layer " .. layer
if layer == 'rule' then
  detail = detail .. ", recipe " .. recipe_lang
elseif layer == 'template' and vim.b.kame_host and vim.b.kame_host ~= '' then
  detail = detail .. ", host " .. vim.b.kame_host
end
if vim.g.kame_preview_body ~= 0 then
  if not single then
    emit("File: " .. rel .. " (" .. detail .. ")")
    emit("")
  end
  for lnum = 1, vim.fn.line("$") do
    emit(render_line(lnum))
  end
end

if vim.g.kame_preview_legend ~= 0 then
  emit("")
  emit("Kame highlight groups (sample in its own style):")
  emit("")
  for _, g in ipairs(groups) do
    local name, link, sample = g[1], g[2], g[3]
    emit(string.format("  %-26s %-12s %s", name, "(" .. link .. ")", colored(name, sample)))
  end

  emit("")
  emit("Containers (no highlight, stay uncolored):")
  emit("")
  for _, c in ipairs(containers) do
    emit(string.format("  %-26s %s", c[1], c[2]))
  end
end

io.stdout:write(table.concat(out, "\n") .. "\n")
