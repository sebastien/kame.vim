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

-- Commands, pipelines, options, and setup keys. Multiple setup pairs are
-- recognised, and the executable after them is still a command.
expect(6, 'git', 'kameKashCommand')
expect(6, '--short', 'kameKashOption')
expect(7, 'build', 'kameKashCommand')
expect(7, '|', 'kameKashPipeline')
expect(7, 'tee', 'kameKashCommand')
expect(8, '&', 'kameKashAsync')
expect(9, ':accept-exit', 'kameKashSetupKey')
expect(9, ':timeout', 'kameKashSetupKey')
expect(9, ':NODE_ENV', 'kameKashSetupKey')
expect(9, 'npm', 'kameKashCommand')

-- Eager let bindings, defer, references, and explicit argv spread.
expect(10, 'let', 'kameKashKeyword')
expect(10, 'workspace', 'kameDefinitionName')
expect(10, '$(mktemp', 'kameCommandSubstitutionDelimiter')
expect(11, 'defer', 'kameKashKeyword')
expect(11, '$workspace', 'kameKashReference')
expect(12, '??', 'kameKashRecovery')
expect(12, '"unknown"', 'kameKashString')
expect(13, '$result', 'kameKashReference')
expect(14, '$x/uv', 'kameKashReference')
expect(14, '--extra', 'kameKashOption')
expect(15, '${x/uv}', 'kameKashReference')
expect(17, '$...CMD', 'kameKashReference')

-- Acceptance and fallback.
expect(18, '?', 'kameKashAcceptance')
expect(18, 'echo', 'kameKashCommand')

-- Block control statements.
expect(20, 'if', 'kameKashKeyword')
expect(20, 'options.release', 'kameReference')
expect(21, 'cc', 'kameKashCommand')
expect(21, '-O2', 'kameKashOption')
expect(22, 'elif', 'kameKashKeyword')
expect(24, 'else', 'kameKashKeyword')
expect(27, 'match', 'kameKashKeyword')
expect(28, 'case', 'kameKashKeyword')
expect(28, './src/{name:*}.c', 'kamePath')
expect(28, '{name:*}', 'kameCapture')
expect(29, '${name}', 'kameKashReference')

-- Native def functions, loop headers, and owned with scopes.
expect(33, 'def', 'kameKashKeyword')
expect(33, 'probe', 'kameFunctionName')
expect(33, 'workspace', 'kameFunctionParameter')
expect(33, 'rest...', 'kameFunctionParameter')
expect(34, '"${workspace}/ready"', 'kameKashString')
expect(35, 'return', 'kameKashKeyword')
expect(36, '?', 'kameKashAcceptance')
expect(38, 'for', 'kameKashKeyword')
expect(38, 'name', 'kameDefinitionName')
expect(38, 'in', 'kameKashKeyword')
expect(38, 'names', 'kameFunctionCall')
expect(40, 'while', 'kameKashKeyword')
expect(42, 'with', 'kameKashKeyword')
expect(42, ':cwd', 'kameKashSetupKey')
expect(42, ':env', 'kameKashSetupKey')
expect(42, '$exports', 'kameKashReference')

-- Graph operators, channels, and command lists.
expect(45, 'producer', 'kameKashCommand')
expect(45, '|', 'kameKashPipeline')
expect(45, 'merge', 'kameKashMux')
expect(46, '&&', 'kameKashSequential')
expect(46, '||', 'kameKashSequential')
expect(47, '>', 'kameKashRedirection')
expect(47, '2>', 'kameKashRedirection')
expect(48, '>&out', 'kameKashChannel')
expect(49, 'stream', 'kameKashKeyword')
expect(49, 'reports', 'kameKashChannelName')
expect(50, 'producer', 'kameKashGroupCommand')
expect(50, '>&reports', 'kameKashChannel')
expect(50, '&reports', 'kameKashChannel')
expect(50, '|', 'kameKashPipeline')
expect(50, 'consumer', 'kameKashCommand')

-- Rule and function selectors are expression atoms in direct Kash.
expect(51, '@>', 'kameSelectorOutput')
expect(51, '@<', 'kameSelectorInput')
expect(51, '@<?', 'kameSelectorInput')
expect(51, '@*', 'kameSelectorArgument')
expect(51, '@_', 'kameSelectorArgument')
expect(51, '@#', 'kameSelectorArgument')
expect(51, '@1', 'kameSelectorArgument')

-- Interpolated paths in definition RHSs highlight @{...}; Kash strings do not.
expect(52, '@{ROOT}', 'kameTemplateReference')
expect(53, '"@{x/uv}"', 'kameKashString')
reject(53, '@{x/uv}', 'kameTemplateReference')

-- Mux operators and policy keys, plus setup pairs after a pipe.
expect(54, 'frame', 'kameKashMux')
expect(54, ':lines', 'kameKashMuxKey')
expect(54, 'broadcast', 'kameKashMux')
expect(54, ':buffer', 'kameKashMuxKey')
expect(55, 'tee', 'kameKashMux')
expect(55, ':append', 'kameKashMuxKey')
expect(55, 'each', 'kameKashMux')
expect(55, 'worker', 'kameKashCommand')
expect(56, ':cwd', 'kameKashSetupKey')
expect(56, ':timeout', 'kameKashSetupKey')
expect(56, 'tool', 'kameKashCommand')
expect(57, '# final', 'kameComment')
expect(58, 'def', 'kameKashKeyword')
expect(58, 'opencode-cleanup!', 'kameFunctionName')
expect(58, 'temporary', 'kameFunctionParameter')
expect(58, '# cleanup', 'kameComment')
expect(59, 'if', 'kameKashKeyword')
expect(60, 'for', 'kameKashKeyword')
expect(60, 'from', 'kameKashKeyword')
expect(61, 'let', 'kameKashKeyword')
expect(61, 'split', 'kameStdlibFunction')
reject(62, 'defn', 'kameKashKeyword')

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
