-- ============================================================================
-- numbering-to-headings.lua — 数字编号纯文本行 → Markdown 标题
-- ============================================================================
-- 适用于标准/规范类文档（如标准文件、技术规范），其编号格式为：
--   1 xxx       → # 1 xxx       (一级)
--   2.1 xxx     → ## 2.1 xxx     (二级)
--   3.1.2 xxx   → ### 3.1.2 xxx  (三级)
--
-- 受 YAML 元数据 `title-type` 控制：
--   none     → 不转换
--   tongzhi  → 跳过（由 title-promotion.lua 处理）
--   biaozhun → 启用数字编号规则
--   auto     → 启用（默认，向后兼容）
--
-- 仅转换纯文本段落（Para）中的编号行，已有的 Header 不受影响。
-- ============================================================================

local mode = "auto"

-- ============================================================================
-- 层级检测
-- ============================================================================

local function detect_level(text)
  -- 三级：X.Y.Z xxx
  if text:match("^%d+%.%d+%.%d+%s") then
    return 3
  end
  -- 二级：X.Y xxx
  if text:match("^%d+%.%d+%s") then
    return 2
  end
  -- 一级：X xxx（不能是 X. 开头，防止匹配 "1." "2." 等列表项）
  if text:match("^%d+%s") and not text:match("^%d+%.%d") then
    return 1
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
        mode = pandoc.utils.stringify(tt):lower()
      end
      return nil
    end,
  },
  {
    Para = function(el)
      if mode == "none" or mode == "tongzhi" then
        return nil
      end

      local text = pandoc.utils.stringify(el.content)

      if #text == 0 then
        return nil
      end

      local level = detect_level(text)
      if level then
        return pandoc.Header(level, el.content)
      end

      return nil
    end,
  },
}
