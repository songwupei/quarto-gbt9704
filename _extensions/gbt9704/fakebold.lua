-- fakebold.lua - Pandoc filter: fakebold/fakeslant for ConTeXt
-- **text**     → {\FakeBold text}
-- *text*      → {\FakeSlant text}
-- ***text***  → {\FakeBoldSlant text}

local function wrap(command, content)
  local result = { pandoc.RawInline('context', '{\\' .. command .. ' ') }
  for _, item in ipairs(content) do
    table.insert(result, item)
  end
  table.insert(result, pandoc.RawInline('context', '}'))
  return result
end

function Strong(el)
  if FORMAT ~= 'context' then return end
  if #el.content == 1 and el.content[1].tag == 'Emph' then
    return wrap('FakeBoldSlant', el.content[1].content)
  end
  return wrap('FakeBold', el.content)
end

function Emph(el)
  if FORMAT ~= 'context' then return end
  if #el.content == 1 and el.content[1].tag == 'Strong' then
    return wrap('FakeBoldSlant', el.content[1].content)
  end
  return wrap('FakeSlant', el.content)
end
