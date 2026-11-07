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

-- Comments and includes. Includes are now parenthesized source-composition
-- forms, not line directives.
expect(1, '# Syntax', 'kameComment')
expect(23, '// Second', 'kameComment')
expect(2, 'include', 'kameDirective')
expect(2, './rules/common.kmk', 'kameIncludePath')
expect(3, 'include?', 'kameDirective')
expect(3, '"lib/extra.km"', 'kameIncludePath')

-- Definitions, including the ?= default and += aggregate operators.
expect(4, 'VERSION', 'kameDefinitionName')
expect(4, '=', 'kameDefinitionOperator')
expect(4, '"1.2.3"', 'kameString')
expect(5, 'MODE', 'kameDefinitionName')
expect(5, '?=', 'kameDefinitionOperator')
expect(6, 'CHECKS', 'kameDefinitionName')
expect(6, '+=', 'kameDefinitionOperator')

-- Expressions and value atoms.
expect(7, '(', 'kameDelimiter')
expect(7, 'wildcard', 'kameStdlibFunction')
expect(7, './src/*.c', 'kamePath')
expect(8, '"building', 'kameString')
expect(8, '@(count', 'kameTemplateDelimiter')
expect(8, 'count', 'kameStdlibFunction')
expect(8, '@{TARGET}', 'kameTemplateReference')
expect(9, '1_000', 'kameNumber')
expect(10, '-3.5', 'kameNumber')
expect(11, '[', 'kameDelimiter')
expect(11, 'name:', 'kameRecordKey')
expect(11, '"app"', 'kameString')
expect(11, 'path:', 'kameRecordKey')
expect(11, './src', 'kamePath')
expect(11, ':true', 'kameBoolean')

-- References, slices, key selections, tool references, sections, comparisons,
-- and command substitution.
expect(12, 'project.name', 'kameReference')
expect(13, 'files.1..4', 'kameReference')
expect(14, 'config.{host,port}', 'kameReference')
expect(15, '@{PATH_SRC}', 'kameTemplateReference')
expect(15, '/sh/**/*.sh', 'kamePath')
expect(16, 'x/uv', 'kameReference')
expect(17, '_0', 'kamePlaceholder')
expect(17, '_1', 'kamePlaceholder')
expect(18, '<', 'kameComparisonOperator')
expect(19, '$(git', 'kameCommandSubstitutionDelimiter')

-- Function definitions, pattern captures, and globs.
expect(20, '(source', 'kameFunctionDefinition')
expect(20, 'source', 'kameFunctionName')
expect(20, 'object', 'kameFunctionParameter')
expect(20, './{**}/{*}.c', 'kamePath')
expect(20, '{**}', 'kameCapture')
expect(20, '_0', 'kameCaptureName')
expect(20, 'object', 'kameFunctionCall', 2)
expect(24, './src/{name:*}.c', 'kamePath')
expect(24, '{name:*}', 'kameCapture')

-- Current standard-library operations that used to fall back to generic calls.
expect(25, 'resource', 'kameStdlibFunction')
expect(26, 'now', 'kameStdlibFunction')
expect(27, 'monotonic', 'kameStdlibFunction')
expect(28, 'parse-args', 'kameStdlibFunction')

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
