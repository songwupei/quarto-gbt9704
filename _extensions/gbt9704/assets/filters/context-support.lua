-- context-support.lua
-- Pandoc Lua filter: 为 ConTeXt 输出修复 Quarto 特有语法
-- 处理: 代码块选项、callout 标注块、数学标签、图片路径

local function startswith(s, prefix)
  return s:sub(1, #prefix) == prefix
end

-- ── CodeBlock: 剥离 Quarto 单元格选项，直接输出 RawBlock ──
-- Pandoc 的 ConTeXt writer 对带属性的 CodeBlock 会错放 \starttyping 位置，
-- 所以绕过 writer，直接生成 RawBlock。
function CodeBlock(el)
  local lines = {}
  for line in el.text:gmatch('[^\n]+') do
    local stripped = line:match('^%s*(.-)%s*$')
    if not (startswith(stripped, '#|') or startswith(stripped, '#| ')) then
      lines[#lines + 1] = line
    end
  end
  if #lines == 0 then return {} end
  local code = table.concat(lines, '\n')
  return pandoc.RawBlock('context', '\\starttyping\n' .. code .. '\n\\stoptyping')
end

-- ── Div: callout 标注块 → ConTeXt 环境 ──
function Div(el)
  local callout_map = {
    ['callout-note']    = 'gbtnote',
    ['callout-warning'] = 'gbtwarning',
    ['callout-tip']     = 'gbttip',
    ['callout-important'] = 'gbtimportant',
    ['callout-caution'] = 'gbtcaution',
  }
  for cls, env in pairs(callout_map) do
    if el.classes:includes(cls) then
      return {
        pandoc.RawBlock('context', '\\start' .. env),
        el,
        pandoc.RawBlock('context', '\\stop' .. env),
      }
    end
  end
  -- 处理 content-visible 条件块：保留 when-format=context 的，丢弃其他
  if el.classes:includes('content-visible') then
    local attrs = el.attributes or {}
    local when = attrs['when-format'] or ''
    if when:find('context') then
      return el
    else
      return {}
    end
  end
  return nil
end

-- ── Note: 脚注 → ConTeXt \footnote ──
function Note(el)
  return pandoc.RawInline('context', '\\footnote{' .. pandoc.utils.stringify(el.content) .. '}')
end

-- ── Image: 确保 ConTeXt 使用正确的图片路径 ──
function Image(el)
  if el.src:match('%.png$') then
    el.src = el.src:gsub('figure%-latex', 'figure-context')
    el.src = el.src:gsub('figure%-pdf', 'figure-context')
    el.src = el.src:gsub('%.png$', '.pdf')
  end
  return el
end

-- ── Meta: 确保 block-headings 开启 ──
function Meta(meta)
  meta['block-headings'] = true
  return meta
end

-- ── DefinitionList: 定义列表 → ConTeXt description 环境 ──
function DefinitionList(el)
  local result = {pandoc.RawBlock('context', '\\startdescription')}
  for _, item in ipairs(el.content) do
    local term_text = pandoc.utils.stringify(item.term)
    table.insert(result, pandoc.RawBlock('context', '\\startdescr{' .. term_text .. '}'))
    for _, block in ipairs(item.definitions) do
      table.insert(result, block)
    end
    table.insert(result, pandoc.RawBlock('context', '\\stopdescr'))
  end
  table.insert(result, pandoc.RawBlock('context', '\\stopdescription'))
  return result
end

return {
  { CodeBlock = CodeBlock },
  { DefinitionList = DefinitionList },
  { Div = Div },
  { Note = Note },
  { Image = Image },
  { Meta = Meta },
}
