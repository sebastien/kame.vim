-- Assert foreign-shell recipe highlighting for test/fixture.shell.km.
-- Driven by test/run.sh with g:kame_recipe_lang = 'shell'.

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

local function expect(line, needle, group)
  checks = checks + 1
  local col = locate(line, needle)
  if not col then
    table.insert(failures, string.format('line %d: occurrence of %q not found', line, needle))
    return
  end
  local actual = group_at(line, col)
  if actual ~= group then
    table.insert(failures, string.format('line %d col %d (%q): expected %s, got %s', line, col, needle, group, actual))
  end
end

expect(1, 'SHELL', 'kameDefinitionName')
expect(1, '"sh"', 'kameString')
expect(3, 'task', 'kameRuleKeyword')
expect(3, 'build', 'kameTargetName')
expect(3, ';', 'kameRuleSeparator')
expect(4, 'echo', 'shStatement')
expect(5, '@if', 'kameTemplateDirective')
expect(6, 'echo', 'shStatement')
expect(7, '@else', 'kameTemplateDirective')
expect(8, 'echo', 'shStatement')
expect(9, '@end', 'kameTemplateDirective')

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
