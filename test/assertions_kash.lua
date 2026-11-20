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

expect(1, '# Kash', 'kameComment')
expect(2, 'def', 'kameKeyword')
expect(2, 'label', 'kameFunctionName')
expect(2, 'name', 'kameFunctionParameter')
expect(3, 'let', 'kameKeyword')
expect(3, 'title', 'kameDefinitionName')
expect(3, '"Hello $name"', 'kameString')
expect(4, '[', 'kameDelimiter')
expect(5, 'echo', 'kameKashCommand')
expect(6, 'cat', 'kameKashCommand')
expect(6, '$...files', 'kameKashReference')
expect(6, '|', 'kameKashPipeline')
expect(6, 'wc', 'kameKashCommand')
expect(7, 'cwd:', 'kameKashSetupKey')
expect(7, 'timeout:', 'kameKashSetupKey')
expect(7, 'env:', 'kameKashSetupKey')
expect(7, 'npm', 'kameKashCommand')
expect(8, '$?(', 'kameCommandSubstitutionDelimiter')
expect(9, '||', 'kameKashSequential')
expect(10, '$&(', 'kameCommandSubstitutionDelimiter')
expect(10, '--port', 'kameKashOption')
expect(11, 'for', 'kameKeyword')
expect(11, 'source', 'kameKashLoopName')
expect(12, 'echo', 'kameKashCommand')
expect(12, '$source', 'kameKashReference')
expect(13, 'while', 'kameKeyword')
expect(14, 'sleep', 'kameKashCommand')
expect(15, 'defer', 'kameKeyword')
expect(15, 'rm', 'kameKashCommand')
expect(16, 'with', 'kameKeyword')
expect(16, 'cwd:', 'kameKashSetupKey')
expect(16, 'env:', 'kameKashSetupKey')
expect(18, 'match', 'kameKeyword')
expect(19, './notes/{name:*}.txt', 'kamePath')
expect(19, '{name:*}', 'kameCapture')
expect(19, '=>', 'kameLambdaOperator')
expect(20, 'echo', 'kameKashCommand')
expect(21, 'else', 'kameKeyword')
expect(23, 'producer', 'kameKashCommand')
expect(23, 'merge', 'kameKashMux')
expect(23, 'sort', 'kameKashCommand')
expect(24, 'frame', 'kameKashMux')
expect(24, ':lines', 'kameKashMuxKey')
expect(24, 'broadcast', 'kameKashMux')
expect(24, ':buffer', 'kameKashMuxKey')
expect(24, 'cat', 'kameKashCommand')
expect(25, '>&out', 'kameKashChannel')
expect(26, 'stream', 'kameKeyword')
expect(26, 'reports', 'kameKashStreamName')

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
