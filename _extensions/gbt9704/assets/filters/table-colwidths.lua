-- ============================================================================
-- table-colwidths.lua — 按内容自动计算表格列宽
-- ============================================================================
-- 旧版按“列数”套固定比例，遇到列数多、列内容差异大的表会把长文本列压成
-- 一字一行。本版改为按每列的实际内容（表头 + 表体）自动估算列宽：
--
--   * 表体取 75 分位，避免个别超长单元格独占宽度；
--   * 兼顾表头宽度、平均宽度和不可断行的 ASCII token（日期/编号/英文）；
--   * 支持 2 列到任意列，不再只覆盖 2–6 列；
--   * 5 列及以上自动降字号（小4 / 5号）并收紧 \tabcolsep，避免宽表挤爆；
--   * 源文件显式写的 tbl-colwidths 仍然优先。
--
-- 手动覆盖（推荐给特殊表格）：
--   ::: {tbl-colwidths="[8,18,10,10,8,20,7,7,12]"}
--   | ... |
--   :::
-- ============================================================================

local function is_wide_codepoint(cp)
  return (cp >= 0x1100 and cp <= 0x115F)          -- Hangul Jamo
      or (cp >= 0x2E80 and cp <= 0xA4CF)          -- CJK / 部首 / 标点
      or (cp >= 0xAC00 and cp <= 0xD7A3)          -- Hangul
      or (cp >= 0xF900 and cp <= 0xFAFF)          -- CJK 兼容
      or (cp >= 0xFE30 and cp <= 0xFE4F)          -- CJK 兼容标点
      or (cp >= 0xFF00 and cp <= 0xFF60)          -- 全角
      or (cp >= 0xFFE0 and cp <= 0xFFE6)          -- 全角符号
      or (cp >= 0x20000 and cp <= 0x3FFFD)        -- CJK 扩展
end

--- 显示宽度：中文/全角按 2，ASCII 按 1
local function display_width(s)
  local total = 0
  for _, cp in utf8.codes(s or "") do
    total = total + (is_wide_codepoint(cp) and 2 or 1)
  end
  return total
end

--- 最长的不可断行 ASCII 片段（日期、编号、英文单词等）
local function longest_token(s)
  local maxw = 0
  for token in (s or ""):gmatch("[%w%._%-%+%/%%:]+") do
    if #token > maxw then maxw = #token end
  end
  return maxw
end

local function percentile(sorted, p)
  if #sorted == 0 then return 0 end
  local idx = math.ceil(p * #sorted)
  if idx < 1 then idx = 1 end
  if idx > #sorted then idx = #sorted end
  return sorted[idx]
end

--- 统计每一列的内容宽度
local function collect_stats(tbl)
  local ncols = #tbl.colspecs
  local stats = {}
  for j = 1, ncols do
    stats[j] = { header = 0, token = 0, body = {}, sum = 0 }
  end

  local function add_header(j, cell)
    local text = pandoc.utils.stringify(cell.contents)
    local st = stats[j]
    st.header = math.max(st.header, display_width(text))
    st.token = math.max(st.token, longest_token(text))
  end

  local function add_body(j, cell)
    local text = pandoc.utils.stringify(cell.contents)
    local st = stats[j]
    st.token = math.max(st.token, longest_token(text))
    local w = display_width(text)
    table.insert(st.body, w)
    st.sum = st.sum + w
  end

  for _, row in ipairs(tbl.head.rows) do
    for j, cell in ipairs(row.cells) do
      if stats[j] then add_header(j, cell) end
    end
  end
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      for j, cell in ipairs(row.cells) do
        if stats[j] then add_body(j, cell) end
      end
    end
  end
  for _, row in ipairs(tbl.foot.rows) do
    for j, cell in ipairs(row.cells) do
      if stats[j] then add_body(j, cell) end
    end
  end

  return stats
end

--- 根据内容估算每一列的权重
local function compute_weights(stats)
  local weights = {}
  for j, st in ipairs(stats) do
    table.sort(st.body)
    local count = #st.body
    local max_body = count > 0 and st.body[count] or 0
    local p75 = percentile(st.body, 0.75)
    local avg = count > 0 and (st.sum / count) or 0

    -- token 上限 16，避免一个超长英文串把列撑爆。
    local token = math.min(st.token, 16)
    local weight
    if max_body == 0 then
      -- 空列（模板表常见）：按表头长度预留宽度，避免被压成一条线
      weight = math.max(st.header * 0.9, 4)
    elseif max_body <= 8 then
      -- 短列（序号、状态、日期等）：按最长内容给一点余量即可，
      -- 不要让表头长度把数字列撑得很宽。
      weight = math.max(max_body + 1.5, token * 1.6, 2.5)
    else
      -- 长文本列：以 75 分位 + 6 为主，避免个别超长单元格独占宽度。
      weight = math.max(p75 + 6, st.header * 0.8, avg * 1.15, token * 1.2, 4)
    end
    weights[j] = weight + 1.0
  end
  return weights
end

--- 归一化，并限制最小/最大列宽
--- @param weights table 各列权重
--- @param mins table|nil 各列最小占比（可选）
local function normalize(weights, mins)
  local n = #weights
  local default_min = n >= 7 and 0.06 or (n >= 5 and 0.07 or 0.08)
  -- 列数少时允许某列占更宽（如“关键词/出现次数/说明”三列表）
  local maxf = n <= 3 and 0.78 or (n <= 4 and 0.65 or 0.55)
  local sum = 0
  for _, w in ipairs(weights) do sum = sum + w end
  if sum <= 0 then return nil end

  local minfs = {}
  local min_sum = 0
  for j = 1, n do
    local m = (mins and mins[j]) or default_min
    if m < default_min then m = default_min end
    minfs[j] = m
    min_sum = min_sum + m
  end
  -- 最小宽度之和不能挤占全部宽度
  if min_sum > 0.9 then
    local scale = 0.9 / min_sum
    for j = 1, n do minfs[j] = minfs[j] * scale end
  end

  local fracs = {}
  for j, w in ipairs(weights) do fracs[j] = w / sum end

  for _ = 1, 10 do
    local fixed, free_sum = 0, 0
    local free = {}
    for j = 1, n do
      if fracs[j] <= minfs[j] then
        fracs[j] = minfs[j]
        fixed = fixed + minfs[j]
      elseif fracs[j] >= maxf then
        fracs[j] = maxf
        fixed = fixed + maxf
      else
        free_sum = free_sum + fracs[j]
        table.insert(free, j)
      end
    end
    if #free == 0 or free_sum <= 0 then break end

    local remaining = 1 - fixed
    if remaining <= 0 then break end
    local scale = remaining / free_sum
    local changed = false
    for _, j in ipairs(free) do
      local nv = fracs[j] * scale
      if math.abs(nv - fracs[j]) > 1e-6 then changed = true end
      fracs[j] = nv
    end
    if not changed then break end
  end

  local total = 0
  for _, v in ipairs(fracs) do total = total + v end
  if total <= 0 then return nil end
  for j = 1, n do fracs[j] = fracs[j] / total end
  return fracs
end

--- 源文件是否已经通过 dash 数量表达了非等宽列宽
local function explicit_widths(tbl)
  local ws = {}
  local minw, maxw = math.huge, 0
  for j, spec in ipairs(tbl.colspecs) do
    local w = spec[2] or 0
    ws[j] = w
    if w > 0 then
      if w < minw then minw = w end
      if w > maxw then maxw = w end
    end
  end
  if maxw <= 0 or minw == math.huge then return nil end
  -- Pandoc 对等宽 dash 也会给首尾列略大一点，比例约 1.3；超过 1.5 才视为用户有意指定
  if maxw / minw < 1.5 then return nil end
  return ws
end

local function width_attr(fracs)
  -- fix-table.lua 的 parse_colwidths() 会把属性值除以 100，
  -- 因此这里输出百分数（如 8.5），而不是 0.085。
  local parts = {}
  for _, w in ipairs(fracs) do
    table.insert(parts, string.format("%.1f", w * 100))
  end
  return "[" .. table.concat(parts, ",") .. "]"
end

--- 宽表降字号并收紧列间距，给内容腾出宽度
local function latex_style(ncols)
  if ncols >= 8 then
    return "\\begingroup\\zihao{5}\\setlength{\\baselineskip}{15pt}"
        .. "\\setlength{\\tabcolsep}{3pt}\\renewcommand{\\arraystretch}{1.12}"
  elseif ncols >= 5 then
    return "\\begingroup\\zihao{4}\\setlength{\\baselineskip}{18pt}"
        .. "\\setlength{\\tabcolsep}{4pt}\\renewcommand{\\arraystretch}{1.12}"
  end
  return nil
end

--- 处理单个表格；返回包装后的 Div
local function wrap_table(tbl)
  local ncols = #tbl.colspecs
  local fracs = explicit_widths(tbl)
  if not fracs then
    local stats = collect_stats(tbl)
    local weights = compute_weights(stats)

    -- 估算当前字号下“一行能放多少个 ASCII 字符”，确保日期/编号
    -- 这类不可断行的短 token 至少能完整放下一行。
    local capacity = ncols >= 8 and 74 or (ncols >= 5 and 66 or 52)
    local mins = {}
    for j, st in ipairs(stats) do
      local m = 0
      if st.token >= 6 then
        m = math.min(0.30, st.token / capacity)
      end
      -- 4 列以内的短/中等文本列（约 3–13 个汉字）给 18% 下限，避免
      -- “按里程碑”“表13与表18四项费用不一致”这类内容被挤成三四个字一行。
      if ncols <= 4 and #st.body > 0 then
        local max_body = st.body[#st.body]
        if max_body >= 6 and max_body <= 26 then
          m = math.max(m, 0.18)
        end
      end
      -- 5–6 列窄表里的短文本列（如“周期：里程碑”），保证整词不被竖排。
      if ncols >= 5 and ncols <= 6 and #st.body > 0 then
        local max_body = st.body[#st.body]
        if max_body >= 6 and max_body <= 12 then
          m = math.max(m, math.min(0.14, (max_body + 2) / capacity))
        end
      end
      mins[j] = m
    end

    fracs = normalize(weights, mins)
  else
    fracs = normalize(fracs)
  end
  if not fracs then return nil end

  local content = { tbl }
  local style = FORMAT:match("^latex") and latex_style(ncols) or nil
  if style then
    table.insert(content, 1, pandoc.RawBlock("latex", style))
    table.insert(content, pandoc.RawBlock("latex", "\\endgroup"))
  end

  return pandoc.Div(content, {
    class = "tbl-colwidths",
    ["tbl-colwidths"] = width_attr(fracs),
  })
end

function Pandoc(doc)
  local new_blocks = {}
  for _, blk in ipairs(doc.blocks) do
    if blk.t == "Table" then
      local wrapped = wrap_table(blk)
      table.insert(new_blocks, wrapped or blk)
    else
      table.insert(new_blocks, blk)
    end
  end
  doc.blocks = new_blocks
  return doc
end
