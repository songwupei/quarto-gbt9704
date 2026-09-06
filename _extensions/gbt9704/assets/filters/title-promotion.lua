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
-- 表格式返回：确保 Meta → Para 按序执行
-- ============================================================================

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
  },
  {
    Para = function(el)
      if not has_tongzhi then return nil end
      return promote(pandoc.utils.stringify(el))
    end,
    Plain = function(el)
      if not has_tongzhi then return nil end
      return promote(pandoc.utils.stringify(el))
    end,
  },
}
