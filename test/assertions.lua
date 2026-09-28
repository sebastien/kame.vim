-- Assert Kame syntax highlight groups at representative positions.
-- Driven by test/run.sh; cquit(1) prints the mismatches and fails the run.

local shell = vim.g.kame_no_shell_syntax ~= 1
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

-- Comments and the include directive.
expect(1, '# Syntax', 'kameComment')
expect(35, '// Second', 'kameComment')
expect(2, 'include', 'kameDirective')
expect(2, './rules/common.kmk', 'kameIncludePath')

-- Definitions and value atoms.
expect(3, 'VERSION', 'kameDefinitionName')
expect(3, '=', 'kameDefinitionOperator')
expect(3, '"1.2.3"', 'kameString')
expect(4, '(', 'kameDelimiter')
expect(4, 'wildcard', 'kameName')
expect(4, './src/*.c', 'kamePath')
expect(5, '"building', 'kameString')
expect(5, '@(count', 'kameTemplateDelimiter')
expect(5, 'count', 'kameName')
expect(6, '1_000', 'kameNumber')
expect(7, '-3.5', 'kameNumber')
expect(8, '[', 'kameDelimiter')
expect(8, 'name:', 'kameRecordKey')
expect(8, '"app"', 'kameString')
expect(8, 'path:', 'kameRecordKey')
expect(8, './src', 'kamePath')
expect(8, ':true', 'kameBoolean')

-- Function definitions, pattern captures, and globs.
expect(9, '(source', 'kameFunctionDefinition')
expect(9, 'source', 'kameFunctionName')
expect(9, 'object', 'kameFunctionParameter')
expect(9, './{**}/{*}.c', 'kamePath')
expect(9, '{**}', 'kameCapture')
expect(9, '_0', 'kameCaptureName')
expect(9, 'object', 'kameName', 2)

-- Rule headers: target names, paths, task/service, separator.
expect(11, 'default', 'kameTargetName')
expect(11, ':', 'kameRuleSeparator')
expect(11, './build/app', 'kamePath')
expect(13, './build/{name}.o', 'kamePath')
expect(13, '{name}', 'kameCapture')
expect(15, './build/main.o', 'kamePath')
expect(17, './build/version.txt', 'kamePath')
expect(19, 'task', 'kameRuleKind')
expect(19, 'cached', 'kameTargetName')
expect(21, 'service', 'kameRuleKind')
expect(21, 'server', 'kameTargetName')
expect(32, 'clean', 'kameTargetName')

-- Kame expansions win over shell text, including inside quoting and heredocs.
expect(14, '@<', 'kameSelectorInput')
expect(14, '@>', 'kameSelectorOutput')
expect(16, '@>*', 'kameSelectorOutput')
expect(16, '@>', 'kameSelectorOutput', 2)
expect(18, '@(yield', 'kameTemplateDelimiter')
expect(18, 'yield', 'kameName')
expect(24, '@(out', 'kameTemplateDelimiter')
expect(24, '"built', 'kameString')
expect(24, '@(count', 'kameTemplateDelimiter')
expect(25, '@>-1', 'kameSelectorOutput')
expect(28, '@<', 'kameSelectorInput')
reject(33, './build', 'kamePath')

if shell then
  -- Recipe bodies are shell scripts.
  expect(14, '-c', 'shOption')
  expect(16, '# link', 'shComment')
  expect(20, 'cached', 'shDoubleQuote')
  expect(20, '$(date)', 'shCmdSubRegion')
  expect(22, '--watch', 'shOption')
  expect(25, '"$title"', 'shQuote')
  expect(26, 'if', 'shConditional')
  expect(27, 'cat', 'shStatement')
  expect(27, '<<-EOF', 'shHereDoc02')
  expect(29, 'EOF', 'shHereDoc02')
  expect(30, 'fi', 'shConditional')
  expect(33, 'rm', 'shStatement')
else
  -- With g:kame_no_shell_syntax the recipe block stays Kame-only.
  expect(14, 'cc', 'kameRecipe')
  reject(14, 'cc', 'shStatement')
  reject(26, 'if', 'shConditional')
end

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
