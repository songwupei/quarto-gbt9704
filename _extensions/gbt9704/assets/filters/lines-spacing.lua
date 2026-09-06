-- =============================================================================
-- lines-spacing.lua — 列表项之间增加空行间距
--
-- 将每个列表项拆成独立段落（空行分隔），.tight 类保持紧凑。
-- =============================================================================

local function has_class(attr, class)
  if attr and attr.classes then
    for _, c in ipairs(attr.classes) do
      if c == class then return true end
    end
  end
  return false
end

local function list_to_paras(list)
  local result = {}
  local is_ordered = list.t == "OrderedList"
  local bullet = list.t == "BulletList" and "• " or ""
  local n = 1

  for _, item in ipairs(list.content) do
    local inlines = {}
    for _, block in ipairs(item) do
      for _, inline in ipairs(block.content) do
        inlines[#inlines + 1] = inline
      end
    end
    -- blank paragraph spacer before each item (except first)
    if #result > 0 then
      result[#result + 1] = pandoc.Para({})
    end
    local content = {}
    if is_ordered then
      content[#content + 1] = pandoc.Str(tostring(n) .. ". ")
      n = n + 1
    elseif bullet ~= "" then
      content[#content + 1] = pandoc.Str(bullet)
    end
    for _, inline in ipairs(inlines) do
      content[#content + 1] = inline
    end
    result[#result + 1] = pandoc.Para(content)
  end
  return result
end

function BulletList(list)
  if has_class(list.attr, "tight") then return nil end
  return list_to_paras(list)
end

function OrderedList(list)
  if has_class(list.attr, "tight") then return nil end
  return list_to_paras(list)
end
