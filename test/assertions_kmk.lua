-- Assert Kame rule-program syntax highlight groups for test/fixture.kmk.
-- Driven by test/run.sh; cquit(1) prints the mismatches and fails the run.

local mode
if vim.g.kame_recipe_lang == 'shell' then
  mode = 'shell'
elseif vim.g.kame_recipe_lang == 'none' or vim.g.kame_no_shell_syntax == 1 then
  mode = 'none'
else
  mode = 'kash'
end

local checks = 0
local failures = {}

local function locate(line, needle, nth)
  local text = vim.fn.getline(line)
  local start = 0
  local index = -1
  for _ = 1, nth or 1 do
    index = vim.fn.stridx(text, needle, start)
    if index < 0 then
      return nil
    end
    start = index + 1
  end
  return index + 1
end

local function group_at(line, col)
  local name = vim.fn.synIDattr(vim.fn.synID(line, col, 1), 'name')
  return name ~= '' and name or '<none>'
end

local function expect(line, needle, group, nth)
  checks = checks + 1
  local col = locate(line, needle, nth)
  if not col then
    table.insert(failures, string.format('line %d: occurrence %d of %q not found', line, nth or 1, needle))
    return
  end
  local actual = group_at(line, col)
  if actual ~= group then
    table.insert(failures, string.format('line %d col %d (%q): expected %s, got %s', line, col, needle, group, actual))
  end
end

local function reject(line, needle, group)
  checks = checks + 1
  local col = locate(line, needle)
  if not col then
    table.insert(failures, string.format('line %d: occurrence of %q not found', line, needle))
    return
  end
  if group_at(line, col) == group then
    table.insert(failures, string.format('line %d col %d (%q): did not expect %s', line, col, needle, group))
  end
end

-- Rule headers: target names, paths, task/service, separator.
expect(3, 'default', 'kameTargetName')
expect(3, ':', 'kameRuleSeparator')
expect(3, './build/app', 'kamePath')
expect(5, './build/{name}.o', 'kamePath')
expect(5, '{name}', 'kameCapture')
expect(7, './build/main.o', 'kamePath')
expect(9, './build/version.txt', 'kamePath')
expect(11, 'task', 'kameRuleKind')
expect(11, 'cached', 'kameTargetName')
expect(13, 'service', 'kameRuleKind')
expect(13, 'server', 'kameTargetName')
expect(24, 'clean', 'kameTargetName')

-- Pattern captures: name and the ':glob' pattern part.
expect(39, './out/{name:*}.o', 'kamePath')
expect(39, '{name:*}', 'kameCapture')
expect(39, '*}', 'kameCapturePattern')

-- Kame expansions win over recipe text, including inside quoting and heredocs.
expect(6, '@<', 'kameSelectorInput')
expect(6, '@>', 'kameSelectorOutput')
expect(8, '@>*', 'kameSelectorOutput')
expect(8, '@>', 'kameSelectorOutput', 2)
expect(10, '@(yield', 'kameTemplateDelimiter')
expect(10, 'yield', 'kameStdlibFunction')
expect(16, '@(out', 'kameTemplateDelimiter')
expect(16, '"built', 'kameString')
expect(16, '@(count', 'kameTemplateDelimiter')
expect(17, '@>-1', 'kameSelectorOutput')
expect(20, '@<', 'kameSelectorInput')
reject(25, './build', 'kamePath')

-- Whole-line recipe directives.
expect(30, '@if', 'kameRecipeDirective')
expect(32, '@else', 'kameRecipeDirective')
expect(34, '@end', 'kameRecipeDirective')
expect(35, '@raw', 'kameRecipeDirective')

if mode == 'shell' then
  -- Recipe bodies are shell scripts.
  expect(6, '-c', 'shOption')
  expect(8, '# link', 'shComment')
  expect(12, 'cached', 'shDoubleQuote')
  expect(12, '$(date)', 'shCmdSubRegion')
  expect(14, '--watch', 'shOption')
  expect(17, '"$title"', 'shQuote')
  expect(18, 'if', 'shConditional')
  expect(19, 'cat', 'shStatement')
  expect(19, '<<-EOF', 'shHereDoc02')
  expect(21, 'EOF', 'shHereDoc02')
  expect(22, 'fi', 'shConditional')
  expect(25, 'rm', 'shStatement')
elseif mode == 'kash' then
  -- Recipe bodies are Kash command statements by default.
  expect(6, '-c', 'kameKashOption')
  expect(8, '# link', 'kameComment')
  expect(12, 'cached', 'kameKashString')
  expect(12, '$(date)', 'kameCommandSubstitutionDelimiter')
  expect(14, '--watch', 'kameKashOption')
  expect(17, '$title', 'kameKashReference')
  expect(17, '"$title"', 'kameKashString')
  expect(18, 'if', 'kameKashKeyword')
  expect(19, 'cat', 'kameKashCommand')
  expect(19, '<<', 'kameKashRedirection')
  expect(22, 'fi', 'kameKashCommand')
  expect(25, 'rm', 'kameKashCommand')
  reject(6, 'cc', 'shStatement')
else
  -- With recipes disabled the recipe block stays Kame-only.
  expect(6, 'cc', 'kameRecipe')
  reject(6, 'cc', 'shStatement')
  reject(6, 'cc', 'kameKashCommand')
  reject(18, 'if', 'shConditional')
end

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
