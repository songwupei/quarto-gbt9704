-- fix_table.lua — Pandoc Lua filter
-- 修复三个 pipe table → LaTeX/PDF 的问题：
--   1. <br> 不换行（RawInline html → LineBreak）
--   2. <div tbl-colwidths="..."> 列宽不生效（→ Table colspecs）
--   3. □ (U+25A1) 字体缺失（仿宋/宋体无此字形 → 回退到 Sarasa Mono SC）
--
-- 用法: pandoc input.md -o output.pdf --lua-filter=tools/fix_table.lua
--
-- 兼容性: HTML / LaTeX / DOCX 输出均正确。LineBreak 对所有格式通用；
--   □ 字体回退仅对 LaTeX 输出注入（HTML 有浏览器回退无需处理）。

-- ============================================================
-- 工具函数
-- ============================================================

--- 解析 "[15,60,25]" → {0.15, 0.60, 0.25}
local function parse_colwidths(s)
  local widths = {}
  if not s then return widths end
  for w in s:gmatch("(%d+%.?%d*)") do
    table.insert(widths, tonumber(w) / 100)
  end
  return widths
end

--- 替换 inlines 列表中的 <br>（RawInline html）→ LineBreak
local function replace_br(inlines)
  local replaced = false
  for i, item in ipairs(inlines) do
    if item.tag == "RawInline" and item.format == "html" then
      local text = item.text:gsub("%s+", ""):lower()
      if text == "<br>" or text == "<br/>" or text == "<br />" then
        inlines[i] = pandoc.LineBreak()
        replaced = true
      end
    end
  end
  return replaced
end

--- 替换 inlines 中的 □ → LaTeX 字体回退命令（仅 LaTeX 输出）
--- 仿宋/宋体/楷体/黑体均不含 U+25A1 字形，需回退到 Sarasa Mono SC
local function replace_checkbox(inlines)
  for i, item in ipairs(inlines) do
    if item.tag == "Str" and item.text:match("□") then
      -- 将包含 □ 的字符串拆分为普通文本 + 字体回退的 □
      local parts = {}
      local rest = item.text
      while #rest > 0 do
        local before, checkbox = rest:match("^(.-)(□)")
        if checkbox then
          if #before > 0 then
            table.insert(parts, pandoc.Str(before))
          end
          table.insert(parts, pandoc.RawInline("tex", "{\\checkboxfallback □}"))
          rest = rest:sub(#before + 4) -- skip past the UTF-8 □ (3 bytes)
        else
          -- Actually □ is 3 bytes in UTF-8, let's just use gmatch
          break
        end
      end
      -- Simpler approach: just replace the whole Str if it contains □
      -- (most common case: "□ 无数据..." → raw tex for the whole thing)
      if #parts == 0 and item.text:match("□") then
        -- Replace the □ character with font-switched version
        local new_text = item.text:gsub("□", "{\\checkboxfallback □}")
        inlines[i] = pandoc.RawInline("tex", new_text)
      elseif #parts > 0 then
        -- Split into segments
        for j = #inlines, i + 1, -1 do
          inlines[j + #parts - 1] = inlines[j]
        end
        for j, part in ipairs(parts) do
          inlines[i + j - 1] = part
        end
      end
    end
  end
end

--- 遍历表格的所有单元格，转换 <br> → LineBreak，□ → 字体回退
local function fix_cells(tbl, is_latex)
  local count = 0

  local function walk_cell(cell)
    for _, block in ipairs(cell.contents) do
      if block.t == "Plain" or block.t == "Para" then
        if replace_br(block.content) then
          count = count + 1
        end
        if is_latex then
          replace_checkbox(block.content)
        end
      end
    end
  end

  -- 表头
  for _, row in ipairs(tbl.head.rows) do
    for _, cell in ipairs(row.cells) do
      walk_cell(cell)
    end
  end
  -- 表体
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      for _, cell in ipairs(row.cells) do
        walk_cell(cell)
      end
    end
  end
  -- 表尾
  for _, row in ipairs(tbl.foot.rows) do
    for _, cell in ipairs(row.cells) do
      walk_cell(cell)
    end
  end

  return count
end

-- ============================================================
-- 过滤器入口
-- ============================================================

--- 全局 Inline 过滤器：处理非表格上下文中的 <br> 和 □
local function fix_inline_general(el, is_latex)
  return nil -- 由各 Block 过滤器自行调用
end

return {
  -- 文档元数据：LaTeX 输出时注入 □ 的字体回退定义
  {
    Meta = function(meta)
      if FORMAT:match("^latex") or FORMAT == "beamer" or FORMAT == "context" then
        -- 在 preamble 中定义回退字体；Sarasa Mono SC 已普遍安装
        local header_includes = meta["header-includes"]
        local fallback_def = pandoc.RawBlock("latex",
          "\\ifdefined\\checkboxfallback\\else\n" ..
          "  \\newfontfamily{\\checkboxfallback}{Sarasa Mono SC}[Scale=MatchLowercase]\n" ..
          "\\fi"
        )
        if not header_includes then
          meta["header-includes"] = pandoc.MetaList{fallback_def}
        else
          table.insert(header_includes, fallback_def)
        end
      end
      return meta
    end,
  },

  -- 处理 <div tbl-colwidths="..."> 包裹的表格：传播列宽，去除 div 包裹
  {
    Div = function(div)
      local colwidths_attr = div.attributes["tbl-colwidths"]
      if not colwidths_attr then
        return nil -- 不处理普通的 div
      end

      local is_latex = FORMAT:match("^latex") or FORMAT == "beamer"

      -- 在 div 内部递归查找第一个 Table 并应用列宽
      local widths = parse_colwidths(colwidths_attr)
      if #widths == 0 then
        return div.content -- 解析失败，只去掉 div 包裹
      end

      local function apply_to_first_table(blocks)
        for i, block in ipairs(blocks) do
          if block.t == "Table" then
            -- 列宽数量匹配时才应用
            -- Pandoc Lua API: colspecs[j] = {alignment_string, width_number}
            if #widths == #block.colspecs then
              for j, w in ipairs(widths) do
                block.colspecs[j][2] = w
              end
            end
            -- <br> → LineBreak, □ → 字体回退
            fix_cells(block, is_latex)
            blocks[i] = block
            return true
          elseif block.t == "Div" then
            if apply_to_first_table(block.content) then
              return true
            end
          end
        end
        return false
      end

      apply_to_first_table(div.content)
      -- 去掉 div 包裹，只返回内容
      return div.content
    end,
  },

  -- 处理未被 <div tbl-colwidths> 包裹的普通表格
  {
    Table = function(tbl)
      local is_latex = FORMAT:match("^latex") or FORMAT == "beamer"
      fix_cells(tbl, is_latex)
      return nil
    end,
  },

  -- 处理非表格中的段落（Para/Plain）：修复 <br> 和 □
  {
    Para = function(para)
      replace_br(para.content)
      if FORMAT:match("^latex") or FORMAT == "beamer" then
        replace_checkbox(para.content)
      end
      return nil
    end,
  },
  {
    Plain = function(plain)
      replace_br(plain.content)
      if FORMAT:match("^latex") or FORMAT == "beamer" then
        replace_checkbox(plain.content)
      end
      return nil
    end,
  },
}
