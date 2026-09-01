-- ============================================================================
-- heading-demotion.lua — 标题层级调整
-- ============================================================================
-- 受 YAML 元数据 `title-type` 控制：
--   tongzhi / tongzhi+biaozhun → 通知模式（删除首个 H1 + H2→H1, H3→H2）
--   biaozhun / none            → 透传
--   未设置                      → 默认 tongzhi（向后兼容）
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
-- 2. 是否存在内容 H1
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
-- 3. 表格式返回
-- ============================================================================

return {
  {
    Meta = function(meta)
      return nil
    end,
  },
  {
    Pandoc = function(doc)
      local tt = doc.meta["title-type"]
      local mode = "tongzhi"  -- 默认
      if tt then
        mode = pandoc.utils.stringify(tt):lower()
      end

      -- 只有包含 tongzhi 时才执行通知模式逻辑
      if not mode:match("tongzhi") then
        return doc
      end

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

      -- 降级 H2→H1, H3→H2
      if need_demotion then
        for _, blk in ipairs(new_blocks) do
          if blk.t == "Header" and blk.level > 1 then
            blk.level = blk.level - 1
          end
        end
      end

      doc.blocks = new_blocks
      return doc
    end,
  },
}
