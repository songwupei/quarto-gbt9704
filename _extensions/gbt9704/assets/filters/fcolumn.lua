-- fcolumn.lua
-- 将 .financial 类别的 Markdown 表格转换为使用 fcolumn 宏包的 LaTeX tabular
-- 支持千分位分隔、小数点对齐、\sumline 合计线
--
-- 用法：
--   | 项目     | 金额（元） |
--   |----------|-----------|
--   | 办公用品  | 1234.56   |
--   | 差旅费    | 89012.00  |
--   | \sumline  |           |
--   | 合计      |           |
--   {tbl-colwidths="[30,70]" .financial}
--
-- 自动检测：
--   - 包含 . 数字的列 → f 列类型（千分位 + 小数点对齐）
--   - 包含 \sumline 标记的行 → 实际 \sumline 命令
--   - 纯文本列 → l（左对齐）

local function is_numeric_cell(content)
  -- 检查单元格内容是否是数字（可能带千分位逗号和货币符号）
  if not content or #content == 0 then
    return false
  end
  -- 提取字符串
  local text = pandoc.utils.stringify(content)
  -- 移除非数字字符后检查
  local cleaned = text:gsub("[%s,，¥$€£%s]", ""):gsub("^%(", ""):gsub("%)$", "")
  -- 检查是否是有效的数字格式（整数或小数）
  if cleaned:match("^-?%d+%.?%d*$") then
    return true
  end
  return false
end

local function is_sumline_cell(content)
  if not content or #content == 0 then
    return false
  end
  local text = pandoc.utils.stringify(content)
  -- 检查是否包含 \sumline 标记
  if text:match("\\sumline") then
    return true
  end
  return false
end

local function cell_text(content)
  return pandoc.utils.stringify(content)
end

local function is_financial_table(tbl)
  if not tbl.classes then
    return false
  end
  for _, cls in ipairs(tbl.classes) do
    if cls == "financial" then
      return true
    end
  end
  return false
end

local function detect_column_types(tbl)
  -- 分析表体和表头，确定每列的类型
  local ncols = 0
  -- 获取列数
  if tbl.head and tbl.head.rows and #tbl.head.rows > 0 then
    local header_row = tbl.head.rows[1]
    ncols = #header_row.cells
  elseif tbl.bodies and #tbl.bodies > 0 and tbl.bodies[1].body and #tbl.bodies[1].body > 0 then
    ncols = #tbl.bodies[1].body[1].cells
  end

  if ncols == 0 then
    return {}
  end

  local coltypes = {}
  for c = 1, ncols do
    coltypes[c] = "l"  -- 默认左对齐
  end

  -- 扫描所有数据行，检测数字列
  local numeric_counts = {}
  local total_rows = 0
  for c = 1, ncols do
    numeric_counts[c] = 0
  end

  local function scan_row(row)
    for c = 1, ncols do
      if row.cells[c] and #row.cells[c].contents > 0 then
        if is_numeric_cell(row.cells[c].contents) then
          numeric_counts[c] = numeric_counts[c] + 1
        end
      end
    end
  end

  -- 扫描表头
  if tbl.head and tbl.head.rows then
    for _, row in ipairs(tbl.head.rows) do
      scan_row(row)
      total_rows = total_rows + 1
    end
  end

  -- 扫描表体
  if tbl.bodies then
    for _, body in ipairs(tbl.bodies) do
      if body.body then
        for _, row in ipairs(body.body) do
          -- 跳过 sumline 行
          local skip = false
          for _, cell in ipairs(row.cells) do
            if is_sumline_cell(cell.contents) then
              skip = true
              break
            end
          end
          if not skip then
            scan_row(row)
            total_rows = total_rows + 1
          end
        end
      end
    end
  end

  -- 如果某列有超过一半的行是数字，则标记为财务列
  if total_rows > 0 then
    for c = 1, ncols do
      if numeric_counts[c] > total_rows * 0.4 then
        coltypes[c] = "f"
      end
    end
  end

  return coltypes
end

function Table(el)
  -- 仅处理带 .financial 类的表格，且仅针对 LaTeX/PDF 输出
  if not is_financial_table(el) then
    return nil
  end
  if not FORMAT:match("latex") and not FORMAT:match("pdf") and not FORMAT:match("beamer") then
    return nil
  end

  local coltypes = detect_column_types(el)
  if #coltypes == 0 then
    return nil
  end

  -- 构建 tabular 环境
  local result = {}
  local colspec = table.concat(coltypes, " ")
  local place = ""
  local has_caption = false

  -- 处理标题
  local cap_long = el.caption and el.caption.long
  if cap_long and #cap_long > 0 then
    has_caption = true
    local cap_text = pandoc.utils.stringify(cap_long)
    table.insert(result, "\\begin{table}[htbp]")
    table.insert(result, "\\centering")
    table.insert(result, "\\caption{" .. cap_text .. "}")
  end

  table.insert(result, "\\resetsumline")
  table.insert(result, "\\begin{tabular}{" .. colspec .. "}")
  table.insert(result, "\\toprule")

  -- 渲染表头
  if el.head and el.head.rows and #el.head.rows > 0 then
    for _, row in ipairs(el.head.rows) do
      local cells = {}
      for _, cell in ipairs(row.cells) do
        local text = cell_text(cell.contents)
        if text == "" then
          text = "\\nbsp"
        end
        table.insert(cells, "\\multicolumn{1}{c}{\\bfseries " .. text .. "}")
      end
      table.insert(result, table.concat(cells, " & ") .. " \\\\")
    end
    table.insert(result, "\\midrule")
  end

  -- 渲染表体
  if el.bodies then
    for bidx, body in ipairs(el.bodies) do
      if body.body then
        for _, row in ipairs(body.body) do
          -- 检查是否是 sumline 行
          local has_sumline = false
          for _, cell in ipairs(row.cells) do
            if is_sumline_cell(cell.contents) then
              has_sumline = true
              break
            end
          end

          if has_sumline then
            table.insert(result, "\\sumline")
          else
            local cells = {}
            for c, cell in ipairs(row.cells) do
              local text = cell_text(cell.contents)
              -- 对 f 列，只保留数字部分（去掉已格式化的千分位）
              if coltypes[c] == "f" then
                -- 清理数字：去掉逗号、空格、货币符号
                text = text:gsub(",", ""):gsub("，", ""):gsub("%s+", "")
                  :gsub("¥", ""):gsub("$", ""):gsub("€", ""):gsub("£", "")
                if text == "" then
                  text = "0"
                end
              end
              if text == "" then
                text = "\\nbsp"
              end
              table.insert(cells, text)
            end
            table.insert(result, table.concat(cells, " & ") .. " \\\\")
          end
        end
      end
    end
  end

  -- 渲染表脚
  if el.foot and el.foot.rows and #el.foot.rows > 0 then
    table.insert(result, "\\midrule")
    for _, row in ipairs(el.foot.rows) do
      local cells = {}
      for _, cell in ipairs(row.cells) do
        local text = cell_text(cell.contents)
        if text == "" then
          text = "\\nbsp"
        end
        table.insert(cells, text)
      end
      table.insert(result, table.concat(cells, " & ") .. " \\\\")
    end
  end

  table.insert(result, "\\bottomrule")
  table.insert(result, "\\end{tabular}")

  if has_caption then
    table.insert(result, "\\end{table}")
  end

  return pandoc.RawBlock("latex", table.concat(result, "\n"))
end
