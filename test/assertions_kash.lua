-- Assert Kash syntax highlight groups for test/fixture.kash.
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

-- Comments and definitions.
expect(1, '# Kash', 'kameComment')
expect(2, 'title', 'kameDefinitionName')
expect(2, '=', 'kameDefinitionOperator')
expect(2, '"Little publication"', 'kameKashString')
expect(4, 'label', 'kameFunctionName')
expect(4, 'name', 'kameFunctionParameter')

-- Commands, pipelines, options, and setup keys.
expect(6, 'git', 'kameKashCommand')
expect(6, '--short', 'kameKashOption')
expect(7, 'build', 'kameKashCommand')
expect(7, '|', 'kameKashPipeline')
expect(7, 'tee', 'kameKashCommand')
expect(8, '&', 'kameKashAsync')
expect(9, ':timeout', 'kameKashSetupKey')
expect(9, '@(10)', 'kameTemplateDelimiter')

-- Substitutions, recovery, and acceptance.
expect(10, '$(git', 'kameCommandSubstitutionDelimiter')
expect(10, '??', 'kameKashRecovery')
expect(10, '"unknown"', 'kameKashString')
expect(11, '$result', 'kameKashReference')
expect(12, '?', 'kameKashAcceptance')
expect(13, '?', 'kameKashAcceptance')
expect(14, '@(map', 'kameTemplateDelimiter')
expect(14, 'map', 'kameStdlibFunction')
expect(15, '@NAME', 'kameKashMeta')
expect(15, ';', 'kameKashSeparator')

-- Block control statements.
expect(17, 'if', 'kameKashKeyword')
expect(17, 'options.release', 'kameReference')
expect(18, 'cc', 'kameKashCommand')
expect(18, '-O2', 'kameKashOption')
expect(19, 'elif', 'kameKashKeyword')
expect(21, 'else', 'kameKashKeyword')
expect(24, 'match', 'kameKashKeyword')
expect(25, 'case', 'kameKashKeyword')
expect(25, './src/{name:*}.c', 'kamePath')
expect(25, '{name:*}', 'kameCapture')
expect(26, '${name}', 'kameKashReference')

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
