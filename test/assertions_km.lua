-- Assert Kame program syntax highlight groups for test/fixture.km.
-- Driven by test/run.sh; cquit(1) prints the mismatches and fails the run.

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

-- Comments, definitions, imports, and includes.
expect(1, '# Syntax', 'kameComment')
expect(2, 'MODE', 'kameDefinitionName')
expect(2, '?=', 'kameDefinitionOperator')
expect(2, '"debug"', 'kameString')
expect(3, '+=', 'kameDefinitionOperator')
expect(4, 'import', 'kameDirective')
expect(4, 'as', 'kameDirective')
expect(4, './lib/toolchain', 'kamePath')
expect(5, 'from', 'kameDirective')
expect(5, 'mode-name', 'kameFunctionCall')
expect(5, 'configured-mode', 'kameFunctionCall')
expect(6, 'include', 'kameDirective')
expect(7, 'include?', 'kameDirective')

-- Expressions, lambdas, pipes, and names.
expect(8, 'SOURCES', 'kameDefinitionName')
expect(8, 'files', 'kameStdlibFunction')
expect(8, './src/**/*.c', 'kamePath')
expect(9, '=>', 'kameLambdaOperator')
expect(9, '+', 'kameOperator')
expect(10, '|>', 'kameValuePipe')
expect(10, 'map', 'kameStdlibFunction')
expect(10, 'ends?', 'kameStdlibFunction')
expect(10, '_', 'kamePlaceholder')
expect(11, 'if', 'kameKeyword')
expect(11, 'then', 'kameKeyword')
expect(11, 'else', 'kameKeyword')
expect(11, 'ready', 'kameFunctionCall')
expect(12, 'name:', 'kameRecordKey')
expect(12, '"app"', 'kameString')
expect(12, '...defaults', 'kameSpreadOperator')
expect(13, '@{', 'kameTemplateDelimiter')
expect(13, 'module/dir', 'kameReference')
expect(13, 'templates/page.kmt', 'kamePath')

-- Functions, match arms, and rule-like declarations.
expect(14, 'def', 'kameKeyword')
expect(14, 'object-path', 'kameFunctionName')
expect(14, 'source', 'kameFunctionParameter')
expect(14, 'match', 'kameKeyword')
expect(15, './src/{path:**}.c', 'kamePath')
expect(15, '{path:**}', 'kameCapture')
expect(15, '=>', 'kameLambdaOperator')
expect(16, 'else', 'kameKeyword')
expect(16, 'nil', 'kameBoolean')
expect(17, 'task', 'kameRuleKeyword')
expect(17, 'deploy', 'kameTargetName')
expect(17, ':', 'kameRuleSeparator')

-- Action statements and bindings.
expect(18, 'let', 'kameKeyword')
expect(18, 'workspace', 'kameDefinitionName')
expect(18, '$(', 'kameCommandSubstitutionDelimiter')
expect(18, 'mktemp', 'kameKashCommand')
expect(19, 'set', 'kameKeyword')
expect(19, 'env/MODE', 'kameReference')
expect(19, '=', 'kameDefinitionOperator')
expect(20, 'for', 'kameKeyword')
expect(20, 'source', 'kameKashLoopName')
expect(20, 'from', 'kameDirective')
expect(20, ':lines', 'kameSymbol')
expect(21, 'echo', 'kameKashCommand')
expect(21, '$source', 'kameKashReference')
expect(22, 'defer', 'kameKeyword')
expect(22, 'rm', 'kameKashCommand')

-- Rule headers, metadata, directives, and recipes.
expect(23, 'rule', 'kameRuleKeyword')
expect(23, './build/{name}.o', 'kamePath')
expect(23, '{name}', 'kameCapture')
expect(23, ':', 'kameRuleSeparator')
expect(23, ';', 'kameRuleSeparator')
expect(23, 'shell:', 'kameRecordKey')
expect(23, '"bash"', 'kameString')
expect(24, '@if', 'kameTemplateDirective')
expect(25, 'strip', 'kameKashCommand')
expect(25, '@{', 'kameTemplateDelimiter')
expect(26, '@end', 'kameTemplateDirective')
expect(27, 'always', 'kameRuleModifier')
expect(27, '(index-path)', 'kameDelimiter')
expect(27, '|', 'kameRuleOrderOnly')
expect(27, ',', 'kameRuleGroupSeparator')
expect(28, 'cp', 'kameKashCommand')
expect(28, 'inputs.0', 'kameReference')
expect(29, 'for', 'kameKeyword')
expect(29, 'in', 'kameKeyword')
expect(29, '"debug"', 'kameString')
expect(30, 'rule', 'kameRuleKeyword')
expect(30, '@{', 'kameTemplateDelimiter')
expect(31, 'cc', 'kameKashCommand')
expect(31, '$inputs.0', 'kameKashReference')

-- Literals and comment rules.
expect(33, '# a comment', 'kameComment')
reject(33, '//', 'kameComment')
expect(34, 'true', 'kameBoolean')
expect(34, 'false', 'kameBoolean')
expect(34, 'nil', 'kameBoolean')
expect(34, ':release', 'kameSymbol')

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
