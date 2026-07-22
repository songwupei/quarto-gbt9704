-- ============================================================================
-- heading-demotion.lua — 双模式标题层级调整
-- ============================================================================
-- 受 YAML 元数据 `title-type` 控制：
--   none     → 不做任何调整，保留原始标题层级
--   tongzhi  → 强制通知模式（删除首个 H1 + H2→H1, H3→H2）
--   biaozhun → 强制标准模式（全部透传）
--   auto     → 自动检测（默认，向后兼容）
-- ============================================================================

-- ============================================================================
-- 1. 编号模式检测
-- ============================================================================

local function is_tongzhi_pattern(text)
  if not text then return false end
  if text:match("^[一二三四五六七八九十]、") then return true end
  if text:match("^（[一二三四五六七八九十]）") then return true end
  return false
end

local function is_biaozhun_pattern(text)
  if not text then return false end
  if text:match("^%d+%.%d+%.%d+%s") then return true end
  if text:match("^%d+%.%d+%s") then return true end
  if text:match("^%d+%s") then return true end
  return false
end

-- ============================================================================
-- 2. 文档类型自动检测（仅 auto 模式）
-- ============================================================================

local function detect_style(blocks)
  local tongzhi, biaozhun = 0, 0
  for _, blk in ipairs(blocks) do
    if blk.t == "Header" then
      local text = pandoc.utils.stringify(blk.content)
      if is_tongzhi_pattern(text) then tongzhi = tongzhi + 1 end
      if is_biaozhun_pattern(text) then biaozhun = biaozhun + 1 end
    end
  end
  if biaozhun > tongzhi then return "biaozhun" end
  return "tongzhi"
end

-- ============================================================================
-- 3. 是否存在内容 H1（匹配编号模式的 H1）
-- ============================================================================

local function has_content_h1(blocks)
  for _, blk in ipairs(blocks) do
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
-- 4. 递归应用标题降级
-- ============================================================================

local function demote_headers(blocks, need_demotion)
  if not need_demotion then return end
  for i, blk in ipairs(blocks) do
    if blk.t == "Header" and blk.level > 1 then
      blk.level = blk.level - 1
    end
  end
end

-- ============================================================================
-- 5. 表格式返回：Meta 先读 title-type，Pandoc 再处理
-- ============================================================================

return {
  {
    Meta = function(meta)
      -- 在 Meta 阶段读取模式，存入 filter 闭包
      -- （通过直接修改 doc.meta 来传递，或在下个阶段读取）
      return nil
    end,
  },
  {
    Pandoc = function(doc)
      -- 读取 title-type
      local tt = doc.meta["title-type"]
      local type_mode = nil
      if tt then
        type_mode = pandoc.utils.stringify(tt):lower()
      end

      -- none: 不干预
      if type_mode == "none" then
        return doc
      end

      -- biaozhun: 透传
      if type_mode == "biaozhun" then
        return doc
      end

      -- 决定文档类型
      local doc_style
      if type_mode == "tongzhi" then
        doc_style = "tongzhi"
      else
        -- auto: 自动检测
        doc_style = detect_style(doc.blocks)
      end

      -- 通知模式处理
      if doc_style == "tongzhi" then
        local need_demotion = not has_content_h1(doc.blocks)

        -- 删除第一个 H1
        local new_blocks = {}
        local first_checked = false
        for _, blk in ipairs(doc.blocks) do
          if not first_checked then
            first_checked = true
            if blk.t == "Header" and blk.level == 1 then
              -- skip
            else
              table.insert(new_blocks, blk)
            end
          else
            table.insert(new_blocks, blk)
          end
        end

        -- 降级
        if need_demotion then
          demote_headers(new_blocks, true)
        end

        doc.blocks = new_blocks
      end

      return doc
    end,
  },
}
