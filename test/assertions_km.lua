-- Assert Kame value-program syntax highlight groups for test/fixture.km.
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

-- Comments and the include directive.
expect(1, '# Syntax', 'kameComment')
expect(17, '// Second', 'kameComment')
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

-- References, slices, key selections, sections, comparisons, and substitution.
expect(9, 'project.name', 'kameReference')
expect(10, 'files.1..4', 'kameReference')
expect(11, 'config.{host,port}', 'kameReference')
expect(12, '_0', 'kamePlaceholder')
expect(12, '_1', 'kamePlaceholder')
expect(13, '<', 'kameComparisonOperator')
expect(14, '$(git', 'kameCommandSubstitutionDelimiter')

-- Function definitions, pattern captures, and globs.
expect(15, '(source', 'kameFunctionDefinition')
expect(15, 'source', 'kameFunctionName')
expect(15, 'object', 'kameFunctionParameter')
expect(15, './{**}/{*}.c', 'kamePath')
expect(15, '{**}', 'kameCapture')
expect(15, '_0', 'kameCaptureName')
expect(15, 'object', 'kameName', 2)

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
