-- ============================================================================
-- numbering-to-headings.lua — 数字编号纯文本行 → Markdown 标题
-- ============================================================================
-- 编号格式：
--   1 xxx       → # 1 xxx       (一级)
--   2.1 xxx     → ## 2.1 xxx     (二级)
--   3.1.2 xxx   → ### 3.1.2 xxx  (三级)
--
-- 受 YAML 元数据 `title-type` 控制：
--   biaozhun 或 tongzhi+biaozhun → 启用
--   none 或 tongzhi              → 跳过
--   未设置                        → 跳过（默认 tongzhi）
-- ============================================================================

local has_biaozhun = false

-- ============================================================================
-- 层级检测
-- ============================================================================

local function detect_level(text)
  if text:match("^%d+%.%d+%.%d+%s") then return 3 end
  if text:match("^%d+%.%d+%s") then return 2 end
  if text:match("^%d+%s") and not text:match("^%d+%.%d") then return 1 end
  return nil
end

-- ============================================================================
-- 表格式返回
-- ============================================================================

return {
  {
    Meta = function(meta)
      local tt = meta["title-type"]
      if tt then
        local mode = pandoc.utils.stringify(tt):lower()
        has_biaozhun = mode:match("biaozhun") ~= nil
      end
      return nil
    end,
  },
  {
    Para = function(el)
      if not has_biaozhun then return nil end

      local text = pandoc.utils.stringify(el.content)
      if #text == 0 then return nil end

      local level = detect_level(text)
      if level then
        return pandoc.Header(level, el.content)
      end

      return nil
    end,
  },
}
