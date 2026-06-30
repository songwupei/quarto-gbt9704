-- normalize-styles.lua — 正向清单：将指定样式名映射为标准样式
local STYLE_MAP = {
  ["First Paragraph"] = "Normal",
  ["Body Text"]       = "Normal",
  ["Compact"]          = "Normal",
}

function Para(el)
  return nil  -- 段落样式由 fenced_div custom-style 控制，不在此处理
end

function Div(el)
  -- 遍历 classes 和 attributes 查找 custom-style
  local style = nil
  for _, cls in ipairs(el.classes) do
    if STYLE_MAP[cls] then
      style = STYLE_MAP[cls]
      break
    end
  end
  local cs = el.attributes["custom-style"]
  if cs and STYLE_MAP[cs] then
    style = STYLE_MAP[cs]
  end

  if not style then return nil end

  -- 用 RawBlock OpenXML 替换，仅引用样式名
  local blocks = {}
  for _, block in ipairs(el.content) do
    if block.t == "Para" then
      local text = pandoc.utils.stringify(block)
      local raw = string.format(
        '<w:p><w:pPr><w:pStyle w:val="%s"/></w:pPr><w:r><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
        style, text
      )
      table.insert(blocks, pandoc.RawBlock("openxml", raw))
    end
  end
  return blocks
end
