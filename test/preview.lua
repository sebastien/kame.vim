-- Render the current buffer with Neovim highlight colors as terminal ANSI,
-- then show every kame* group in its own style.
-- Driven by test/preview.sh; output goes to stdout.

vim.cmd("set termguicolors")

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
  { "kameGlob", "SpecialChar", "*  **  ?  [0-9]" },
  { "kameSymbol", "Constant", ":my-symbol" },
  { "kameBoolean", "Boolean", ":true  :false  :nil" },
  { "kameNumber", "Number", "1_000  -3.5  0xFF  0b1010  0o755" },
  { "kameName", "Identifier", "wildcard  count" },
  { "kameRecordKey", "Identifier", "name:  path:" },
  { "kameSpecialForm", "Statement", "def  let  eval  ?" },
  { "kameOperator", "Operator", "|" },
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

local shown = vim.fn.expand("%:p")
if shown == "" then
  shown = "[No Name]"
end
local shell = vim.g.kame_no_shell_syntax == 1 and " (g:kame_no_shell_syntax=1)" or " (with shell syntax)"
emit("File: " .. shown .. shell)
emit("")
for lnum = 1, vim.fn.line("$") do
  emit(render_line(lnum))
end

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

io.stdout:write(table.concat(out, "\n") .. "\n")
