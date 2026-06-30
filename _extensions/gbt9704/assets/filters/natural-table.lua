-- natural-table.lua
-- 将 pandoc Table AST 转换为 ConTeXt Natural Tables (\bTABLE...\eTABLE)
-- 支持表头、多表体、表脚、内联格式、交替行色

local function render_inlines(inlines)
  local parts = {}
  for _, il in ipairs(inlines) do
    local t = il.t
    if t == "Str" then
      table.insert(parts, il.text)
    elseif t == "Space" then
      table.insert(parts, " ")
    elseif t == "SoftBreak" or t == "LineBreak" then
      table.insert(parts, " ")
    elseif t == "Code" then
      table.insert(parts, "\\type{" .. il.text .. "}")
    elseif t == "Strong" then
      table.insert(parts, "{\\bf " .. render_inlines(il.content) .. "}")
    elseif t == "Emph" then
      table.insert(parts, "{\\em " .. render_inlines(il.content) .. "}")
    elseif t == "Link" then
      local txt = render_inlines(il.content)
      table.insert(parts, "\\useurl[" .. il.target .. "][" .. txt .. "]")
    elseif t == "RawInline" and il.format == "context" then
      table.insert(parts, il.text)
    else
      table.insert(parts, pandoc.utils.stringify({il}))
    end
  end
  return table.concat(parts)
end

local function render_cell(cell)
  local parts = {}
  for _, block in ipairs(cell.contents) do
    if block.t == "Plain" or block.t == "Para" then
      table.insert(parts, render_inlines(block.content))
    elseif block.t == "CodeBlock" then
      table.insert(parts, "\\type{" .. block.text:gsub("\n", " ") .. "}")
    elseif block.t == "BulletList" then
      for _, item in ipairs(block.content) do
        local txt = render_inlines(item[1] and item[1].content or {})
        table.insert(parts, "\\bullet " .. txt)
      end
    else
      local txt = pandoc.utils.stringify(block)
      if txt ~= "" then
        table.insert(parts, txt)
      end
    end
  end
  local content = table.concat(parts, " \\par ")
  -- 转义 TeX 注释符：% 会注释掉 \eTD 导致表格无法闭合
  content = content:gsub("%%", "\\%%")
  return content ~= "" and content or "\\nbsp"
end

function Table(el)
  -- 仅 ConTeXt 输出使用 Natural Table，docx/pdf 保持 pandoc 原生表格
  if not FORMAT:match("context") then
    return nil
  end
  local result = {}
  local tbl_opts = "option=stretch,split=repeat"

  -- 有标题则包裹 placeable (pandoc 3.x el.caption 是 Caption 对象)
  local cap_long = el.caption and el.caption.long
  local has_caption = cap_long and #cap_long > 0
  if has_caption then
    local cap_text = pandoc.utils.stringify(cap_long)
    table.insert(result, "\\startplacetable[title={" .. cap_text .. "}]")
  end

  table.insert(result, "\\bTABLE[" .. tbl_opts .. "]")

  -- 表头
  if el.head and el.head.rows and #el.head.rows > 0 then
    table.insert(result, "\\bTABLEhead")
    for _, row in ipairs(el.head.rows) do
      table.insert(result, "\\bTR")
      for _, cell in ipairs(row.cells) do
        table.insert(result, "\\bTH " .. render_cell(cell) .. " \\eTH")
      end
      table.insert(result, "\\eTR")
    end
    table.insert(result, "\\eTABLEhead")
  end

  -- 表体
  for _, body in ipairs(el.bodies) do
    table.insert(result, "\\bTABLEbody")
    for ri, row in ipairs(body.body) do
      table.insert(result, "\\bTR")
      for _, cell in ipairs(row.cells) do
        table.insert(result, "\\bTD " .. render_cell(cell) .. " \\eTD")
      end
      table.insert(result, "\\eTR")
    end
    table.insert(result, "\\eTABLEbody")
  end

  -- 表脚
  if el.foot and el.foot.rows and #el.foot.rows > 0 then
    table.insert(result, "\\bTABLEfoot")
    for _, row in ipairs(el.foot.rows) do
      table.insert(result, "\\bTR")
      for _, cell in ipairs(row.cells) do
        table.insert(result, "\\bTD " .. render_cell(cell) .. " \\eTD")
      end
      table.insert(result, "\\eTR")
    end
    table.insert(result, "\\eTABLEfoot")
  end

  table.insert(result, "\\eTABLE")

  if has_caption then
    table.insert(result, "\\stopplacetable")
  end

  return pandoc.RawBlock("context", table.concat(result, "\n"))
end
