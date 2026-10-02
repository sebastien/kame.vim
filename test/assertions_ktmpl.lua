-- Assert Kame document-template (.HOST.ktmpl) highlight groups for
-- test/fixture.paml.ktmpl, a PAML host. Driven by test/run.sh; cquit(1) prints
-- the mismatches and fails the run.
--
-- Two layers are checked together: the host language (paml*) and the Kame
-- template overlay (kame*). Host groups only exist when a PAML syntax is on
-- 'runtimepath'; the host checks are skipped otherwise so the suite still runs
-- without the host installed.

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

-- Layer detection: a .ktmpl names the template layer and its host dialect.
checks = checks + 1
if vim.b.kame_lang ~= 'template' then
  table.insert(failures, string.format('kame_lang: expected template, got %s', tostring(vim.b.kame_lang)))
end
checks = checks + 1
if vim.b.kame_host ~= 'paml' then
  table.insert(failures, string.format('kame_host: expected paml, got %s', tostring(vim.b.kame_host)))
end

-- Inline @(EXPRESSION) expansions: the delimiter opens the item, the contents
-- use the value grammar, and the closing ')' is the delimiter again.
expect(5, '@(page.title)', 'kameTemplateDelimiter')
expect(5, 'page.title', 'kameReference')
expect(5, ')', 'kameTemplateDelimiter', 1)
expect(7, '@(', 'kameTemplateDelimiter')
expect(7, 'page.heading', 'kameReference')
expect(12, 'post.url', 'kameReference')
expect(12, 'post.title', 'kameReference')

-- Directive lines, whole-line and keyword-gated, inside the host comment style.
expect(8, '@if', 'kameRecipeDirective')
expect(10, '@for', 'kameRecipeDirective')
expect(13, '@end', 'kameRecipeDirective')
expect(14, '@else', 'kameRecipeDirective')
expect(16, '@end', 'kameRecipeDirective')

-- The directive is only the keyword; its argument list belongs to the host
-- region and stays host text.
reject(8, '(page.posts)', 'kameRecipeDirective')

-- Host text keeps its own highlighting under the overlay. Skipped when no PAML
-- syntax is installed, since the host groups do not exist then.
if vim.fn.hlexists('pamlTag') == 1 then
  expect(1, '<!DOCTYPE', 'pamlTag')
  expect(5, '<title', 'pamlTag')
  expect(5, ':Kame', 'pamlLabel')
  expect(7, '<h1', 'pamlTag')
  expect(12, 'href=', 'pamlAttribute')
  -- A label that follows the attribute list stays host text, and the overlay
  -- still reaches the expansions inside it (the shim chains pamlLabel back
  -- from pamlAttributes' end).
  expect(12, ': ', 'pamlLabel', 1)
  expect(12, 'post.title', 'kameReference')
else
  io.stdout:write('  (no paml syntax found; host checks skipped)\n')
end

if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  io.stderr:write(string.format('%d of %d checks failed\n', #failures, checks))
  vim.cmd('cquit 1')
end

io.stdout:write(string.format('  %d checks passed\n', checks))
