-- ============================================================================
-- numbering-to-headings.lua — 数字编号纯文本行 → Markdown 标题
-- ============================================================================
-- 适用于标准/规范类文档（如标准文件、技术规范），其编号格式为：
--   1 xxx       → # 1 xxx       (一级)
--   2.1 xxx     → ## 2.1 xxx     (二级)
--   3.1.2 xxx   → ### 3.1.2 xxx  (三级)
--
-- 仅转换纯文本段落（Para）中的编号行，已有的 Header 不受影响。
-- 要求行首严格匹配数字编号模式，正文不会误触发。
--
-- 与 title-promotion.lua 互补：
--   title-promotion → 中文编号（一、、（一）、1.）
--   numbering-to-headings → 数字编号（1 xx、2.1 xx、3.1.2 xx）
-- ============================================================================

-- ============================================================================
-- 1. 层级检测
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
-- 2. 主流程
-- ============================================================================

function Para(el)
  local text = pandoc.utils.stringify(el.content)

  -- 跳过空行
  if #text == 0 then
    return nil
  end

  local level = detect_level(text)
  if level then
    return pandoc.Header(level, el.content)
  end

  return nil
end
