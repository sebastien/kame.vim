-- Assert Kame document-template highlight groups for test/fixture.kmt.
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

expect(1, '@{', 'kameTemplateDelimiter')
expect(1, 'title', 'kameFunctionCall')
expect(3, '@for', 'kameTemplateDirective')
expect(3, 'in', 'kameKeyword')
expect(4, '@{', 'kameTemplateDelimiter')
expect(4, 'post.title', 'kameReference')
expect(5, '@end', 'kameTemplateDirective')
expect(5, 'for', 'kameTemplateDirectiveLabel')
expect(7, '@if', 'kameTemplateDirective')
expect(7, 'ready', 'kameFunctionCall')
expect(7, '-', 'kameTemplateTrim')
expect(8, '@include', 'kameTemplateDirective')
expect(8, './row.html', 'kamePath')
expect(9, '@end', 'kameTemplateDirective')
expect(9, 'if', 'kameTemplateDirectiveLabel')
expect(10, '@raw', 'kameTemplateDirective')
reject(11, '@{', 'kameTemplateDelimiter')
expect(12, '@end', 'kameTemplateDirective')
expect(13, '@@', 'kameEscape')

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
