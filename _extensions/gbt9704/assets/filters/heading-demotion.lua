-- heading-demotion.lua
-- Pandoc Lua filter: 全文标题降级
-- 1. 如果文档第一个顶层 Block 是 H1，删除它（避免与 YAML title 重复）
-- 2. 所有 Header 降一级（H2→H1, H3→H2, ...），H1 保持不变

local first_block_checked = false

function Pandoc(doc)
  local new_blocks = {}
  for _, blk in ipairs(doc.blocks) do
    if not first_block_checked then
      first_block_checked = true
      if blk.t == "Header" and blk.level == 1 then
        -- 第一个 block 是 H1：删除（与 frontmatter title 重复）
      else
        table.insert(new_blocks, blk)
      end
    else
      table.insert(new_blocks, blk)
    end
  end
  doc.blocks = new_blocks
  return doc
end

function Header(el)
  if el.level > 1 then
    el.level = el.level - 1
  end
  return el
end
