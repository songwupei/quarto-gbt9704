-- ============================================================================
-- heading-demotion.lua — 双模式标题层级调整
-- ============================================================================
-- 自动识别文档编号体系，应用对应的层级策略。
--
-- [通知模式] 检测到 一、、（一） 等中文编号
--   场景 A：markdown 显式标题（## 一、xx）→ 删首个 H1 + H2→H1, H3→H2
--   场景 B：title-promotion 自动提升（一、→H1,（一）→H2）→ 不做降级
--
-- [标准模式] 检测到 1 xx / 2.1 xx / 3.1.2 xx 等数字编号
--   全部透传，不做任何调整
--
-- [默认] 通知模式（向后兼容，无编号标题时走此路径）
-- ============================================================================

-- ============================================================================
-- 1. 编号模式检测（可独立扩展）
-- ============================================================================

-- 通知模式：中文编号
local function is_tongzhi_pattern(text)
  if not text then return false end
  -- 一、、二、、...
  if text:match("^[一二三四五六七八九十]、") then return true end
  -- （一）、（二）、...
  if text:match("^（[一二三四五六七八九十]）") then return true end
  return false
end

-- 标准模式：数字编号
local function is_biaozhun_pattern(text)
  if not text then return false end
  -- 3.1.2 xxx
  if text:match("^%d+%.%d+%.%d+%s") then return true end
  -- 2.1 xxx
  if text:match("^%d+%.%d+%s") then return true end
  -- 1 xxx（但不能是 1. 后面跟数字，防止匹配列表项 1.2）
  if text:match("^%d+%s") then return true end
  return false
end

-- ============================================================================
-- 2. 文档类型判定
-- ============================================================================

local function detect_style(doc)
  local tongzhi = 0
  local biaozhun = 0

  for _, blk in ipairs(doc.blocks) do
    if blk.t == "Header" then
      local text = pandoc.utils.stringify(blk.content)
      if is_tongzhi_pattern(text) then
        tongzhi = tongzhi + 1
      end
      if is_biaozhun_pattern(text) then
        biaozhun = biaozhun + 1
      end
    end
  end

  if biaozhun > tongzhi then
    return "biaozhun"
  end
  return "tongzhi"  -- 默认（向后兼容）
end

-- ============================================================================
-- 3. 通知模式 — 是否存在内容 H1
--    "内容 H1"：匹配编号模式的 H1（一、或 1 xx），不是文档标题
--    如果存在 → title-promotion 已提升，不需要降级
--    如果不存在 → markdown 显式标题，需要降级
-- ============================================================================

local function has_content_h1(doc)
  for _, blk in ipairs(doc.blocks) do
    if blk.t == "Header" and blk.level == 1 then
      local text = pandoc.utils.stringify(blk.content)
      if is_tongzhi_pattern(text) or is_biaozhun_pattern(text) then
        return true
      end
    end
  end
  return false
end

-- ============================================================================
-- 4. 主流程：Pandoc(doc) + Header(el)
-- ============================================================================

local doc_style = nil
local need_demotion = false

function Pandoc(doc)
  doc_style = detect_style(doc)

  if doc_style == "tongzhi" then
    -- 判断是否需要降级
    need_demotion = not has_content_h1(doc)

    -- 删除第一个 H1（与 YAML title 重复的标题）
    local new_blocks = {}
    local first_checked = false
    for _, blk in ipairs(doc.blocks) do
      if not first_checked then
        first_checked = true
        if blk.t == "Header" and blk.level == 1 then
          -- skip — 与 YAML title 重复
        else
          table.insert(new_blocks, blk)
        end
      else
        table.insert(new_blocks, blk)
      end
    end
    doc.blocks = new_blocks

  else
    -- 标准模式：完全不干预
    need_demotion = false
  end

  return doc
end

function Header(el)
  if need_demotion and el.level > 1 then
    el.level = el.level - 1
  end
  return el
end
