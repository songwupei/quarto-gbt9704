-- ============================================================================
-- table-colwidths.lua — 自动为所有表格注入 tbl-colwidths
-- ============================================================================
-- 根据列数自动计算列宽比例，避免 Pandoc 默认按列头等宽分配。
--
-- 默认比例（可在下方 COLWIDTHS 表中调整）：
--   2 列 → [20, 80]
--   3 列 → [15, 15, 70]      ← "等级 | 名称 | 核心特征" 类表格
--   4 列 → [15, 25, 35, 25]
--   5 列 → [12, 12, 30, 23, 23]
--   6 列 → [10, 10, 25, 20, 20, 15]
--
-- 如果源文件中已有 tbl-colwidths（如 :::: {tbl-colwidths="[...]"}"），
-- 则以源文件为准，filter 不覆盖。
-- ============================================================================

-- ============================================================================
-- 1. 默认列宽配置（按列数映射）
--    修改这里的数字即可全局调整，无需改动业务逻辑
-- ============================================================================
local COLWIDTHS = {
  [2] = {20, 80},
  [3] = {15, 15, 70},
  [4] = {15, 25, 35, 25},
  [5] = {12, 12, 30, 23, 23},
  [6] = {10, 10, 25, 20, 20, 15},
}

-- ============================================================================
-- 2. 主流程：遍历所有 Table，包裹在 tbl-colwidths Div 中
-- ============================================================================
function Pandoc(doc)
  local new_blocks = {}
  local i = 1

  while i <= #doc.blocks do
    local blk = doc.blocks[i]

    if blk.t == "Table" then
      local ncols = #blk.colspecs
      local widths = COLWIDTHS[ncols]

      if widths then
        -- 检查是否已有显式 colwidths wrapper
        local already_wrapped = false
        if i > 1 and doc.blocks[i - 1].t == "Div" then
          local div = doc.blocks[i - 1]
          local classes = div.classes or {}
          for _, cls in ipairs(classes) do
            if cls == "tbl-colwidths" then
              already_wrapped = true
              break
            end
          end
        end

        if not already_wrapped then
          local parts = {}
          for _, w in ipairs(widths) do
            table.insert(parts, tostring(w))
          end
          local width_str = "[" .. table.concat(parts, ",") .. "]"

          local div = pandoc.Div(
            {blk},
            {["tbl-colwidths"] = width_str}
          )
          table.insert(new_blocks, div)
        else
          table.insert(new_blocks, blk)
        end
      else
        table.insert(new_blocks, blk)
      end
    else
      table.insert(new_blocks, blk)
    end

    i = i + 1
  end

  doc.blocks = new_blocks
  return doc
end
