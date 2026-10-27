-- ============================================================================
-- title-promotion.lua — 中文编号纯文本行 → Markdown 标题
-- ============================================================================
-- 受 YAML 元数据 `title-type` 控制（支持 + 组合）：
--   none              → 不转换
--   tongzhi           → 中文编号：一、→H1  （一）→H2
--   tongzhi+biaozhun  → 中文 + 数字
--   未设置             → 默认 tongzhi（向后兼容）
-- ============================================================================

local has_tongzhi = true   -- 默认启用

-- ============================================================================
-- 标题提升规则（仅中文编号）
-- ============================================================================

local function promote(text)
  if not text then return nil end
  local len = pandoc.text.len(text)

  -- Rule 1: 一、、二、、... → Heading 1
  if len >= 2 and pandoc.text.sub(text, 2, 2) == "、" then
    local first_char = pandoc.text.sub(text, 1, 1)
    if first_char == "一" or first_char == "二" or first_char == "三" or first_char == "四"
       or first_char == "五" or first_char == "六" or first_char == "七" or first_char == "八"
       or first_char == "九" or first_char == "十" then
      return pandoc.Header(1, pandoc.Str(text))
    end
  end

  -- Rule 2: （一）、（二）、... → Heading 2
  if len >= 3 and pandoc.text.sub(text, 1, 1) == "（"
     and pandoc.text.sub(text, 3, 3) == "）" then
    local mid = pandoc.text.sub(text, 2, 2)
    if mid == "一" or mid == "二" or mid == "三" or mid == "四"
       or mid == "五" or mid == "六" or mid == "七" or mid == "八"
       or mid == "九" or mid == "十" then
      return pandoc.Header(2, pandoc.Str(text))
    end
  end

  return nil
end

-- ============================================================================
-- 表格式返回：确保 Meta → Pandoc 按序执行
-- ============================================================================
-- 注意：不能用 Para/Plain 元素回调，否则表格单元格里以“一、”开头的正文
-- （如“一、项目建设费改为……”）也会被提升为标题，在 LaTeX 中生成
-- minipage 内的 \section，把表格撑出大片空白。这里只遍历顶层块和 Div。

local function promote_blocks(blocks)
  for i, blk in ipairs(blocks) do
    if blk.t == "Para" or blk.t == "Plain" then
      local heading = promote(pandoc.utils.stringify(blk))
      if heading then blocks[i] = heading end
    elseif blk.t == "Div" then
      promote_blocks(blk.content)
    end
  end
end

return {
  {
    Meta = function(meta)
      local tt = meta["title-type"]
      if tt then
        local mode = pandoc.utils.stringify(tt):lower()
        -- 检查是否包含 tongzhi（支持 tongzhi+biaozhun 组合）
        has_tongzhi = mode:match("tongzhi") ~= nil
      end
      return nil
    end,
    Pandoc = function(doc)
      if not has_tongzhi then return doc end
      promote_blocks(doc.blocks)
      return doc
    end,
  },
}
